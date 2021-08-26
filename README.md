# terraform-aws-cloud

This repository contains Terraform modules used to deploy and configure an AWS EKS cluster for the StreamNative Platform. It is currently underpinned by the [`terraform-aws-eks`](https://github.com/terraform-aws-modules/terraform-aws-eks) module. 

The working result is a Kubernetes cluster sized to your specifications, bootstrapped with StreamNative's Platform configuration, ready to receive a deployment of Apache Pulsar.

For more information on StreamNative Platform, head on over to our [official documentation](https://docs.streamnative.io/platform).
## Prerequisities
The [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) command line tool is required and must be installed. It's what we're using to manage the creation of a Kubernetes cluster and its bootstrap configuration, along with the necessary cloud provider infrastructure.

We use [Helm](https://helm.sh/docs/intro/install/) for deploying the [StreamNative Platform charts](https://github.com/streamnative/charts) on the cluster, and while not necessary, it's recommended to have it installed for debugging purposes.

Your caller identity must also have the necessary AWS IAM permissions to create and work with EC2 (EKS, VPCs, etc.) and Route53.

### Other Recommendations for AWS
- [`aws`](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) command-line tool
- [`aws-iam-authenticator`](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) command line tool 

## Getting Started
A bare minimum configuration will be contained in a `main.tf`:

```hcl
terraform {
  required_version = ">=1.0.0"

  required_providers {
    aws = {
      version = ">= 3.45.0"
      source  = "hashicorp/aws"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.2.0"
    }
  }
}


#######
### These data sources are required by the Kubernetes and Helm providers to connect to the newly provisioned cluster
#######
data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.eks_cluster_id
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    config_path = "/path/to/my-sn-platform-cluster-config" # This must match the module input
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  insecure               = false
  config_path            = "/path/to/my-sn-platform-cluster-config" # This must match the module input
}

#######
### Create the StreamNative Platform Cluster
#######
module "sn_platform_cluster" {
  source          = "streamnative/cloud/aws"

  cluster_name                 = "my-sn-platform-cluster"
  cluster_version              = "1.19"
  kubeconfig_output_path       = "/path/to/my-sn-platform-cluster-config" # add this path to the provider configs above

  map_additional_iam_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/my-aws-admin-role" 
      username = "management-admin"
      groups   = ["system:masters"]
    }
  ]

  node_pool_instance_types     = ["m4.large"]
  node_pool_desired_size       = 3
  node_pool_min_size           = 3
  node_pool_max_size           = 5
  pulsar_namespace             = "pulsar-demo"

  hosted_zone_id               = "Z04554535IN8Z31SKDVQ2"
  public_subnet_ids            = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  private_subnet_ids           = ["subnet-vwxyz123", "subnet-efgh242a", "subnet-lmno643b"]
  region                       = "us-west-2"
  vpc_id                       = "vpc-1234556abcdef"
}
```

*Important Note: You will notice that a [Terraform Backend](https://www.terraform.io/docs/language/settings/backends/index.html) configuration is absent in this example, and a `local` backend (Terraform's default) will be used. For production deployments, we highly recommend using a `remote` backend with proper versioning and access controls, such as [Terraform Cloud](https://www.terraform.io/docs/cloud/index.html) or [S3](https://www.terraform.io/docs/language/settings/backends/s3.html).*

In the example `main.tf` above, we create a StreamNative Platform EKS cluster using Kubernetes version `1.19`, with a desired node pool size of `3` `m4.large` instances and an auto-scaling capacity to `5`.

It also adds the role `arn:aws:iam::123456789012:role/my-aws-admin-role` to the EKS auth config map, granting the identity access to manage the cluster via [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/).

## Creating a StreamNative Platform EKS Cluster
To apply the configuration, initialize the Terraform module in the directory containing **your own version** of the `main.tf` from the example above:

```shell
terraform init
```

Run a plan to validate what's being created:

```shell
terraform plan
```

Apply the configuration:
```shell
terraform apply
```

## Deploy a StreamNative Platform Workload (an Apache Pulsar Cluster)
We use a [Helm chart](https://github.com/streamnative/charts/tree/master/charts/sn-pulsar) to deploy StreamNative Platform on the receiving Kubernetes cluster (e.g. the one created prior from the Terraform module). 

The example below will install StreamNative Platform using the default values file. 

```shell
helm install \
--namespace pulsar-demo \
sn-platform \
--repo https://charts.streamnative.io pulsar \
--values https://raw.githubusercontent.com/streamnative/charts/master/charts/pulsar/values.yaml \
--version 2.7.0-rc.8 \
--set initialize=true
--kubeconfig=/path/to/my-sn-platform-cluster-config 
```
*Important Note: If this is your first time installing the helm chart, you must override the initialize value to `true` (e.g. `--set initialize=true`)*

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.45.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.45.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.1.0 |
| <a name="module_vpc_tags"></a> [vpc\_tags](#module\_vpc\_tags) | ./modules/eks-vpc-tags | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.calico](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.csi](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [kubernetes_namespace.calico](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/namespace) | resource |
| [kubernetes_namespace.sn_system](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/namespace) | resource |
| [kubernetes_storage_class.sn_default](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.sn_ssd](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/storage_class) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cert_manager_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.csi_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.worker_autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_vpc_tags"></a> [add\_vpc\_tags](#input\_add\_vpc\_tags) | Adds tags to VPC resources necessary for ingress resources within EKS to perform auto-discovery of subnets. Defaults to "true". Note that this may cause resource cycling (delete and recreate) if you are using Terraform to manage your VPC resources without having a `lifecycle { ignore_changes = [ tags ] }` block defined within them, since the VPC resources will want to manage the tags themselves and remove the ones added by this module. | `bool` | `true` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to be added to the resources created by this module. | `map(any)` | `{}` | no |
| <a name="input_aws_load_balancer_controller_helm_chart_name"></a> [aws\_load\_balancer\_controller\_helm\_chart\_name](#input\_aws\_load\_balancer\_controller\_helm\_chart\_name) | The name of the Helm chart to use for the AWS Load Balancer Controller. | `string` | `"aws-load-balancer-controller"` | no |
| <a name="input_aws_load_balancer_controller_helm_chart_repository"></a> [aws\_load\_balancer\_controller\_helm\_chart\_repository](#input\_aws\_load\_balancer\_controller\_helm\_chart\_repository) | The repository containing the Helm chart to use for the AWS Load Balancer Controller. | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_aws_load_balancer_controller_helm_chart_version"></a> [aws\_load\_balancer\_controller\_helm\_chart\_version](#input\_aws\_load\_balancer\_controller\_helm\_chart\_version) | The version of the Helm chart to use for the AWS Load Balancer Controller. The current version can be found in github: https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/Chart.yaml | `string` | `"1.2.6"` | no |
| <a name="input_aws_load_balancer_controller_settings"></a> [aws\_load\_balancer\_controller\_settings](#input\_aws\_load\_balancer\_controller\_settings) | Additional settings which will be passed to the Helm chart values for the AWS Load Balancer Controller. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options. | `map(string)` | `{}` | no |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition: 'aws', 'aws-cn', or 'aws-us-gov', used when constructing IRSA trust relationship policies | `string` | `"aws"` | no |
| <a name="input_calico_helm_chart_name"></a> [calico\_helm\_chart\_name](#input\_calico\_helm\_chart\_name) | The name of the Helm chart in the repository for Calico, which is installed alongside the tigera-operator. | `string` | `"tigera-operator"` | no |
| <a name="input_calico_helm_chart_repository"></a> [calico\_helm\_chart\_repository](#input\_calico\_helm\_chart\_repository) | The repository containing the calico helm chart. We are currently using a community provided chart, which is a fork of the official chart published by Tigera. This chart isn't as opinionated about namespaces, and should be used until this issue is resolved https://github.com/projectcalico/calico/issues/4812 | `string` | `"https://stevehipwell.github.io/helm-charts/"` | no |
| <a name="input_calico_helm_chart_version"></a> [calico\_helm\_chart\_version](#input\_calico\_helm\_chart\_version) | Helm chart version for Calico. Defaults to "1.0.5". See https://github.com/stevehipwell/helm-charts/tree/master/charts/tigera-operator for available version releases. | `string` | `"1.0.5"` | no |
| <a name="input_calico_settings"></a> [calico\_settings](#input\_calico\_settings) | Additional settings which will be passed to the Helm chart values. See https://github.com/stevehipwell/helm-charts/tree/master/charts/tigera-operator for available options. | `map(any)` | `{}` | no |
| <a name="input_cert_manager_helm_chart_name"></a> [cert\_manager\_helm\_chart\_name](#input\_cert\_manager\_helm\_chart\_name) | The name of the Helm chart in the repository for cert-manager. | `string` | `"cert-manager"` | no |
| <a name="input_cert_manager_helm_chart_repository"></a> [cert\_manager\_helm\_chart\_repository](#input\_cert\_manager\_helm\_chart\_repository) | The repository containing the cert-manager helm chart. | `string` | `"https://charts.jetstack.io"` | no |
| <a name="input_cert_manager_helm_chart_version"></a> [cert\_manager\_helm\_chart\_version](#input\_cert\_manager\_helm\_chart\_version) | Helm chart version for the cert-manager. Defaults to "1.4.0". See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for version releases. | `string` | `"1.4.0"` | no |
| <a name="input_cert_manager_settings"></a> [cert\_manager\_settings](#input\_cert\_manager\_settings) | Additional settings which will be passed to the Helm chart values. See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for available options. | `map(any)` | `{}` | no |
| <a name="input_cluster_autoscaler_helm_chart_name"></a> [cluster\_autoscaler\_helm\_chart\_name](#input\_cluster\_autoscaler\_helm\_chart\_name) | The name of the Helm chart in the repository for cluster-autoscaler. | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_helm_chart_repository"></a> [cluster\_autoscaler\_helm\_chart\_repository](#input\_cluster\_autoscaler\_helm\_chart\_repository) | The repository containing the cluster-autoscaler helm chart. | `string` | `"https://kubernetes.github.io/autoscaler"` | no |
| <a name="input_cluster_autoscaler_helm_chart_version"></a> [cluster\_autoscaler\_helm\_chart\_version](#input\_cluster\_autoscaler\_helm\_chart\_version) | Helm chart version for the cluster-autoscaler. Defaults to "9.10.4". See https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for more details. | `string` | `"9.10.4"` | no |
| <a name="input_cluster_autoscaler_settings"></a> [cluster\_autoscaler\_settings](#input\_cluster\_autoscaler\_settings) | Additional settings which will be passed to the Helm chart values for cluster-autoscaler, see https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for options. | `map(any)` | `{}` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) | `list(string)` | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources. Must be 16 characters or less | `string` | `""` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The version of Kubernetes to be installed | `string` | `"1.18"` | no |
| <a name="input_create_sn_system_namespace"></a> [create\_sn\_system\_namespace](#input\_create\_sn\_system\_namespace) | Whether or not to create the namespace "sn-system" on the cluster. This namespace is commonly used by OLM and StreamNative's Kubernetes Operators | `bool` | `true` | no |
| <a name="input_csi_namespace"></a> [csi\_namespace](#input\_csi\_namespace) | The namespace used for AWS EKS Container Storage Interface (CSI) | `string` | `"kube-system"` | no |
| <a name="input_csi_sa_name"></a> [csi\_sa\_name](#input\_csi\_sa\_name) | The service account name used for AWS EKS Container Storage Interface (CSI) | `string` | `"ebs-csi-controller-sa"` | no |
| <a name="input_csi_settings"></a> [csi\_settings](#input\_csi\_settings) | Additional settings which will be passed to the Helm chart values, see https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml for available options. | `map(any)` | `{}` | no |
| <a name="input_disable_istio_sources"></a> [disable\_istio\_sources](#input\_disable\_istio\_sources) | Disables Istio sources for the External DNS configuration. Set to "false" by default. Set to "true" for debugging External DNS or if Istio is disabled. | `bool` | `false` | no |
| <a name="input_enable_csi"></a> [enable\_csi](#input\_enable\_csi) | Enables the EBS Container Storage Interface (CSI) driver on the cluster, which allows for EKS manage the lifecycle of persistant volumes in EBS. | `bool` | `true` | no |
| <a name="input_enable_func_pool"></a> [enable\_func\_pool](#input\_enable\_func\_pool) | Enable an additional dedicated function pool | `bool` | `false` | no |
| <a name="input_external_dns_helm_chart_name"></a> [external\_dns\_helm\_chart\_name](#input\_external\_dns\_helm\_chart\_name) | The name of the Helm chart in the repository for ExternalDNS. | `string` | `"external-dns"` | no |
| <a name="input_external_dns_helm_chart_repository"></a> [external\_dns\_helm\_chart\_repository](#input\_external\_dns\_helm\_chart\_repository) | The repository containing the ExternalDNS helm chart. | `string` | `"https://charts.bitnami.com/bitnami"` | no |
| <a name="input_external_dns_helm_chart_version"></a> [external\_dns\_helm\_chart\_version](#input\_external\_dns\_helm\_chart\_version) | Helm chart version for ExternalDNS. Defaults to "4.9.0". See https://hub.helm.sh/charts/bitnami/external-dns for updates. | `string` | `"4.9.0"` | no |
| <a name="input_external_dns_settings"></a> [external\_dns\_settings](#input\_external\_dns\_settings) | Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns | `map(any)` | `{}` | no |
| <a name="input_func_pool_desired_size"></a> [func\_pool\_desired\_size](#input\_func\_pool\_desired\_size) | Desired number of worker nodes | `number` | `1` | no |
| <a name="input_func_pool_disk_size"></a> [func\_pool\_disk\_size](#input\_func\_pool\_disk\_size) | Disk size in GiB for function worker nodes. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided | `number` | `20` | no |
| <a name="input_func_pool_disk_type"></a> [func\_pool\_disk\_type](#input\_func\_pool\_disk\_type) | Disk type for function worker nodes. Defaults to gp3 | `string` | `"gp3"` | no |
| <a name="input_func_pool_instance_types"></a> [func\_pool\_instance\_types](#input\_func\_pool\_instance\_types) | Set of instance types associated with the EKS Node Group. Defaults to ["t3.large"]. Terraform will only perform drift detection if a configuration value is provided | `list(string)` | <pre>[<br>  "t3.large"<br>]</pre> | no |
| <a name="input_func_pool_max_size"></a> [func\_pool\_max\_size](#input\_func\_pool\_max\_size) | The maximum size of the AutoScaling Group | `number` | `5` | no |
| <a name="input_func_pool_min_size"></a> [func\_pool\_min\_size](#input\_func\_pool\_min\_size) | The minimum size of the AutoScaling Group | `number` | `1` | no |
| <a name="input_func_pool_namespace"></a> [func\_pool\_namespace](#input\_func\_pool\_namespace) | The namespace where functions run | `string` | `"pulsar-funcs"` | no |
| <a name="input_func_pool_sa_name"></a> [func\_pool\_sa\_name](#input\_func\_pool\_sa\_name) | The service account name the functions use | `string` | `"default"` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | The ID of the Route53 hosted zone used by the cluster's External DNS configuration | `string` | n/a | yes |
| <a name="input_kubeconfig_output_path"></a> [kubeconfig\_output\_path](#input\_kubeconfig\_output\_path) | Where to save the Kubectl config file (if `write_kubeconfig = true`). Assumed to be a directory if the value ends with a forward slash `/`. | `string` | `"./"` | no |
| <a name="input_map_additional_aws_accounts"></a> [map\_additional\_aws\_accounts](#input\_map\_additional\_aws\_accounts) | Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap | `list(string)` | `[]` | no |
| <a name="input_map_additional_iam_roles"></a> [map\_additional\_iam\_roles](#input\_map\_additional\_iam\_roles) | Additional IAM roles to add to `config-map-aws-auth` ConfigMap | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_map_additional_iam_users"></a> [map\_additional\_iam\_users](#input\_map\_additional\_iam\_users) | Additional IAM roles to add to `config-map-aws-auth` ConfigMap | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_node_pool_desired_size"></a> [node\_pool\_desired\_size](#input\_node\_pool\_desired\_size) | Desired number of worker nodes in the node pool | `number` | n/a | yes |
| <a name="input_node_pool_disk_size"></a> [node\_pool\_disk\_size](#input\_node\_pool\_disk\_size) | Disk size in GiB for worker nodes in the node pool. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided | `number` | `null` | no |
| <a name="input_node_pool_disk_type"></a> [node\_pool\_disk\_type](#input\_node\_pool\_disk\_type) | Disk type for worker nodes in the node pool. Defaults to gp3 | `string` | `"gp3"` | no |
| <a name="input_node_pool_instance_types"></a> [node\_pool\_instance\_types](#input\_node\_pool\_instance\_types) | Set of instance types associated with the EKS Node Group. Defaults to ["t3.medium"]. Terraform will only perform drift detection if a configuration value is provided | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| <a name="input_node_pool_max_size"></a> [node\_pool\_max\_size](#input\_node\_pool\_max\_size) | The maximum size of the node pool Autoscaling group | `number` | n/a | yes |
| <a name="input_node_pool_min_size"></a> [node\_pool\_min\_size](#input\_node\_pool\_min\_size) | The minimum size of the node pool AutoScaling group | `number` | n/a | yes |
| <a name="input_node_termination_handler_helm_chart_name"></a> [node\_termination\_handler\_helm\_chart\_name](#input\_node\_termination\_handler\_helm\_chart\_name) | The name of the Helm chart to use for the AWS Node Termination Handler. | `string` | `"aws-node-termination-handler"` | no |
| <a name="input_node_termination_handler_helm_chart_repository"></a> [node\_termination\_handler\_helm\_chart\_repository](#input\_node\_termination\_handler\_helm\_chart\_repository) | The repository containing the Helm chart to use for the AWS Node Termination Handler. | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_node_termination_handler_settings"></a> [node\_termination\_handler\_settings](#input\_node\_termination\_handler\_settings) | Additional settings which will be passed to the Helm chart values for the AWS Node Termination Handler. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options. | `map(string)` | `{}` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The ids of existing private subnets | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | The ids of existing public subnets | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC to use | `string` | `""` | no |
| <a name="input_wait_for_cluster_timeout"></a> [wait\_for\_cluster\_timeout](#input\_wait\_for\_cluster\_timeout) | Time in seconds to wait for the newly provisioned EKS cluster's API/healthcheck endpoint to return healthy, before applying the aws-auth configmap. Defaults to 300 seconds in the parent module "terraform-aws-modules/eks/aws", which is often too short. Increase to at least 900 seconds, if needed. See also https://github.com/terraform-aws-modules/terraform-aws-eks/pull/1420 | `number` | `0` | no |
| <a name="input_write_kubeconfig"></a> [write\_kubeconfig](#input\_write\_kubeconfig) | Whether to write a Kubectl config file containing the cluster configuration. Saved to variable "kubeconfig\_output\_path". | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cert_manager_role_arn"></a> [cert\_manager\_role\_arn](#output\_cert\_manager\_role\_arn) | The IAM Role ARN used by the Certificate Manager configuration |
| <a name="output_cluster_autoscaler_role_arn"></a> [cluster\_autoscaler\_role\_arn](#output\_cluster\_autoscaler\_role\_arn) | The IAM Role ARN used by the Cluster Autoscaler configuration |
| <a name="output_eks_cluster_arn"></a> [eks\_cluster\_arn](#output\_eks\_cluster\_arn) | The ARN for the EKS cluster created by this module |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | The id/name of the EKS cluster created by this module |
| <a name="output_eks_cluster_identity_oidc_issuer_arn"></a> [eks\_cluster\_identity\_oidc\_issuer\_arn](#output\_eks\_cluster\_identity\_oidc\_issuer\_arn) | The ARN for the OIDC issuer created by this module |
| <a name="output_eks_cluster_identity_oidc_issuer_string"></a> [eks\_cluster\_identity\_oidc\_issuer\_string](#output\_eks\_cluster\_identity\_oidc\_issuer\_string) | A formatted string containing the prefix for the OIDC issuer created by this module. Same as "cluster\_oidc\_issuer\_url", but with "https://" stripped from the name. This output is typically used in other StreamNative modules that request the "oidc\_issuer" input. |
| <a name="output_eks_cluster_identity_oidc_issuer_url"></a> [eks\_cluster\_identity\_oidc\_issuer\_url](#output\_eks\_cluster\_identity\_oidc\_issuer\_url) | The URL for the OIDC issuer created by this module |
| <a name="output_external_dns_role_arn"></a> [external\_dns\_role\_arn](#output\_external\_dns\_role\_arn) | The IAM Role ARN used by the ExternalDNS configuration |
| <a name="output_sn_system_namespace"></a> [sn\_system\_namespace](#output\_sn\_system\_namespace) | The namespace used for StreamNative system resources, i.e. operators et all |
