# terraform-aws-cloud

This repository contains opinionated Terraform modules used to deploy and configure an AWS EKS cluster for the StreamNative Platform. It is currently underpinned by the [`terraform-aws-eks`](https://github.com/terraform-aws-modules/terraform-aws-eks) module.

The working result is a Kubernetes cluster sized to your specifications, bootstrapped with StreamNative's Platform configuration, ready to receive a deployment of Apache Pulsar.

For more information on StreamNative Platform, head on over to our [official documentation](https://docs.streamnative.io/platform).
## Prerequisites
The [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) command line tool is required and must be installed. It's what we're using to manage the creation of a Kubernetes cluster and its bootstrap configuration, along with the necessary cloud provider infrastructure.

We use [Helm](https://helm.sh/docs/intro/install/) for deploying the [StreamNative Platform charts](https://github.com/streamnative/charts) on the cluster, and while not necessary, it's recommended to have it installed for debugging purposes.

Your caller identity must also have the necessary AWS IAM permissions to create and work with EC2 (EKS, VPCs, etc.) and Route53.

### Other Recommendations
- [`aws`](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) command-line tool
- [`aws-iam-authenticator`](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) command line tool

## Networking
EKS has multiple modes of network configuration for how you access the EKS cluster endpoint, as well as how the node groups communicate with the EKS control plane.

This Terraform module supports the following:

- **Public (EKS) / Private (Node Groups)**: The EKS cluster API server is accessible from the internet, and node groups use a private VPC endpoint to communicate with the cluster's controle plane **_(default configuration)_**
- **Public (EKS) / Public (Node Groups)**: The EKS cluster API server is accessible from the internet, and node groups use a public EKS endpoint to communicate with the cluster's control plane. This mode can be enabled by setting the input `enable_node_group_private_networking = false` in the module.

**Note:** _Currently we do not support fully private EKS clusters with this module (i.e. all network traffic remains internal to the AWS VPC)_

For your VPC configuration we require sets of public and private subnets (minimum of two each, one per AWS AZ). Both groups of subnets must have an outbound configuration to the internet. We also recommend using a seperate VPC reserved for the EKS cluster, with a minimum CIDR block per subnet of `/24`.

A Terraform [sub-module](https://github.com/streamnative/terraform-aws-cloud/tree/master/modules/vpc) is available that manages the VPC configuration to our specifications. It can be used in composition to the root module in this repo _(see this [example](https://github.com/streamnative/terraform-aws-cloud/blob/master/examples/example-with-vpc/main.tf))_.

For more information on how EKS networking can be configured, refer to the following AWS guides:
- [Networking in EKS](https://aws.github.io/aws-eks-best-practices/reliability/docs/networkmanagement/)
- [Amazon EKS cluster endpoint access control](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html)
- [De-mystifying cluster networking for Amazon EKS worker nodes](https://aws.amazon.com/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/)


## Getting Started
A bare minimum configuration to execute the module:

```hcl
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
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  insecure               = false
}

variable "region" {
  default = "us-east-1"
}

module "sn_cluster" {
  source = "streamnative/cloud/aws"

  cluster_name             = "sn-cluster-${var.region}"
  cluster_version          = "1.20"
  hosted_zone_id           = "Z04554535IN8Z31SKDVQ2" # Change this to your hosted zone ID
  node_pool_instance_types = ["c6i.large"]
  node_pool_desired_size   = 2
  node_pool_min_size       = 1
  node_pool_max_size       = 6

  ## Note: EKS requires two subnets, each in their own availability zone
  public_subnet_ids  = ["subnet-abcde012", "subnet-bcde012a"]
  private_subnet_ids = ["subnet-vwxyz123", "subnet-efgh242a"]
  region             = var.region
  vpc_id             = "vpc-1234556abcdef"
}
```

In the example `main.tf` above, we create a StreamNative Platform EKS cluster using Kubernetes version `1.20`, with two node groups (one per subnet[^1]), each group being set with a desired capacity of two and a maximum scaling of six, meaning four `c6i.large` worker nodes in total will initially be created, but depending on cluster usage it can autoscale up to twelve.

_Note: If you are creating more than one EKS cluster in an AWS account, it is necessary to set the input `create_iam_policies_for_cluster_addon_services = false`. Otherwise Terraform will error stating that resources already exist with the desired name. This is a temporary workaround and will be improved in later versions of the module._

This creates an EKS cluster to your specifications, along with the following addons (and required IAM resources), which are enabled by default:
- [AWS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
- [AWS Node Terminiation Handler](https://github.com/aws/aws-node-termination-handler)
- [cert-manager](https://github.com/jetstack/cert-manager)
- [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [external-dns](https://github.com/kubernetes-sigs/external-dns)
- [external-secrets](https://github.com/external-secrets/kubernetes-external-secrets)

## Creating a StreamNative Platform EKS Cluster
When deploying StreamNative Platform, there are additional resources to be created alongside (and inside!) the EKS cluster:

- StreamNative operators for Pulsar
- Vault Operator
- Vault Resources
- Tiered Storage Resources (optional)

We have made this easy by creating additional Terraform modules that can be included alongside your EKS module composition. Consider adding the following to the example `main.tf` file above:

```hcl
#######
### This module creates resources used for tiered storage offloading in Pulsar
#######
module "sn_tiered_storage_resources" {
  source = "streamnative/cloud/aws//modules/tiered-storage-resources"

  cluster_name         = module.sn_cluster.eks_cluster_id
  oidc_issuer          = module.sn_cluster.eks_cluster_oidc_issuer_string
  pulsar_namespace     = "my-pulsar-namespace"
  service_account_name = "pulsar"

  tags = {
    Project     = "StreamNative Platform"
    Environment = var.environment
  }

  depends_on = [
    module.sn_cluster
  ]
}

#######
### This module creates resources used by Vault for storing and retrieving secrets related to the Pulsar cluster
#######
module "sn_tiered_storage_vault_resources" {
  source = "streamnative/cloud/aws//modules/vault-resources"

  cluster_name         = module.sn_cluster.eks_cluster_id
  oidc_issuer          = module.sn_cluster.eks_cluster_oidc_issuer_string
  pulsar_namespace     = "my-pulsar-namespace" # The namespace where you will be installing Pulsar
  service_account_name = "vault"               # The name of the service account used by Vault in the Pulsar namespace

  tags = {
    Project     = "StreamNative Platform"
    Environment = var.environment
  }

  depends_on = [
    module.sn_cluster
  ]
}

#######
### This module installs the necessary operators for StreamNative Platform
### See: https://registry.terraform.io/modules/streamnative/charts/helm/latest
#######
module "sn_bootstrap" {
  source = "streamnative/charts/helm"

  enable_function_mesh_operator = true
  enable_vault_operator         = true
  enable_pulsar_operator        = true

  depends_on = [
    module.sn_cluster,
  ]
}
```

To apply the configuration initialize the Terraform module in the directory containing **your own version** of the `main.tf` from the examples above:

```shell
terraform init
```

Validate and apply the configuration:
```shell
terraform apply
```

## Deploy a StreamNative Platform Workload (an Apache Pulsar Cluster)
We use a [Helm chart](https://github.com/streamnative/charts/tree/master/charts/sn-platform) to deploy StreamNative Platform on the receiving Kubernetes cluster. Refer to our [official documentation](https://docs.streamnative.io/platform/v1.0.0/overview/) for more info.

_Note: Since this module manages all of the Kubernetes addon dependencies required by StreamNative Platform, it is not necessary to perform all of the [steps outlined in the Helm chart's README.](https://github.com/streamnative/charts/tree/master/charts/sn-platform#steps). Please [reach out](https://support.streamnative.io) to your customer representative if you have questions._

## Using kubenertes-external-secrets with Amazon Secrets Manager
By default, `kubernetes-external-secrets` is enabled on the EKS cluster and the corresponding IRSA has access to retrieve all secrets created in the cluster's region. To clamp down access, you can specify the ARNs for just the secrets needed by passing a list to the input `asm_secret_arns` in your composition:

```hcl
module "sn_cluster" {
  source = "streamnative/cloud/aws"

  asm_secret_arns = [
    "arn:aws:secretsmanager:us-west-2:111122223333:secret:aes128-1a2b3c",
    "arn:aws:secretsmanager:us-west-2:111122223333:secret:aes192-4D5e6F",
    "arn:aws:secretsmanager:us-west-2:111122223333:secret:aes256-7g8H9i",
  ]
}
```

You can also use secret prefixes and wildcards to scope access a bit more granularly, i.e. `"arn:aws:secretsmanager:Region:AccountId:secret:TestEnv/*"` and pass that to the module. Refer to the [Secrets Manager docs](https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_examples.html) for examples.

To get an ASM secret on the cluster, create an `ExternalSecret` manifiest yml file:

```yml
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: my-cluster-secret
spec:
  backendType: secretsManager
  data:
    - key: secret-prefix/secret-id
      name: my-cluster-secret
```

Refer to [the official docs](https://github.com/external-secrets/kubernetes-external-secrets#add-a-secret) for more details.

You can also disable `kubernetes-external-secrets` by setting the input `enable-external-secret = false` in your composition of the `terraform-aws-cloud` (this) module.

[^1]: When running Apache Pulsar in Kubernetes, we make use of EBS backed Kubernetes Persistent Volume Claims (PVC). EBS volumes themselves are zonal, which means [an EC2 instance can only mount a volume that exists in its same AWS Availability Zone](https://aws.amazon.com/blogs/containers/amazon-eks-cluster-multi-zone-auto-scaling-groups/). For this reason we have added node group "zone affinity" functionality into our module, where **an EKS node group is created per AWS Availability Zone**. This is controlled by the number of subnets you pass to the EKS module, creating one node group per subnet.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=3.61.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >=2.6.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=3.61.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >=2.6.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.24.0 |
| <a name="module_istio"></a> [istio](#module\_istio) | github.com/streamnative/terraform-helm-charts//modules/istio-operator | v0.8.4 |
| <a name="module_vpc_tags"></a> [vpc\_tags](#module\_vpc\_tags) | ./modules/eks-vpc-tags | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group_tag.asg_group_vendor_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |
| [aws_ec2_tag.cluster_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_iam_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.external_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.csi_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.external_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.calico](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cert_issuer](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.csi](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.external_secrets](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.metrics_server](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [kubernetes_namespace.sn_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_storage_class.sn_default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.sn_ssd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cert_manager_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_autoscaler_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.csi_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_secrets_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.ebs_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_subnet.private_cidrs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_vpc_tags"></a> [add\_vpc\_tags](#input\_add\_vpc\_tags) | Adds tags to VPC resources necessary for ingress resources within EKS to perform auto-discovery of subnets. Defaults to "true". Note that this may cause resource cycling (delete and recreate) if you are using Terraform to manage your VPC resources without having a `lifecycle { ignore_changes = [ tags ] }` block defined within them, since the VPC resources will want to manage the tags themselves and remove the ones added by this module. | `bool` | `true` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to be added to the resources created by this module. | `map(any)` | `{}` | no |
| <a name="input_allowed_public_cidrs"></a> [allowed\_public\_cidrs](#input\_allowed\_public\_cidrs) | List of CIDR blocks that are allowed to access the EKS cluster's public endpoint. Defaults to "0.0.0.0/0" (any). | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_asm_secret_arns"></a> [asm\_secret\_arns](#input\_asm\_secret\_arns) | The a list of ARNs for secrets stored in ASM. This grants the kubernetes-external-secrets controller select access to secrets used by resources within the EKS cluster. If no arns are provided via this input, the IAM policy will allow read access to all secrets created in the provided region. | `list(string)` | `[]` | no |
| <a name="input_aws_load_balancer_controller_helm_chart_name"></a> [aws\_load\_balancer\_controller\_helm\_chart\_name](#input\_aws\_load\_balancer\_controller\_helm\_chart\_name) | The name of the Helm chart to use for the AWS Load Balancer Controller. | `string` | `"aws-load-balancer-controller"` | no |
| <a name="input_aws_load_balancer_controller_helm_chart_repository"></a> [aws\_load\_balancer\_controller\_helm\_chart\_repository](#input\_aws\_load\_balancer\_controller\_helm\_chart\_repository) | The repository containing the Helm chart to use for the AWS Load Balancer Controller. | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_aws_load_balancer_controller_helm_chart_version"></a> [aws\_load\_balancer\_controller\_helm\_chart\_version](#input\_aws\_load\_balancer\_controller\_helm\_chart\_version) | The version of the Helm chart to use for the AWS Load Balancer Controller. The current version can be found in github: https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/Chart.yaml. | `string` | `"1.4.2"` | no |
| <a name="input_aws_load_balancer_controller_settings"></a> [aws\_load\_balancer\_controller\_settings](#input\_aws\_load\_balancer\_controller\_settings) | Additional settings which will be passed to the Helm chart values for the AWS Load Balancer Controller. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options. | `map(string)` | `{}` | no |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition: 'aws', 'aws-cn', or 'aws-us-gov', used when constructing IRSA trust relationship policies. | `string` | `"aws"` | no |
| <a name="input_calico_helm_chart_name"></a> [calico\_helm\_chart\_name](#input\_calico\_helm\_chart\_name) | The name of the Helm chart in the repository for Calico, which is installed alongside the tigera-operator. | `string` | `"tigera-operator"` | no |
| <a name="input_calico_helm_chart_repository"></a> [calico\_helm\_chart\_repository](#input\_calico\_helm\_chart\_repository) | The repository containing the calico helm chart. We are currently using a community provided chart, which is a fork of the official chart published by Tigera. This chart isn't as opinionated about namespaces, and should be used until this issue is resolved https://github.com/projectcalico/calico/issues/4812. | `string` | `"https://stevehipwell.github.io/helm-charts/"` | no |
| <a name="input_calico_helm_chart_version"></a> [calico\_helm\_chart\_version](#input\_calico\_helm\_chart\_version) | Helm chart version for Calico. Defaults to "1.0.5". See https://github.com/stevehipwell/helm-charts/tree/master/charts/tigera-operator for available version releases. | `string` | `"1.5.0"` | no |
| <a name="input_calico_settings"></a> [calico\_settings](#input\_calico\_settings) | Additional settings which will be passed to the Helm chart values. See https://github.com/stevehipwell/helm-charts/tree/master/charts/tigera-operator for available options. | `map(any)` | `{}` | no |
| <a name="input_cert_issuer_support_email"></a> [cert\_issuer\_support\_email](#input\_cert\_issuer\_support\_email) | The email address to receive notifications from the cert issuer. | `string` | `"certs-support@streamnative.io"` | no |
| <a name="input_cert_manager_helm_chart_name"></a> [cert\_manager\_helm\_chart\_name](#input\_cert\_manager\_helm\_chart\_name) | The name of the Helm chart in the repository for cert-manager. | `string` | `"cert-manager"` | no |
| <a name="input_cert_manager_helm_chart_repository"></a> [cert\_manager\_helm\_chart\_repository](#input\_cert\_manager\_helm\_chart\_repository) | The repository containing the cert-manager helm chart. | `string` | `"https://charts.bitnami.com/bitnami"` | no |
| <a name="input_cert_manager_helm_chart_version"></a> [cert\_manager\_helm\_chart\_version](#input\_cert\_manager\_helm\_chart\_version) | Helm chart version for the cert-manager. See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for version releases. | `string` | `"0.6.2"` | no |
| <a name="input_cert_manager_settings"></a> [cert\_manager\_settings](#input\_cert\_manager\_settings) | Additional settings which will be passed to the Helm chart values. See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for available options. | `map(any)` | `{}` | no |
| <a name="input_cluster_autoscaler_helm_chart_name"></a> [cluster\_autoscaler\_helm\_chart\_name](#input\_cluster\_autoscaler\_helm\_chart\_name) | The name of the Helm chart in the repository for cluster-autoscaler. | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_helm_chart_repository"></a> [cluster\_autoscaler\_helm\_chart\_repository](#input\_cluster\_autoscaler\_helm\_chart\_repository) | The repository containing the cluster-autoscaler helm chart. | `string` | `"https://kubernetes.github.io/autoscaler"` | no |
| <a name="input_cluster_autoscaler_helm_chart_version"></a> [cluster\_autoscaler\_helm\_chart\_version](#input\_cluster\_autoscaler\_helm\_chart\_version) | Helm chart version for the cluster-autoscaler. Defaults to "9.10.4". See https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for more details. | `string` | `"9.19.2"` | no |
| <a name="input_cluster_autoscaler_settings"></a> [cluster\_autoscaler\_settings](#input\_cluster\_autoscaler\_settings) | Additional settings which will be passed to the Helm chart values for cluster-autoscaler, see https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for options. | `map(any)` | `{}` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). | `list(string)` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_log_kms_key_id"></a> [cluster\_log\_kms\_key\_id](#input\_cluster\_log\_kms\_key\_id) | If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html). | `string` | `""` | no |
| <a name="input_cluster_log_retention_in_days"></a> [cluster\_log\_retention\_in\_days](#input\_cluster\_log\_retention\_in\_days) | Number of days to retain log events. Defaults to 365 days. | `number` | `365` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources. Must be 16 characters or less. | `string` | `""` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The version of Kubernetes to be installed. | `string` | `"1.20"` | no |
| <a name="input_csi_helm_chart_name"></a> [csi\_helm\_chart\_name](#input\_csi\_helm\_chart\_name) | The name of the Helm chart in the repository for CSI. | `string` | `"aws-ebs-csi-driver"` | no |
| <a name="input_csi_helm_chart_repository"></a> [csi\_helm\_chart\_repository](#input\_csi\_helm\_chart\_repository) | The repository containing the CSI helm chart | `string` | `"https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"` | no |
| <a name="input_csi_helm_chart_version"></a> [csi\_helm\_chart\_version](#input\_csi\_helm\_chart\_version) | Helm chart version for CSI | `string` | `"2.8.0"` | no |
| <a name="input_csi_settings"></a> [csi\_settings](#input\_csi\_settings) | Additional settings which will be passed to the Helm chart values, see https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml for available options. | `map(any)` | `{}` | no |
| <a name="input_disk_encryption_kms_key_id"></a> [disk\_encryption\_kms\_key\_id](#input\_disk\_encryption\_kms\_key\_id) | The KMS Key ARN to use for disk encryption. | `string` | `""` | no |
| <a name="input_enable_aws_load_balancer_controller"></a> [enable\_aws\_load\_balancer\_controller](#input\_enable\_aws\_load\_balancer\_controller) | Whether to enable the AWS Load Balancer Controller addon on the cluster. Defaults to "true", and in most situations is required by StreamNative Cloud. | `bool` | `true` | no |
| <a name="input_enable_calico"></a> [enable\_calico](#input\_enable\_calico) | Enables the Calico networking service on the cluster. Defaults to "false". | `bool` | `false` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Enables the Cert-Manager addon service on the cluster. Defaults to "true", and in most situations is required by StreamNative Cloud. | `bool` | `true` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Enables the Cluster Autoscaler addon service on the cluster. Defaults to "true", and in most situations is recommened for StreamNative Cloud. | `bool` | `true` | no |
| <a name="input_enable_csi"></a> [enable\_csi](#input\_enable\_csi) | Enables the EBS Container Storage Interface (CSI) driver on the cluster, which allows for EKS manage the lifecycle of persistant volumes in EBS. | `bool` | `true` | no |
| <a name="input_enable_external_dns"></a> [enable\_external\_dns](#input\_enable\_external\_dns) | Enables the External DNS addon service on the cluster. Defaults to "true", and in most situations is required by StreamNative Cloud. | `bool` | `true` | no |
| <a name="input_enable_func_pool_monitoring"></a> [enable\_func\_pool\_monitoring](#input\_enable\_func\_pool\_monitoring) | Enable CloudWatch monitoring for the dedicated function pool(s). | `bool` | `true` | no |
| <a name="input_enable_external_secrets"></a> [enable\_external\_secrets](#input\_enable\_external\_secrets) | Enables kubernetes-external-secrets addon service on the cluster. Defaults to "false" | `bool` | `false` | no |
| <a name="input_enable_func_pool"></a> [enable\_func\_pool](#input\_enable\_func\_pool) | Enable an additional dedicated function pool. | `bool` | `true` | no |
| <a name="input_enable_istio"></a> [enable\_istio](#input\_enable\_istio) | Enables Istio on the cluster. Set to "true" by default. | `bool` | `true` | no |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Enables the Kubernetes Metrics Server addon service on the cluster. Defaults to "true". | `bool` | `true` | no |
| <a name="input_enable_node_group_private_networking"></a> [enable\_node\_group\_private\_networking](#input\_enable\_node\_group\_private\_networking) | Enables private networking for the EKS node groups (not the EKS cluster endpoint, which remains public), meaning Kubernetes API requests that originate within the cluster's VPC use a private VPC endpoint for EKS. Defaults to "true". | `bool` | `true` | no |
| <a name="input_enable_node_pool_monitoring"></a> [enable\_node\_pool\_monitoring](#input\_enable\_node\_pool\_monitoring) | Enable CloudWatch monitoring for the default pool(s). | `bool` | `true` | no |
| <a name="input_external_dns_helm_chart_name"></a> [external\_dns\_helm\_chart\_name](#input\_external\_dns\_helm\_chart\_name) | The name of the Helm chart in the repository for ExternalDNS. | `string` | `"external-dns"` | no |
| <a name="input_external_dns_helm_chart_repository"></a> [external\_dns\_helm\_chart\_repository](#input\_external\_dns\_helm\_chart\_repository) | The repository containing the ExternalDNS helm chart. | `string` | `"https://charts.bitnami.com/bitnami"` | no |
| <a name="input_external_dns_helm_chart_version"></a> [external\_dns\_helm\_chart\_version](#input\_external\_dns\_helm\_chart\_version) | Helm chart version for ExternalDNS. See https://hub.helm.sh/charts/bitnami/external-dns for updates. | `string` | `"6.5.6"` | no |
| <a name="input_external_dns_settings"></a> [external\_dns\_settings](#input\_external\_dns\_settings) | Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns. | `map(any)` | `{}` | no |
| <a name="input_external_secrets_helm_chart_name"></a> [external\_secrets\_helm\_chart\_name](#input\_external\_secrets\_helm\_chart\_name) | The name of the Helm chart in the repository for kubernetes-external-secrets. | `string` | `"kubernetes-external-secrets"` | no |
| <a name="input_external_secrets_helm_chart_repository"></a> [external\_secrets\_helm\_chart\_repository](#input\_external\_secrets\_helm\_chart\_repository) | The repository containing the kubernetes-external-secrets helm chart. | `string` | `"https://external-secrets.github.io/kubernetes-external-secrets"` | no |
| <a name="input_external_secrets_helm_chart_version"></a> [external\_secrets\_helm\_chart\_version](#input\_external\_secrets\_helm\_chart\_version) | Helm chart version for kubernetes-external-secrets. Defaults to "8.3.0". See https://github.com/external-secrets/kubernetes-external-secrets/tree/master/charts/kubernetes-external-secrets for updates. | `string` | `"8.3.0"` | no |
| <a name="input_external_secrets_settings"></a> [external\_secrets\_settings](#input\_external\_secrets\_settings) | Additional settings which will be passed to the Helm chart values, see https://github.com/external-secrets/kubernetes-external-secrets/tree/master/charts/kubernetes-external-secrets for available options. | `map(any)` | `{}` | no |
| <a name="input_func_pool_ami_id"></a> [func\_pool\_ami\_id](#input\_func\_pool\_ami\_id) | The AMI ID to use for the func pool nodes. Defaults to the latest EKS Optimized AMI provided by AWS | `string` | `""` | no |
| <a name="input_func_pool_ami_is_eks_optimized"></a> [func\_pool\_ami\_is\_eks\_optimized](#input\_func\_pool\_ami\_is\_eks\_optimized) | If the custom AMI is an EKS optimized image, ignored if ami\_id is not set. If this is true then bootstrap.sh is called automatically (max pod logic needs to be manually set), if this is false you need to provide all the node configuration in pre\_userdata | `bool` | `true` | no |
| <a name="input_func_pool_desired_size"></a> [func\_pool\_desired\_size](#input\_func\_pool\_desired\_size) | Desired number of worker nodes | `number` | `0` | no |
| <a name="input_func_pool_disk_size"></a> [func\_pool\_disk\_size](#input\_func\_pool\_disk\_size) | Disk size in GiB for function worker nodes. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided. | `number` | `50` | no |
| <a name="input_func_pool_disk_type"></a> [func\_pool\_disk\_type](#input\_func\_pool\_disk\_type) | Disk type for function worker nodes. Defaults to gp3. | `string` | `"gp3"` | no |
| <a name="input_func_pool_instance_types"></a> [func\_pool\_instance\_types](#input\_func\_pool\_instance\_types) | Set of instance types associated with the EKS Node Group. Defaults to ["t3.large"]. Terraform will only perform drift detection if a configuration value is provided. | `list(string)` | <pre>[<br>  "c6i.large"<br>]</pre> | no |
| <a name="input_func_pool_labels"></a> [func\_pool\_labels](#input\_func\_pool\_labels) | Labels to apply to the function pool node group. Defaults to {}. | `map(string)` | `{}` | no |
| <a name="input_func_pool_max_size"></a> [func\_pool\_max\_size](#input\_func\_pool\_max\_size) | The maximum size of the AutoScaling Group. | `number` | `5` | no |
| <a name="input_func_pool_min_size"></a> [func\_pool\_min\_size](#input\_func\_pool\_min\_size) | The minimum size of the AutoScaling Group. | `number` | `0` | no |
| <a name="input_func_pool_namespace"></a> [func\_pool\_namespace](#input\_func\_pool\_namespace) | The namespace where functions run. | `string` | `"pulsar-funcs"` | no |
| <a name="input_func_pool_pre_userdata"></a> [func\_pool\_pre\_userdata](#input\_func\_pool\_pre\_userdata) | The pre-userdata script to run on the function worker nodes. | `string` | `""` | no |
| <a name="input_func_pool_sa_name"></a> [func\_pool\_sa\_name](#input\_func\_pool\_sa\_name) | The service account name the functions use. | `string` | `"default"` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | The ID of the Route53 hosted zone used by the cluster's External DNS configuration. | `string` | n/a | yes |
| <a name="input_iam_path"></a> [iam\_path](#input\_iam\_path) | An IAM Path to be used for all IAM resources created by this module. Changing this from the default will cause issues with StreamNative's Vendor access, if applicable. | `string` | `"/StreamNative/"` | no |
| <a name="input_istio_mesh_id"></a> [istio\_mesh\_id](#input\_istio\_mesh\_id) | The ID used by the Istio mesh. This is also the ID of the StreamNative Cloud Pool used for the workload environments. This is required when "enable\_istio\_operator" is set to "true". | `string` | `null` | no |
| <a name="input_istio_network"></a> [istio\_network](#input\_istio\_network) | The name of network used for the Istio deployment. This is required when "enable\_istio\_operator" is set to "true". | `string` | `"default"` | no |
| <a name="input_istio_network_loadbancer"></a> [istio\_network\_loadbancer](#input\_istio\_network\_loadbancer) | n/a | `string` | `"internet_facing"` | no |
| <a name="input_istio_profile"></a> [istio\_profile](#input\_istio\_profile) | The path or name for an Istio profile to load. Set to the profile "default" if not specified. | `string` | `"default"` | no |
| <a name="input_istio_revision_tag"></a> [istio\_revision\_tag](#input\_istio\_revision\_tag) | The revision tag value use for the Istio label "istio.io/rev". | `string` | `"sn-stable"` | no |
| <a name="input_istio_settings"></a> [istio\_settings](#input\_istio\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `{}` | no |
| <a name="input_istio_trust_domain"></a> [istio\_trust\_domain](#input\_istio\_trust\_domain) | The trust domain used for the Istio deployment, which corresponds to the root of a system. This is required when "enable\_istio\_operator" is set to "true". | `string` | `"cluster.local"` | no |
| <a name="input_kiali_operator_settings"></a> [kiali\_operator\_settings](#input\_kiali\_operator\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `{}` | no |
| <a name="input_map_additional_aws_accounts"></a> [map\_additional\_aws\_accounts](#input\_map\_additional\_aws\_accounts) | Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap. | `list(string)` | `[]` | no |
| <a name="input_map_additional_iam_roles"></a> [map\_additional\_iam\_roles](#input\_map\_additional\_iam\_roles) | Additional IAM roles to add to `config-map-aws-auth` ConfigMap. | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_map_additional_iam_users"></a> [map\_additional\_iam\_users](#input\_map\_additional\_iam\_users) | Additional IAM roles to add to `config-map-aws-auth` ConfigMap. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_node_pool_ami_id"></a> [node\_pool\_ami\_id](#input\_node\_pool\_ami\_id) | The AMI ID to use for the EKS cluster nodes. Defaults to the latest EKS Optimized AMI provided by AWS | `string` | `""` | no |
| <a name="input_node_pool_ami_is_eks_optimized"></a> [node\_pool\_ami\_is\_eks\_optimized](#input\_node\_pool\_ami\_is\_eks\_optimized) | If the custom AMI is an EKS optimized image, ignored if ami\_id is not set. If this is true then bootstrap.sh is called automatically (max pod logic needs to be manually set), if this is false you need to provide all the node configuration in pre\_userdata | `bool` | `true` | no |
| <a name="input_node_pool_desired_size"></a> [node\_pool\_desired\_size](#input\_node\_pool\_desired\_size) | Desired number of worker nodes in the node pool. | `number` | `1` | no |
| <a name="input_metrics_server_helm_chart_name"></a> [metrics\_server\_helm\_chart\_name](#input\_metrics\_server\_helm\_chart\_name) | The name of the helm release to install | `string` | `"metrics-server"` | no |
| <a name="input_metrics_server_helm_chart_repository"></a> [metrics\_server\_helm\_chart\_repository](#input\_metrics\_server\_helm\_chart\_repository) | The repository containing the external-metrics helm chart. | `string` | `"https://kubernetes-sigs.github.io/metrics-server"` | no |
| <a name="input_metrics_server_helm_chart_version"></a> [metrics\_server\_helm\_chart\_version](#input\_metrics\_server\_helm\_chart\_version) | Helm chart version for Metrics server | `string` | `"3.8.2"` | no |
| <a name="input_metrics_server_settings"></a> [metrics\_server\_settings](#input\_metrics\_server\_settings) | Additional settings which will be passed to the Helm chart values, see https://github.com/external-secrets/kubernetes-external-secrets/tree/master/charts/kubernetes-external-secrets for available options. | `map(any)` | `{}` | no |
| <a name="input_node_pool_disk_size"></a> [node\_pool\_disk\_size](#input\_node\_pool\_disk\_size) | Disk size in GiB for worker nodes in the node pool. Defaults to 50. | `number` | `50` | no |
| <a name="input_node_pool_disk_type"></a> [node\_pool\_disk\_type](#input\_node\_pool\_disk\_type) | Disk type for worker nodes in the node pool. Defaults to gp3. | `string` | `"gp3"` | no |
| <a name="input_node_pool_instance_types"></a> [node\_pool\_instance\_types](#input\_node\_pool\_instance\_types) | Set of instance types associated with the EKS Node Group. Defaults to ["c6i.large"]. | `list(string)` | <pre>[<br>  "c6i.large"<br>]</pre> | no |
| <a name="input_node_pool_labels"></a> [node\_pool\_labels](#input\_node\_pool\_labels) | A map of kubernetes labels to add to the node pool. | `map(string)` | `{}` | no |
| <a name="input_node_pool_max_size"></a> [node\_pool\_max\_size](#input\_node\_pool\_max\_size) | The maximum size of the node pool Autoscaling group. | `number` | n/a | yes |
| <a name="input_node_pool_min_size"></a> [node\_pool\_min\_size](#input\_node\_pool\_min\_size) | The minimum size of the node pool AutoScaling group. | `number` | n/a | yes |
| <a name="input_node_termination_handler_chart_version"></a> [node\_termination\_handler\_chart\_version](#input\_node\_termination\_handler\_chart\_version) | The version of the Helm chart to use for the AWS Node Termination Handler. | `string` | `"0.18.5"` | no |
| <a name="input_node_pool_pre_userdata"></a> [node\_pool\_pre\_userdata](#input\_node\_pool\_pre\_userdata) | The user data to apply to the worker nodes in the node pool. This is applied before the bootstrap.sh script. | `string` | `""` | no |
| <a name="input_node_termination_handler_chart_version"></a> [node\_termination\_handler\_chart\_version](#input\_node\_termination\_handler\_chart\_version) | The version of the Helm chart to use for the AWS Node Termination Handler. | `string` | `"0.16.0"` | no |
| <a name="input_node_termination_handler_helm_chart_name"></a> [node\_termination\_handler\_helm\_chart\_name](#input\_node\_termination\_handler\_helm\_chart\_name) | The name of the Helm chart to use for the AWS Node Termination Handler. | `string` | `"aws-node-termination-handler"` | no |
| <a name="input_node_termination_handler_helm_chart_repository"></a> [node\_termination\_handler\_helm\_chart\_repository](#input\_node\_termination\_handler\_helm\_chart\_repository) | The repository containing the Helm chart to use for the AWS Node Termination Handler. | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_node_termination_handler_settings"></a> [node\_termination\_handler\_settings](#input\_node\_termination\_handler\_settings) | Additional settings which will be passed to the Helm chart values for the AWS Node Termination Handler. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options. | `map(string)` | `{}` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access. | `string` | `null` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The ids of existing private subnets. | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | The ids of existing public subnets. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region. | `string` | `null` | no |
| <a name="input_service_domain"></a> [service\_domain](#input\_service\_domain) | The DNS domain for external service endpoints. This must be set when enabling Istio or else the deployment will fail. | `string` | `null` | no |
| <a name="input_sncloud_services_iam_policy_arn"></a> [sncloud\_services\_iam\_policy\_arn](#input\_sncloud\_services\_iam\_policy\_arn) | The IAM policy ARN to be used for all StreamNative Cloud Services that need to interact with AWS services external to EKS. This policy is typically created by the "modules/managed-cloud" sub-module in this repository, as a seperate customer driven process for managing StreamNative's Vendor Access into AWS. If no policy ARN is provided, the module will generate the policies needed by each cluster service we install and expects that the caller identity has appropriate IAM permissions that allow "iam:CreatePolicy" action. Otherwise the module will fail to run properly. Depends upon use | `string` | `""` | no |
| <a name="input_sncloud_services_lb_policy_arn"></a> [sncloud\_services\_lb\_policy\_arn](#input\_sncloud\_services\_lb\_policy\_arn) | A custom IAM policy ARN for LB load balancer controller. If not specified, and use\_runt | `string` | `""` | no |
| <a name="input_use_runtime_policy"></a> [use\_runtime\_policy](#input\_use\_runtime\_policy) | Indicates to use the runtime policy and attach a predefined policies as opposed to create roles. Currently defaults to false | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC to use. | `string` | `""` | no |
| <a name="input_wait_for_cluster_timeout"></a> [wait\_for\_cluster\_timeout](#input\_wait\_for\_cluster\_timeout) | Time in seconds to wait for the newly provisioned EKS cluster's API/healthcheck endpoint to return healthy, before applying the aws-auth configmap. Defaults to 300 seconds in the parent module "terraform-aws-modules/eks/aws", which is often too short. Increase to at least 900 seconds, if needed. See also https://github.com/terraform-aws-modules/terraform-aws-eks/pull/1420. | `number` | `0` | no |

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
| <a name="output_worker_iam_role_arn"></a> [worker\_iam\_role\_arn](#output\_worker\_iam\_role\_arn) | The IAM Role ARN used by the Worker configuration |
<!-- END_TF_DOCS -->
