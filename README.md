<!--
  ~ Copyright 2023 StreamNative, Inc.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
-->

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

  cluster_name                   = "sn-cluster-${var.region}"
  cluster_version                = "1.21"
  hosted_zone_id                 = "Z04554535IN8Z31SKDVQ2" # Change this to your hosted zone ID
  node_pool_max_size             = 3

  ## Note: EKS requires two subnets, each in their own availability zone
  public_subnet_ids  = ["subnet-abcde012", "subnet-bcde012a"]
  private_subnet_ids = ["subnet-vwxyz123", "subnet-efgh242a"]
  region             = var.region
  vpc_id             = "vpc-1234556abcdef"
}
```

In the example `main.tf` above, a StreamNative Platform EKS cluster is created using Kubernetes version `1.21`. 

By default, the cluster will come provisioned with 8 node groups (_reference node topology[^1]_), six of which have a desired capacity set to `0`, and only the "xlarge" node group has a default desired capacity of `1`. All 

In addition, the EKS cluster will be configured to support the following add-ons:

- [AWS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
- [AWS Node Terminiation Handler](https://github.com/aws/aws-node-termination-handler)
- [cert-manager](https://github.com/jetstack/cert-manager)
- [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [external-dns](https://github.com/kubernetes-sigs/external-dns)
- [Istio](https://istio.io/)
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 
- [Velero](https://velero.io/) (for backup and restore)

## Creating a StreamNative Platform EKS Cluster
When deploying StreamNative Platform, there are additional resources to be created alongside (and inside!) the EKS cluster:

- StreamNative operators for Pulsar
- Vault Configuration & Resources

We have made this easy by creating additional Terraform modules that can be included alongside your EKS module composition. Consider adding the following to the example `main.tf` file above:

```hcl
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


[^1]: When running Apache Pulsar in Kubernetes, we make use of EBS backed Kubernetes Persistent Volume Claims (PVC). EBS volumes themselves are zonal, which means [an EC2 instance can only mount a volume that exists in its same AWS Availability Zone](https://aws.amazon.com/blogs/containers/amazon-eks-cluster-multi-zone-auto-scaling-groups/). For this reason we have added node group "zone affinity" functionality into our module, where **an EKS node group is created per AWS Availability Zone**. This is controlled by the number of subnets you pass to the EKS module, creating one node group per subnet. In addition, we also create node groups based on instance classes, which allows us to perform more fine tuned control around scheduling and resource utilization. To illustrate, if a cluster is being created across 3 availability zones and the default 4 instance classes are being used, then 12 total node groups will be created, all except the nodes belonging to the `xlarge` (which has a default capicty of `1` for initial scheduling of workloads) group will remain empty until a corresponding Pulsar or addon workload is deployed.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=3.61.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >=2.6.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.49.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.16.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 18.30.2 |
| <a name="module_istio"></a> [istio](#module\_istio) | github.com/streamnative/terraform-helm-charts//modules/istio-operator | v0.8.6 |
| <a name="module_vpc_tags"></a> [vpc\_tags](#module\_vpc\_tags) | ./modules/eks-vpc-tags | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_tag.cluster_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_iam_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ng](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.csi_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ng_AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ng_AmazonEKSVPCResourceControllerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ng_AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cert_issuer](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cilium](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.csi](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.metrics_server](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [helm_release.velero](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |
| [kubernetes_namespace.sn_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.velero](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
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
| [aws_iam_policy_document.ng_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.ebs_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_kms_key.s3_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_subnet.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

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
| <a name="input_cert_issuer_support_email"></a> [cert\_issuer\_support\_email](#input\_cert\_issuer\_support\_email) | The email address to receive notifications from the cert issuer. | `string` | `"certs-support@streamnative.io"` | no |
| <a name="input_cert_manager_helm_chart_name"></a> [cert\_manager\_helm\_chart\_name](#input\_cert\_manager\_helm\_chart\_name) | The name of the Helm chart in the repository for cert-manager. | `string` | `"cert-manager"` | no |
| <a name="input_cert_manager_helm_chart_repository"></a> [cert\_manager\_helm\_chart\_repository](#input\_cert\_manager\_helm\_chart\_repository) | The repository containing the cert-manager helm chart. | `string` | `"https://charts.bitnami.com/bitnami"` | no |
| <a name="input_cert_manager_helm_chart_version"></a> [cert\_manager\_helm\_chart\_version](#input\_cert\_manager\_helm\_chart\_version) | Helm chart version for the cert-manager. See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for version releases. | `string` | `"0.6.2"` | no |
| <a name="input_cert_manager_settings"></a> [cert\_manager\_settings](#input\_cert\_manager\_settings) | Additional settings which will be passed to the Helm chart values. See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for available options. | `map(any)` | `{}` | no |
| <a name="input_cilium_helm_chart_name"></a> [cilium\_helm\_chart\_name](#input\_cilium\_helm\_chart\_name) | The name of the Helm chart in the repository for Cilium. | `string` | `"cilium"` | no |
| <a name="input_cilium_helm_chart_repository"></a> [cilium\_helm\_chart\_repository](#input\_cilium\_helm\_chart\_repository) | The repository containing the Cilium helm chart. | `string` | `"https://helm.cilium.io"` | no |
| <a name="input_cilium_helm_chart_version"></a> [cilium\_helm\_chart\_version](#input\_cilium\_helm\_chart\_version) | Helm chart version for Cilium. See https://artifacthub.io/packages/helm/cilium/cilium for updates. | `string` | `"1.13.2"` | no |
| <a name="input_cluster_autoscaler_helm_chart_name"></a> [cluster\_autoscaler\_helm\_chart\_name](#input\_cluster\_autoscaler\_helm\_chart\_name) | The name of the Helm chart in the repository for cluster-autoscaler. | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_helm_chart_repository"></a> [cluster\_autoscaler\_helm\_chart\_repository](#input\_cluster\_autoscaler\_helm\_chart\_repository) | The repository containing the cluster-autoscaler helm chart. | `string` | `"https://kubernetes.github.io/autoscaler"` | no |
| <a name="input_cluster_autoscaler_helm_chart_version"></a> [cluster\_autoscaler\_helm\_chart\_version](#input\_cluster\_autoscaler\_helm\_chart\_version) | Helm chart version for the cluster-autoscaler. Defaults to "9.10.4". See https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for more details. | `string` | `"9.21.0"` | no |
| <a name="input_cluster_autoscaler_settings"></a> [cluster\_autoscaler\_settings](#input\_cluster\_autoscaler\_settings) | Additional settings which will be passed to the Helm chart values for cluster-autoscaler, see https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for options. | `map(any)` | `{}` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). | `list(string)` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources. Must be 16 characters or less. | `string` | `""` | no |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | Additional rules to add to the cluster security group. Set source\_node\_security\_group = true inside rules to set the node\_security\_group as source. | `any` | `{}` | no |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | The ID of an existing security group to use for the EKS cluster. If not provided, a new security group will be created. | `string` | `""` | no |
| <a name="input_cluster_service_ipv4_cidr"></a> [cluster\_service\_ipv4\_cidr](#input\_cluster\_service\_ipv4\_cidr) | The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks | `string` | `null` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The version of Kubernetes to be installed. | `string` | `"1.20"` | no |
| <a name="input_create_cluster_security_group"></a> [create\_cluster\_security\_group](#input\_create\_cluster\_security\_group) | Whether to create a new security group for the EKS cluster. If set to false, you must provide an existing security group via the cluster\_security\_group\_id variable. | `bool` | `true` | no |
| <a name="input_create_iam_policies"></a> [create\_iam\_policies](#input\_create\_iam\_policies) | Whether to create IAM policies for the IAM roles. If set to false, the module will default to using existing policy ARNs that must be present in the AWS account | `bool` | `false` | no |
| <a name="input_create_node_security_group"></a> [create\_node\_security\_group](#input\_create\_node\_security\_group) | Whether to create a new security group for the EKS nodes. If set to false, you must provide an existing security group via the node\_security\_group\_id variable. | `bool` | `true` | no |
| <a name="input_csi_helm_chart_name"></a> [csi\_helm\_chart\_name](#input\_csi\_helm\_chart\_name) | The name of the Helm chart in the repository for CSI. | `string` | `"aws-ebs-csi-driver"` | no |
| <a name="input_csi_helm_chart_repository"></a> [csi\_helm\_chart\_repository](#input\_csi\_helm\_chart\_repository) | The repository containing the CSI helm chart | `string` | `"https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"` | no |
| <a name="input_csi_helm_chart_version"></a> [csi\_helm\_chart\_version](#input\_csi\_helm\_chart\_version) | Helm chart version for CSI | `string` | `"2.8.0"` | no |
| <a name="input_csi_settings"></a> [csi\_settings](#input\_csi\_settings) | Additional settings which will be passed to the Helm chart values, see https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml for available options. | `map(any)` | `{}` | no |
| <a name="input_disable_public_eks_endpoint"></a> [disable\_public\_eks\_endpoint](#input\_disable\_public\_eks\_endpoint) | Whether to disable public access to the EKS control plane endpoint. If set to "true", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to "false" unless you are familiar with this type of configuration. | `bool` | `false` | no |
| <a name="input_disable_public_pulsar_endpoint"></a> [disable\_public\_pulsar\_endpoint](#input\_disable\_public\_pulsar\_endpoint) | Whether or not to make the Istio Gateway use a public facing or internal network load balancer. If set to "true", additional configuration is required in order to manage the cluster from the StreamNative console | `bool` | `false` | no |
| <a name="input_disk_encryption_kms_key_arn"></a> [disk\_encryption\_kms\_key\_arn](#input\_disk\_encryption\_kms\_key\_arn) | The KMS Key ARN to use for EBS disk encryption. If not set, the default EBS encryption key will be used. | `string` | `""` | no |
| <a name="input_enable_bootstrap"></a> [enable\_bootstrap](#input\_enable\_bootstrap) | Enables bootstrapping of add-ons within the cluster. | `bool` | `true` | no |
| <a name="input_enable_cilium"></a> [enable\_cilium](#input\_enable\_cilium) | Enables Cilium on the cluster. Set to "false" by default. | `bool` | `false` | no |
| <a name="input_enable_cilium_taint"></a> [enable\_cilium\_taint](#input\_enable\_cilium\_taint) | Adds the cillium taint to nodes. Is "true" by default. Should set to "false" if adding cillium to existing pool | `bool` | `true` | no |
| <a name="input_enable_istio"></a> [enable\_istio](#input\_enable\_istio) | Allows for enabling the bootstrap of Istio explicity in scenarios where the input "var.enable\_bootstrap" is set to "false". | `bool` | `true` | no |
| <a name="input_enable_node_group_private_networking"></a> [enable\_node\_group\_private\_networking](#input\_enable\_node\_group\_private\_networking) | Enables private networking for the EKS node groups (not the EKS cluster endpoint, which remains public), meaning Kubernetes API requests that originate within the cluster's VPC use a private VPC endpoint for EKS. Defaults to "true". | `bool` | `true` | no |
| <a name="input_enable_node_pool_monitoring"></a> [enable\_node\_pool\_monitoring](#input\_enable\_node\_pool\_monitoring) | Enable CloudWatch monitoring for the default pool(s). | `bool` | `false` | no |
| <a name="input_enable_nodes_use_public_subnet"></a> [enable\_nodes\_use\_public\_subnet](#input\_enable\_nodes\_use\_public\_subnet) | When set to true, the node groups will use public subnet rather private subnet, and the public subnet must enable auto-assing public ip so that nodes can have public ip to access internet. Default is false. | `bool` | `false` | no |
| <a name="input_enable_resource_creation"></a> [enable\_resource\_creation](#input\_enable\_resource\_creation) | When enabled, all dependencies, like roles, buckets, etc will be created. When disabled, they will note. Use in combination with `enable_bootstrap` to manage these outside this module | `bool` | `true` | no |
| <a name="input_enable_sncloud_control_plane_access"></a> [enable\_sncloud\_control\_plane\_access](#input\_enable\_sncloud\_control\_plane\_access) | Whether to enable access to the EKS control plane endpoint. If set to "false", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to "true" unless you are familiar with this type of configuration. | `bool` | `true` | no |
| <a name="input_enable_v3_node_groups"></a> [enable\_v3\_node\_groups](#input\_enable\_v3\_node\_groups) | Enable v3 node groups, which uses a single ASG and all other node groups enabled elsewhere | `bool` | `false` | no |
| <a name="input_enable_v3_node_migration"></a> [enable\_v3\_node\_migration](#input\_enable\_v3\_node\_migration) | Enable v3 node and v2 node groups at the same time. Intended for use with migration to v3 nodes. | `bool` | `false` | no |
| <a name="input_enable_v3_node_taints"></a> [enable\_v3\_node\_taints](#input\_enable\_v3\_node\_taints) | When v3 node groups are enabled, use the node taints. Defaults to true | `bool` | `true` | no |
| <a name="input_external_dns_helm_chart_name"></a> [external\_dns\_helm\_chart\_name](#input\_external\_dns\_helm\_chart\_name) | The name of the Helm chart in the repository for ExternalDNS. | `string` | `"external-dns"` | no |
| <a name="input_external_dns_helm_chart_repository"></a> [external\_dns\_helm\_chart\_repository](#input\_external\_dns\_helm\_chart\_repository) | The repository containing the ExternalDNS helm chart. | `string` | `"https://charts.bitnami.com/bitnami"` | no |
| <a name="input_external_dns_helm_chart_version"></a> [external\_dns\_helm\_chart\_version](#input\_external\_dns\_helm\_chart\_version) | Helm chart version for ExternalDNS. See https://hub.helm.sh/charts/bitnami/external-dns for updates. | `string` | `"6.10.2"` | no |
| <a name="input_external_dns_settings"></a> [external\_dns\_settings](#input\_external\_dns\_settings) | Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns. | `map(any)` | `{}` | no |
| <a name="input_hosted_zone_domain_name_filters"></a> [hosted\_zone\_domain\_name\_filters](#input\_hosted\_zone\_domain\_name\_filters) | A list domain names of the Route53 hosted zones, used by the cluster's External DNS configuration for domain filtering. | `list(string)` | `[]` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | The ID of the Route53 hosted zone used by the cluster's External DNS configuration. | `string` | `"*"` | no |
| <a name="input_iam_path"></a> [iam\_path](#input\_iam\_path) | An IAM Path to be used for all IAM resources created by this module. Changing this from the default will cause issues with StreamNative's Vendor access, if applicable. | `string` | `"/StreamNative/"` | no |
| <a name="input_istio_mesh_id"></a> [istio\_mesh\_id](#input\_istio\_mesh\_id) | The ID used by the Istio mesh. This is also the ID of the StreamNative Cloud Pool used for the workload environments. This is required when "enable\_istio\_operator" is set to "true". | `string` | `null` | no |
| <a name="input_istio_network"></a> [istio\_network](#input\_istio\_network) | The name of network used for the Istio deployment. This is required when "enable\_istio\_operator" is set to "true". | `string` | `"default"` | no |
| <a name="input_istio_profile"></a> [istio\_profile](#input\_istio\_profile) | The path or name for an Istio profile to load. Set to the profile "default" if not specified. | `string` | `"default"` | no |
| <a name="input_istio_revision_tag"></a> [istio\_revision\_tag](#input\_istio\_revision\_tag) | The revision tag value use for the Istio label "istio.io/rev". | `string` | `"sn-stable"` | no |
| <a name="input_istio_settings"></a> [istio\_settings](#input\_istio\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `{}` | no |
| <a name="input_istio_trust_domain"></a> [istio\_trust\_domain](#input\_istio\_trust\_domain) | The trust domain used for the Istio deployment, which corresponds to the root of a system. This is required when "enable\_istio\_operator" is set to "true". | `string` | `"cluster.local"` | no |
| <a name="input_kiali_operator_settings"></a> [kiali\_operator\_settings](#input\_kiali\_operator\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `{}` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Whether to manage the aws\_auth configmap | `bool` | `true` | no |
| <a name="input_map_additional_iam_roles"></a> [map\_additional\_iam\_roles](#input\_map\_additional\_iam\_roles) | A list of IAM role bindings to add to the aws-auth ConfigMap. | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_metrics_server_helm_chart_name"></a> [metrics\_server\_helm\_chart\_name](#input\_metrics\_server\_helm\_chart\_name) | The name of the helm release to install | `string` | `"metrics-server"` | no |
| <a name="input_metrics_server_helm_chart_repository"></a> [metrics\_server\_helm\_chart\_repository](#input\_metrics\_server\_helm\_chart\_repository) | The repository containing the external-metrics helm chart. | `string` | `"https://kubernetes-sigs.github.io/metrics-server"` | no |
| <a name="input_metrics_server_helm_chart_version"></a> [metrics\_server\_helm\_chart\_version](#input\_metrics\_server\_helm\_chart\_version) | Helm chart version for Metrics server | `string` | `"3.8.2"` | no |
| <a name="input_metrics_server_settings"></a> [metrics\_server\_settings](#input\_metrics\_server\_settings) | Additional settings which will be passed to the Helm chart values, see https://github.com/external-secrets/kubernetes-external-secrets/tree/master/charts/kubernetes-external-secrets for available options. | `map(any)` | `{}` | no |
| <a name="input_migration_mode"></a> [migration\_mode](#input\_migration\_mode) | Whether to enable migration mode for the cluster. This is used to migrate details from existing security groups, which have had their names and description changed in versions v18.X of the community EKS module. | `bool` | `false` | no |
| <a name="input_migration_mode_node_sg_name"></a> [migration\_mode\_node\_sg\_name](#input\_migration\_mode\_node\_sg\_name) | The name (not ID!) of the existing security group used by worker nodes. This is required when "migration\_mode" is set to "true", otherwise the parent module will attempt to set a new security group name and destroy the existin one. | `string` | `null` | no |
| <a name="input_node_pool_ami_id"></a> [node\_pool\_ami\_id](#input\_node\_pool\_ami\_id) | The AMI ID to use for the EKS cluster nodes. Defaults to the latest EKS Optimized AMI provided by AWS. | `string` | `""` | no |
| <a name="input_node_pool_block_device_name"></a> [node\_pool\_block\_device\_name](#input\_node\_pool\_block\_device\_name) | The name of the block device to use for the EKS cluster nodes. | `string` | `"/dev/nvme0n1"` | no |
| <a name="input_node_pool_desired_size"></a> [node\_pool\_desired\_size](#input\_node\_pool\_desired\_size) | Desired number of worker nodes in the node pool. | `number` | `0` | no |
| <a name="input_node_pool_disk_iops"></a> [node\_pool\_disk\_iops](#input\_node\_pool\_disk\_iops) | The amount of provisioned IOPS for the worker node root EBS volume. | `number` | `3000` | no |
| <a name="input_node_pool_disk_size"></a> [node\_pool\_disk\_size](#input\_node\_pool\_disk\_size) | Disk size in GiB for worker nodes in the node pool. Defaults to 50. | `number` | `100` | no |
| <a name="input_node_pool_disk_type"></a> [node\_pool\_disk\_type](#input\_node\_pool\_disk\_type) | Disk type for worker nodes in the node pool. Defaults to gp3. | `string` | `"gp3"` | no |
| <a name="input_node_pool_ebs_optimized"></a> [node\_pool\_ebs\_optimized](#input\_node\_pool\_ebs\_optimized) | If true, the launched EC2 instance(s) will be EBS-optimized. Specify this if using a custom AMI with pre-user data. | `bool` | `true` | no |
| <a name="input_node_pool_instance_types"></a> [node\_pool\_instance\_types](#input\_node\_pool\_instance\_types) | Set of instance types associated with the EKS Node Groups. Defaults to ["m6i.large", "m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge", "m6i.8xlarge"], which will create empty node groups of each instance type to account for any workload configurable from StreamNative Cloud. | `list(string)` | <pre>[<br>  "m6i.large",<br>  "m6i.xlarge",<br>  "m6i.2xlarge",<br>  "m6i.4xlarge",<br>  "m6i.8xlarge"<br>]</pre> | no |
| <a name="input_node_pool_labels"></a> [node\_pool\_labels](#input\_node\_pool\_labels) | A map of kubernetes labels to add to the node pool. | `map(string)` | `{}` | no |
| <a name="input_node_pool_max_size"></a> [node\_pool\_max\_size](#input\_node\_pool\_max\_size) | The maximum size of the node pool Autoscaling group. | `number` | n/a | yes |
| <a name="input_node_pool_min_size"></a> [node\_pool\_min\_size](#input\_node\_pool\_min\_size) | The minimum size of the node pool AutoScaling group. | `number` | `0` | no |
| <a name="input_node_pool_pre_userdata"></a> [node\_pool\_pre\_userdata](#input\_node\_pool\_pre\_userdata) | The user data to apply to the worker nodes in the node pool. This is applied before the bootstrap.sh script. | `string` | `""` | no |
| <a name="input_node_pool_tags"></a> [node\_pool\_tags](#input\_node\_pool\_tags) | A map of tags to add to the node groups and supporting resources. | `map(string)` | `{}` | no |
| <a name="input_node_pool_taints"></a> [node\_pool\_taints](#input\_node\_pool\_taints) | A list of taints in map format to apply to the node pool. | `any` | `{}` | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | Additional ingress rules to add to the node security group. Set source\_cluster\_security\_group = true inside rules to set the cluster\_security\_group as source | `any` | `{}` | no |
| <a name="input_node_security_group_id"></a> [node\_security\_group\_id](#input\_node\_security\_group\_id) | An ID of an existing security group to use for the EKS node groups. If not specified, a new security group will be created. | `string` | `""` | no |
| <a name="input_node_termination_handler_chart_version"></a> [node\_termination\_handler\_chart\_version](#input\_node\_termination\_handler\_chart\_version) | The version of the Helm chart to use for the AWS Node Termination Handler. | `string` | `"0.18.5"` | no |
| <a name="input_node_termination_handler_helm_chart_name"></a> [node\_termination\_handler\_helm\_chart\_name](#input\_node\_termination\_handler\_helm\_chart\_name) | The name of the Helm chart to use for the AWS Node Termination Handler. | `string` | `"aws-node-termination-handler"` | no |
| <a name="input_node_termination_handler_helm_chart_repository"></a> [node\_termination\_handler\_helm\_chart\_repository](#input\_node\_termination\_handler\_helm\_chart\_repository) | The repository containing the Helm chart to use for the AWS Node Termination Handler. | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_node_termination_handler_settings"></a> [node\_termination\_handler\_settings](#input\_node\_termination\_handler\_settings) | Additional settings which will be passed to the Helm chart values for the AWS Node Termination Handler. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options. | `map(string)` | `{}` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access. | `string` | `null` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The ids of existing private subnets. | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | The ids of existing public subnets. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region. | `string` | `null` | no |
| <a name="input_s3_encryption_kms_key_arn"></a> [s3\_encryption\_kms\_key\_arn](#input\_s3\_encryption\_kms\_key\_arn) | KMS key ARN to use for S3 encryption. If not set, the default AWS S3 key will be used. | `string` | `""` | no |
| <a name="input_service_domain"></a> [service\_domain](#input\_service\_domain) | When Istio is enabled, the FQDN needed specifically for Istio's authorization policies. | `string` | `""` | no |
| <a name="input_sncloud_services_iam_policy_arn"></a> [sncloud\_services\_iam\_policy\_arn](#input\_sncloud\_services\_iam\_policy\_arn) | The IAM policy ARN to be used for all StreamNative Cloud Services that need to interact with AWS services external to EKS. This policy is typically created by StreamNative's "terraform-managed-cloud" module, as a seperate customer driven process for managing StreamNative's Vendor Access into AWS. If no policy ARN is provided, the module will default to the expected named policy of "StreamNativeCloudRuntimePolicy". This variable allows for flexibility in the event that the policy name changes, or if a custom policy provided by the customer is preferred. | `string` | `""` | no |
| <a name="input_sncloud_services_lb_policy_arn"></a> [sncloud\_services\_lb\_policy\_arn](#input\_sncloud\_services\_lb\_policy\_arn) | A custom IAM policy ARN for LB load balancer controller. This policy is typically created by StreamNative's "terraform-managed-cloud" module, as a seperate customer driven process for managing StreamNative's Vendor Access into AWS. If no policy ARN is provided, the module will default to the expected named policy of "StreamNativeCloudLBPolicy". This variable allows for flexibility in the event that the policy name changes, or if a custom policy provided by the customer is preferred. | `string` | `""` | no |
| <a name="input_use_runtime_policy"></a> [use\_runtime\_policy](#input\_use\_runtime\_policy) | Legacy variable, will be deprecated in future versions. The preference of this module is to have the parent EKS module create and manage the IAM role. However some older configurations may have had the cluster IAM role managed seperately, and this variable allows for backwards compatibility. | `bool` | `false` | no |
| <a name="input_v3_node_group_core_instance_type"></a> [v3\_node\_group\_core\_instance\_type](#input\_v3\_node\_group\_core\_instance\_type) | The instance to use for the core node group | `string` | `"m6i.large"` | no |
| <a name="input_velero_backup_schedule"></a> [velero\_backup\_schedule](#input\_velero\_backup\_schedule) | The scheduled time for Velero to perform backups. Written in cron expression, defaults to "0 5 * * *" or "at 5:00am every day" | `string` | `"0 5 * * *"` | no |
| <a name="input_velero_excluded_namespaces"></a> [velero\_excluded\_namespaces](#input\_velero\_excluded\_namespaces) | A comma-separated list of namespaces to exclude from Velero backups. Defaults are set to ["default", "kube-system", "operators", "olm"]. | `list(string)` | <pre>[<br>  "kube-system",<br>  "default",<br>  "operators",<br>  "olm"<br>]</pre> | no |
| <a name="input_velero_helm_chart_name"></a> [velero\_helm\_chart\_name](#input\_velero\_helm\_chart\_name) | The name of the Helm chart to use for Velero | `string` | `"velero"` | no |
| <a name="input_velero_helm_chart_repository"></a> [velero\_helm\_chart\_repository](#input\_velero\_helm\_chart\_repository) | The repository containing the Helm chart to use for velero | `string` | `"https://vmware-tanzu.github.io/helm-charts"` | no |
| <a name="input_velero_helm_chart_version"></a> [velero\_helm\_chart\_version](#input\_velero\_helm\_chart\_version) | The version of the Helm chart to use for Velero. The current version can be found in github: https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero | `string` | `"2.31.8"` | no |
| <a name="input_velero_namespace"></a> [velero\_namespace](#input\_velero\_namespace) | The kubernetes namespace where Velero should be deployed. | `string` | `"velero"` | no |
| <a name="input_velero_plugin_version"></a> [velero\_plugin\_version](#input\_velero\_plugin\_version) | Which version of the velero-plugin-for-aws to use. | `string` | `"v1.5.1"` | no |
| <a name="input_velero_policy_arn"></a> [velero\_policy\_arn](#input\_velero\_policy\_arn) | The arn for the IAM policy used by the Velero backup addon service. For enhanced security, we allow for IAM policies used by cluster addon services to be created seperately from this module. This is only required if the input "create\_iam\_policy\_for\_velero" is set to "false". If created elsewhere, the expected name of the policy is "StreamNativeCloudVeleroBackupPolicy". | `string` | `null` | no |
| <a name="input_velero_settings"></a> [velero\_settings](#input\_velero\_settings) | Additional settings which will be passed to the Helm chart values for Velero. See https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero for available options | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC to use. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_loadbalancer_arn"></a> [aws\_loadbalancer\_arn](#output\_aws\_loadbalancer\_arn) | ARN for loadbalancer |
| <a name="output_cert_manager_arn"></a> [cert\_manager\_arn](#output\_cert\_manager\_arn) | The ARN for Cert Manager |
| <a name="output_cluster_autoscaler_arn"></a> [cluster\_autoscaler\_arn](#output\_cluster\_autoscaler\_arn) | ARN for Cluster Autoscaler |
| <a name="output_csi_arn"></a> [csi\_arn](#output\_csi\_arn) | ARN for csi |
| <a name="output_eks"></a> [eks](#output\_eks) | All outputs of module.eks for provide convenient approach to access child module's outputs. |
| <a name="output_eks_cluster_arn"></a> [eks\_cluster\_arn](#output\_eks\_cluster\_arn) | The ARN for the EKS cluster created by this module |
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | The endpoint for the EKS cluster created by this module |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | The id/name of the EKS cluster created by this module |
| <a name="output_eks_cluster_identity_oidc_issuer_arn"></a> [eks\_cluster\_identity\_oidc\_issuer\_arn](#output\_eks\_cluster\_identity\_oidc\_issuer\_arn) | The ARN for the OIDC issuer created by this module |
| <a name="output_eks_cluster_identity_oidc_issuer_string"></a> [eks\_cluster\_identity\_oidc\_issuer\_string](#output\_eks\_cluster\_identity\_oidc\_issuer\_string) | A formatted string containing the prefix for the OIDC issuer created by this module. Same as "cluster\_oidc\_issuer\_url", but with "https://" stripped from the name. This output is typically used in other StreamNative modules that request the "oidc\_issuer" input. |
| <a name="output_eks_cluster_identity_oidc_issuer_url"></a> [eks\_cluster\_identity\_oidc\_issuer\_url](#output\_eks\_cluster\_identity\_oidc\_issuer\_url) | The URL for the OIDC issuer created by this module |
| <a name="output_eks_cluster_platform_version"></a> [eks\_cluster\_platform\_version](#output\_eks\_cluster\_platform\_version) | The platform version for the EKS cluster created by this module |
| <a name="output_eks_cluster_primary_security_group_id"></a> [eks\_cluster\_primary\_security\_group\_id](#output\_eks\_cluster\_primary\_security\_group\_id) | The id of the primary security group created by the EKS service itself, not by this module. This is labeled "Cluster Security Group" in the EKS console. |
| <a name="output_eks_cluster_secondary_security_group_id"></a> [eks\_cluster\_secondary\_security\_group\_id](#output\_eks\_cluster\_secondary\_security\_group\_id) | The id of the secondary security group created by this module. This is labled "Additional Security Groups" in the EKS console. |
| <a name="output_eks_node_group_iam_role_arn"></a> [eks\_node\_group\_iam\_role\_arn](#output\_eks\_node\_group\_iam\_role\_arn) | The IAM Role ARN used by the Worker configuration |
| <a name="output_eks_node_group_security_group_id"></a> [eks\_node\_group\_security\_group\_id](#output\_eks\_node\_group\_security\_group\_id) | Security group ID attached to the EKS node groups |
| <a name="output_eks_node_groups"></a> [eks\_node\_groups](#output\_eks\_node\_groups) | Map of all attributes of the EKS node groups created by this module |
| <a name="output_external_dns_arn"></a> [external\_dns\_arn](#output\_external\_dns\_arn) | The ARN for External DNS |
| <a name="output_tiered_storage_s3_bucket_arn"></a> [tiered\_storage\_s3\_bucket\_arn](#output\_tiered\_storage\_s3\_bucket\_arn) | The ARN for the tiered storage S3 bucket created by this module |
| <a name="output_velero_arn"></a> [velero\_arn](#output\_velero\_arn) | ARN for Velero |
| <a name="output_velero_s3_bucket_arn"></a> [velero\_s3\_bucket\_arn](#output\_velero\_s3\_bucket\_arn) | The ARN for the Velero S3 bucket created by this module |
<!-- END_TF_DOCS -->
