# terraform-aws-cloud

This repository contains Terraform modules used to deploy and configure an AWS EKS cluster for the StreamNative Platform. It is currently underpinned by the [`terraform-aws-eks`](https://github.com/terraform-aws-modules/terraform-aws-eks) module. 

The working result is a Kubernetes cluster sized to your specifications, bootstrapped with StreamNative's Platform configuration, ready to receive a deployment of Apache Pulsar.

For more information on StreamNative Platform, head on over to our [official documentation](https://docs.streamnative.io/platform).
## Prerequisities
The [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) command line tool is required and must be installed. It's what we're using to manage the creation of a Kubernetes cluster and its bootstrap configuration, along with the necessary cloud provider infrastructure.

Although not specific to using this module, we use [Helm](https://helm.sh/docs/intro/install/) for deploying the [StreamNative Platform charts](https://github.com/streamnative/charts) on the cluster.

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
| <a name="module_function_mesh_operator"></a> [function\_mesh\_operator](#module\_function\_mesh\_operator) | streamnative/charts/helm//modules/function-mesh-operator | n/a |
| <a name="module_istio_operator"></a> [istio\_operator](#module\_istio\_operator) | streamnative/charts/helm//modules/istio-operator | n/a |
| <a name="module_olm"></a> [olm](#module\_olm) | streamnative/charts/helm//modules/operator-lifecycle-manager | n/a |
| <a name="module_olm_subscriptions"></a> [olm\_subscriptions](#module\_olm\_subscriptions) | streamnative/charts/helm//modules/olm-subscriptions | n/a |
| <a name="module_prometheus_operator"></a> [prometheus\_operator](#module\_prometheus\_operator) | streamnative/charts/helm//modules/prometheus-operator | n/a |
| <a name="module_pulsar_operator"></a> [pulsar\_operator](#module\_pulsar\_operator) | streamnative/charts/helm//modules/pulsar-operator | n/a |
| <a name="module_tiered_storage"></a> [tiered\_storage](#module\_tiered\_storage) | streamnative/managed-cloud/aws//modules/tiered_storage | 0.4.1 |
| <a name="module_vault"></a> [vault](#module\_vault) | streamnative/managed-cloud/aws//modules/vault_resources | 0.4.1 |
| <a name="module_vault_operator"></a> [vault\_operator](#module\_vault\_operator) | streamnative/charts/helm//modules/vault-operator | n/a |
| <a name="module_vpc_tags"></a> [vpc\_tags](#module\_vpc\_tags) | ./modules/eks-vpc-tags | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.csi](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [kubernetes_namespace.istio](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/namespace) | resource |
| [kubernetes_namespace.pulsar](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/namespace) | resource |
| [kubernetes_namespace.sn_system](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/namespace) | resource |
| [kubernetes_service_account.csi](https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs/resources/service_account) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cert_manager_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.csi_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault_base_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.worker_autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_vpc_tags"></a> [add\_vpc\_tags](#input\_add\_vpc\_tags) | Adds tags to VPC resources necessary for ingress resources within EKS to perform auto-discovery of subnets. Defaults to "true". Note that this may cause resource cycling (delete and recreate) if you are using Terraform to manage your VPC resources without having a `lifecycle { ignore_changes = [ tags ] }` block defined within them, since the VPC resources will want to manage the tags themselves and remove the ones added by this module. | `bool` | `true` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to be added to the resources created by this module. | `map(any)` | `{}` | no |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition: 'aws', 'aws-cn', or 'aws-us-gov' | `string` | `"aws"` | no |
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
| <a name="input_csi_namespace"></a> [csi\_namespace](#input\_csi\_namespace) | The namespace used for AWS EKS Container Storage Interface (CSI) | `string` | `"kube-system"` | no |
| <a name="input_csi_sa_name"></a> [csi\_sa\_name](#input\_csi\_sa\_name) | The service account name used for AWS EKS Container Storage Interface (CSI) | `string` | `"efs-csi-controller-sa"` | no |
| <a name="input_disable_olm"></a> [disable\_olm](#input\_disable\_olm) | Enables Operator Lifecycle Manager (OLM) on the EKS cluster, and disables installing operators via helm releases. This is currently disabled by default. | `bool` | `true` | no |
| <a name="input_enable_func_pool"></a> [enable\_func\_pool](#input\_enable\_func\_pool) | Enable an additional dedicated function pool | `bool` | `true` | no |
| <a name="input_enable_function_mesh_operator"></a> [enable\_function\_mesh\_operator](#input\_enable\_function\_mesh\_operator) | Enables the StreamNative Function Mesh Operator on the EKS cluster. Enabled by default, but disabled if var.disable\_olm is set to `true` | `bool` | `true` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Enables the OpenID Connect Provider for EKS to use IAM Roles for Service Accounts (IRSA) | `bool` | `true` | no |
| <a name="input_enable_istio_operator"></a> [enable\_istio\_operator](#input\_enable\_istio\_operator) | Enables the Istio operator on the EKS cluster. Enabled by default. | `bool` | `true` | no |
| <a name="input_enable_istio_sources"></a> [enable\_istio\_sources](#input\_enable\_istio\_sources) | Enables the Istio sources when deploying ExternalDNS. Automatically enabled if input "enable\_istio\_operator" is set to  "true", but can be explicitly disabled by setting this input to "false" and should only be changed for debugging purposes. | `bool` | `true` | no |
| <a name="input_enable_prometheus_operator"></a> [enable\_prometheus\_operator](#input\_enable\_prometheus\_operator) | Enables the Prometheus operator on the EKS cluster. Enabled by default, but disabled if var.disable\_olm is set to `true` | `bool` | `true` | no |
| <a name="input_enable_pulsar_operator"></a> [enable\_pulsar\_operator](#input\_enable\_pulsar\_operator) | Enables the Pulsar Operator on the EKS cluster. Enabled by default, but disabled if var.disable\_olm is set to `true` | `bool` | `true` | no |
| <a name="input_enable_vault_operator"></a> [enable\_vault\_operator](#input\_enable\_vault\_operator) | Enables Hashicorp Vault on the EKS cluster. | `bool` | `true` | no |
| <a name="input_external_dns_helm_chart_name"></a> [external\_dns\_helm\_chart\_name](#input\_external\_dns\_helm\_chart\_name) | The name of the Helm chart in the repository for ExternalDNS. | `string` | `"external-dns"` | no |
| <a name="input_external_dns_helm_chart_repository"></a> [external\_dns\_helm\_chart\_repository](#input\_external\_dns\_helm\_chart\_repository) | The repository containing the ExternalDNS helm chart. | `string` | `"https://charts.bitnami.com/bitnami"` | no |
| <a name="input_external_dns_helm_chart_version"></a> [external\_dns\_helm\_chart\_version](#input\_external\_dns\_helm\_chart\_version) | Helm chart version for ExternalDNS. Defaults to "4.9.0". See https://hub.helm.sh/charts/bitnami/external-dns for updates. | `string` | `"4.9.0"` | no |
| <a name="input_external_dns_settings"></a> [external\_dns\_settings](#input\_external\_dns\_settings) | Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns | `map(any)` | `{}` | no |
| <a name="input_func_pool_allowed_role_arns"></a> [func\_pool\_allowed\_role\_arns](#input\_func\_pool\_allowed\_role\_arns) | The role resources (or patterns) that function roles can assume | `list(string)` | <pre>[<br>  "arn:aws:iam::*:role/pulsar-func-*"<br>]</pre> | no |
| <a name="input_func_pool_desired_size"></a> [func\_pool\_desired\_size](#input\_func\_pool\_desired\_size) | Desired number of worker nodes | `number` | `1` | no |
| <a name="input_func_pool_disk_size"></a> [func\_pool\_disk\_size](#input\_func\_pool\_disk\_size) | Disk size in GiB for function worker nodes. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided | `number` | `20` | no |
| <a name="input_func_pool_disk_type"></a> [func\_pool\_disk\_type](#input\_func\_pool\_disk\_type) | Disk type for function worker nodes. Defaults to gp3 | `string` | `"gp3"` | no |
| <a name="input_func_pool_instance_types"></a> [func\_pool\_instance\_types](#input\_func\_pool\_instance\_types) | Set of instance types associated with the EKS Node Group. Defaults to ["t3.large"]. Terraform will only perform drift detection if a configuration value is provided | `list(string)` | <pre>[<br>  "t3.large"<br>]</pre> | no |
| <a name="input_func_pool_kubernetes_labels"></a> [func\_pool\_kubernetes\_labels](#input\_func\_pool\_kubernetes\_labels) | Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed | `map(string)` | `{}` | no |
| <a name="input_func_pool_max_size"></a> [func\_pool\_max\_size](#input\_func\_pool\_max\_size) | The maximum size of the AutoScaling Group | `number` | `5` | no |
| <a name="input_func_pool_min_size"></a> [func\_pool\_min\_size](#input\_func\_pool\_min\_size) | The minimum size of the AutoScaling Group | `number` | `1` | no |
| <a name="input_func_pool_namespace"></a> [func\_pool\_namespace](#input\_func\_pool\_namespace) | The namespace where functions run | `string` | `"pulsar-funcs"` | no |
| <a name="input_func_pool_sa_name"></a> [func\_pool\_sa\_name](#input\_func\_pool\_sa\_name) | The service account name the functions use | `string` | `"default"` | no |
| <a name="input_function_mesh_operator_chart_name"></a> [function\_mesh\_operator\_chart\_name](#input\_function\_mesh\_operator\_chart\_name) | The name of the Helm chart to install | `string` | `"function-mesh-operator"` | no |
| <a name="input_function_mesh_operator_chart_repository"></a> [function\_mesh\_operator\_chart\_repository](#input\_function\_mesh\_operator\_chart\_repository) | The repository containing the Helm chart to install | `string` | `"https://charts.streamnative.io"` | no |
| <a name="input_function_mesh_operator_chart_version"></a> [function\_mesh\_operator\_chart\_version](#input\_function\_mesh\_operator\_chart\_version) | The version of the Helm chart to install | `string` | `"0.1.7"` | no |
| <a name="input_function_mesh_operator_cleanup_on_fail"></a> [function\_mesh\_operator\_cleanup\_on\_fail](#input\_function\_mesh\_operator\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails | `bool` | `true` | no |
| <a name="input_function_mesh_operator_release_name"></a> [function\_mesh\_operator\_release\_name](#input\_function\_mesh\_operator\_release\_name) | The name of the helm release | `string` | `"function-mesh-operator"` | no |
| <a name="input_function_mesh_operator_settings"></a> [function\_mesh\_operator\_settings](#input\_function\_mesh\_operator\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `null` | no |
| <a name="input_function_mesh_operator_timeout"></a> [function\_mesh\_operator\_timeout](#input\_function\_mesh\_operator\_timeout) | Time in seconds to wait for any individual kubernetes operation | `number` | `600` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | The ID of the Route53 hosted zone used by the cluster's external-dns configuration | `string` | `""` | no |
| <a name="input_istio_operator_chart_name"></a> [istio\_operator\_chart\_name](#input\_istio\_operator\_chart\_name) | The name of the Helm chart to install | `string` | `"istio-operator"` | no |
| <a name="input_istio_operator_chart_repository"></a> [istio\_operator\_chart\_repository](#input\_istio\_operator\_chart\_repository) | The repository containing the Helm chart to install | `string` | `"https://kubernetes-charts.banzaicloud.com"` | no |
| <a name="input_istio_operator_chart_version"></a> [istio\_operator\_chart\_version](#input\_istio\_operator\_chart\_version) | The version of the Helm chart to install | `string` | `"0.0.88"` | no |
| <a name="input_istio_operator_cleanup_on_fail"></a> [istio\_operator\_cleanup\_on\_fail](#input\_istio\_operator\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails | `bool` | `true` | no |
| <a name="input_istio_operator_release_name"></a> [istio\_operator\_release\_name](#input\_istio\_operator\_release\_name) | The name of the helm release | `string` | `"istio-operator"` | no |
| <a name="input_istio_operator_settings"></a> [istio\_operator\_settings](#input\_istio\_operator\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `null` | no |
| <a name="input_istio_operator_timeout"></a> [istio\_operator\_timeout](#input\_istio\_operator\_timeout) | Time in seconds to wait for any individual kubernetes operation | `number` | `600` | no |
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
| <a name="input_olm_namespace"></a> [olm\_namespace](#input\_olm\_namespace) | The namespace used by OLM and its resources | `string` | `"olm"` | no |
| <a name="input_olm_operators_namespace"></a> [olm\_operators\_namespace](#input\_olm\_operators\_namespace) | The namespace where OLM will install the operators | `string` | `"operators"` | no |
| <a name="input_olm_settings"></a> [olm\_settings](#input\_olm\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `null` | no |
| <a name="input_olm_sn_image"></a> [olm\_sn\_image](#input\_olm\_sn\_image) | The registry containing StreamNative's operator catalog image | `string` | `""` | no |
| <a name="input_olm_subscription_settings"></a> [olm\_subscription\_settings](#input\_olm\_subscription\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `null` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The ids of existing private subnets | `list(string)` | `[]` | no |
| <a name="input_prometheus_operator_chart_name"></a> [prometheus\_operator\_chart\_name](#input\_prometheus\_operator\_chart\_name) | The name of the Helm chart to install | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_prometheus_operator_chart_repository"></a> [prometheus\_operator\_chart\_repository](#input\_prometheus\_operator\_chart\_repository) | The repository containing the Helm chart to install | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| <a name="input_prometheus_operator_chart_version"></a> [prometheus\_operator\_chart\_version](#input\_prometheus\_operator\_chart\_version) | The version of the Helm chart to install | `string` | `"16.12.1"` | no |
| <a name="input_prometheus_operator_cleanup_on_fail"></a> [prometheus\_operator\_cleanup\_on\_fail](#input\_prometheus\_operator\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails | `bool` | `true` | no |
| <a name="input_prometheus_operator_release_name"></a> [prometheus\_operator\_release\_name](#input\_prometheus\_operator\_release\_name) | The name of the helm release | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_prometheus_operator_settings"></a> [prometheus\_operator\_settings](#input\_prometheus\_operator\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `null` | no |
| <a name="input_prometheus_operator_timeout"></a> [prometheus\_operator\_timeout](#input\_prometheus\_operator\_timeout) | Time in seconds to wait for any individual kubernetes operation | `number` | `600` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | The ids of existing public subnets | `list(string)` | `[]` | no |
| <a name="input_pulsar_namespace"></a> [pulsar\_namespace](#input\_pulsar\_namespace) | The Kubernetes namespace that will be used for the Pulsar workload. This does not get created automatically, but is needed in order to create the scoped access policies in AWS. Can be enabled by setting `var.pulsar_namespace_create` to `true`. | `string` | n/a | yes |
| <a name="input_pulsar_namespace_create"></a> [pulsar\_namespace\_create](#input\_pulsar\_namespace\_create) | Whether to create the Pulsar namespace if it doesn't already exist | `bool` | `false` | no |
| <a name="input_pulsar_operator_chart_name"></a> [pulsar\_operator\_chart\_name](#input\_pulsar\_operator\_chart\_name) | The name of the Helm chart to install | `string` | `"pulsar-operator"` | no |
| <a name="input_pulsar_operator_chart_repository"></a> [pulsar\_operator\_chart\_repository](#input\_pulsar\_operator\_chart\_repository) | The repository containing the Helm chart to install | `string` | `"https://charts.streamnative.io"` | no |
| <a name="input_pulsar_operator_chart_version"></a> [pulsar\_operator\_chart\_version](#input\_pulsar\_operator\_chart\_version) | The version of the Helm chart to install | `string` | `"0.7.2"` | no |
| <a name="input_pulsar_operator_cleanup_on_fail"></a> [pulsar\_operator\_cleanup\_on\_fail](#input\_pulsar\_operator\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails | `bool` | `true` | no |
| <a name="input_pulsar_operator_release_name"></a> [pulsar\_operator\_release\_name](#input\_pulsar\_operator\_release\_name) | The name of the helm release | `string` | `"pulsar-operator"` | no |
| <a name="input_pulsar_operator_settings"></a> [pulsar\_operator\_settings](#input\_pulsar\_operator\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `null` | no |
| <a name="input_pulsar_operator_timeout"></a> [pulsar\_operator\_timeout](#input\_pulsar\_operator\_timeout) | Time in seconds to wait for any individual kubernetes operation | `number` | `600` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region | `string` | `null` | no |
| <a name="input_s3_bucket_name_override"></a> [s3\_bucket\_name\_override](#input\_s3\_bucket\_name\_override) | Overrides the name for S3 bucket resources | `string` | `""` | no |
| <a name="input_vault_operator_chart_name"></a> [vault\_operator\_chart\_name](#input\_vault\_operator\_chart\_name) | The name of the Helm chart to install | `string` | `"vault-operator"` | no |
| <a name="input_vault_operator_chart_repository"></a> [vault\_operator\_chart\_repository](#input\_vault\_operator\_chart\_repository) | The repository containing the Helm chart to install | `string` | `"https://kubernetes-charts.banzaicloud.com"` | no |
| <a name="input_vault_operator_chart_version"></a> [vault\_operator\_chart\_version](#input\_vault\_operator\_chart\_version) | The version of the Helm chart to install | `string` | `"1.13.0"` | no |
| <a name="input_vault_operator_cleanup_on_fail"></a> [vault\_operator\_cleanup\_on\_fail](#input\_vault\_operator\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails | `bool` | `true` | no |
| <a name="input_vault_operator_release_name"></a> [vault\_operator\_release\_name](#input\_vault\_operator\_release\_name) | The name of the helm release | `string` | `"vault-operator"` | no |
| <a name="input_vault_operator_settings"></a> [vault\_operator\_settings](#input\_vault\_operator\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `null` | no |
| <a name="input_vault_operator_timeout"></a> [vault\_operator\_timeout](#input\_vault\_operator\_timeout) | Time in seconds to wait for any individual kubernetes operation | `number` | `600` | no |
| <a name="input_vault_prefix_override"></a> [vault\_prefix\_override](#input\_vault\_prefix\_override) | Overrides the name prefix for Vault resources | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC to use | `string` | `""` | no |
| <a name="input_wait_for_cluster_timeout"></a> [wait\_for\_cluster\_timeout](#input\_wait\_for\_cluster\_timeout) | Time in seconds to wait for the newly provisioned EKS cluster's API/healthcheck endpoint to return healthy, before applying the aws-auth configmap. Defaults to 300 seconds in the parent module "terraform-aws-modules/eks/aws", which is often too short. Increase to at least 900 seconds, if needed. See also https://github.com/terraform-aws-modules/terraform-aws-eks/pull/1420 | `number` | `0` | no |
| <a name="input_write_kubeconfig"></a> [write\_kubeconfig](#input\_write\_kubeconfig) | Whether to write a Kubectl config file containing the cluster configuration. Saved to variable "kubeconfig\_output\_path". | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cert_manager_role_arn"></a> [cert\_manager\_role\_arn](#output\_cert\_manager\_role\_arn) | n/a |
| <a name="output_cluster_autoscaler_role_arn"></a> [cluster\_autoscaler\_role\_arn](#output\_cluster\_autoscaler\_role\_arn) | n/a |
| <a name="output_eks_cluster_arn"></a> [eks\_cluster\_arn](#output\_eks\_cluster\_arn) | n/a |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | n/a |
| <a name="output_eks_cluster_identity_oidc_issuer_arn"></a> [eks\_cluster\_identity\_oidc\_issuer\_arn](#output\_eks\_cluster\_identity\_oidc\_issuer\_arn) | n/a |
| <a name="output_eks_cluster_identity_oidc_issuer_url"></a> [eks\_cluster\_identity\_oidc\_issuer\_url](#output\_eks\_cluster\_identity\_oidc\_issuer\_url) | n/a |
| <a name="output_external_dns_role_arn"></a> [external\_dns\_role\_arn](#output\_external\_dns\_role\_arn) | n/a |
| <a name="output_tiered_storage_role_arn"></a> [tiered\_storage\_role\_arn](#output\_tiered\_storage\_role\_arn) | n/a |
| <a name="output_vault_role_arn"></a> [vault\_role\_arn](#output\_vault\_role\_arn) | n/a |
