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
  name = module.eks_cluster.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.eks_cluster_name
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.75.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.32.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.75.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 20.29.0 |
| <a name="module_eks_auth"></a> [eks\_auth](#module\_eks\_auth) | terraform-aws-modules/eks/aws//modules/aws-auth | 20.29.0 |
| <a name="module_vpc_tags"></a> [vpc\_tags](#module\_vpc\_tags) | ./modules/eks-vpc-tags | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_tag.cluster_security_group](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/ec2_tag) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role) | resource |
| [aws_iam_role.ng](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ng_AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ng_AmazonEKSVPCResourceControllerPolicy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ng_AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cluster_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ng_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.ebs_default](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/data-sources/partition) | data source |
| [aws_subnet.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/data-sources/subnet) | data source |
| [aws_subnet.public_subnets](https://registry.terraform.io/providers/hashicorp/aws/5.75.0/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_vpc_tags"></a> [add\_vpc\_tags](#input\_add\_vpc\_tags) | Adds tags to VPC resources necessary for ingress resources within EKS to perform auto-discovery of subnets. Defaults to "true". Note that this may cause resource cycling (delete and recreate) if you are using Terraform to manage your VPC resources without having a `lifecycle { ignore_changes = [ tags ] }` block defined within them, since the VPC resources will want to manage the tags themselves and remove the ones added by this module. | `bool` | `true` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to be added to the resources created by this module. | `map(any)` | `{}` | no |
| <a name="input_allowed_public_cidrs"></a> [allowed\_public\_cidrs](#input\_allowed\_public\_cidrs) | List of CIDR blocks that are allowed to access the EKS cluster's public endpoint. Defaults to "0.0.0.0/0" (any). | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_bootstrap_self_managed_addons"></a> [bootstrap\_self\_managed\_addons](#input\_bootstrap\_self\_managed\_addons) | Indicates whether or not to bootstrap self-managed addons after the cluster has been created | `bool` | `null` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_cluster_encryption_config"></a> [cluster\_encryption\_config](#input\_cluster\_encryption\_config) | Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to `{}` | `any` | `{}` | no |
| <a name="input_cluster_iam"></a> [cluster\_iam](#input\_cluster\_iam) | Cluster IAM settings | `any` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources. Must be 16 characters or less. | `string` | `""` | no |
| <a name="input_cluster_networking"></a> [cluster\_networking](#input\_cluster\_networking) | Cluster Networking settings | `any` | `null` | no |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | Additional rules to add to the cluster security group. Set source\_node\_security\_group = true inside rules to set the node\_security\_group as source. | `any` | `{}` | no |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | The ID of an existing security group to use for the EKS cluster. If not provided, a new security group will be created. | `string` | `""` | no |
| <a name="input_cluster_service_ipv4_cidr"></a> [cluster\_service\_ipv4\_cidr](#input\_cluster\_service\_ipv4\_cidr) | The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks | `string` | `null` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The version of Kubernetes to be installed. | `string` | `"1.20"` | no |
| <a name="input_create_cluster_security_group"></a> [create\_cluster\_security\_group](#input\_create\_cluster\_security\_group) | Whether to create a new security group for the EKS cluster. If set to false, you must provide an existing security group via the cluster\_security\_group\_id variable. | `bool` | `true` | no |
| <a name="input_create_iam_policies"></a> [create\_iam\_policies](#input\_create\_iam\_policies) | deprecated | `bool` | `false` | no |
| <a name="input_create_node_security_group"></a> [create\_node\_security\_group](#input\_create\_node\_security\_group) | Whether to create a new security group for the EKS nodes. If set to false, you must provide an existing security group via the node\_security\_group\_id variable. | `bool` | `true` | no |
| <a name="input_disable_public_eks_endpoint"></a> [disable\_public\_eks\_endpoint](#input\_disable\_public\_eks\_endpoint) | Whether to disable public access to the EKS control plane endpoint. If set to "true", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to "false" unless you are familiar with this type of configuration. | `bool` | `false` | no |
| <a name="input_disk_encryption_kms_key_arn"></a> [disk\_encryption\_kms\_key\_arn](#input\_disk\_encryption\_kms\_key\_arn) | The KMS Key ARN to use for EBS disk encryption. If not set, the default EBS encryption key will be used. | `string` | `""` | no |
| <a name="input_enable_bootstrap"></a> [enable\_bootstrap](#input\_enable\_bootstrap) | deprecated | `bool` | `false` | no |
| <a name="input_enable_cilium"></a> [enable\_cilium](#input\_enable\_cilium) | deprecated | `bool` | `false` | no |
| <a name="input_enable_istio"></a> [enable\_istio](#input\_enable\_istio) | deprecated | `bool` | `false` | no |
| <a name="input_enable_node_pool_monitoring"></a> [enable\_node\_pool\_monitoring](#input\_enable\_node\_pool\_monitoring) | Enable CloudWatch monitoring for the default pool(s). | `bool` | `false` | no |
| <a name="input_enable_nodes_use_public_subnet"></a> [enable\_nodes\_use\_public\_subnet](#input\_enable\_nodes\_use\_public\_subnet) | When set to true, the node groups will use public subnet rather private subnet, and the public subnet must enable auto-assing public ip so that nodes can have public ip to access internet. Default is false. | `bool` | `false` | no |
| <a name="input_enable_resource_creation"></a> [enable\_resource\_creation](#input\_enable\_resource\_creation) | deprecated | `bool` | `true` | no |
| <a name="input_enable_sncloud_control_plane_access"></a> [enable\_sncloud\_control\_plane\_access](#input\_enable\_sncloud\_control\_plane\_access) | Whether to enable access to the EKS control plane endpoint. If set to "false", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to "true" unless you are familiar with this type of configuration. | `bool` | `true` | no |
| <a name="input_enable_v3_node_groups"></a> [enable\_v3\_node\_groups](#input\_enable\_v3\_node\_groups) | Enable v3 node groups, which uses a single ASG and all other node groups enabled elsewhere | `bool` | `false` | no |
| <a name="input_enable_v3_node_migration"></a> [enable\_v3\_node\_migration](#input\_enable\_v3\_node\_migration) | Enable v3 node and v2 node groups at the same time. Intended for use with migration to v3 nodes. | `bool` | `false` | no |
| <a name="input_enable_v3_node_taints"></a> [enable\_v3\_node\_taints](#input\_enable\_v3\_node\_taints) | When v3 node groups are enabled, use the node taints. Defaults to true | `bool` | `true` | no |
| <a name="input_enable_vpc_cni_prefix_delegation"></a> [enable\_vpc\_cni\_prefix\_delegation](#input\_enable\_vpc\_cni\_prefix\_delegation) | Whether set ENABLE\_PREFIX\_DELEGATION for vpc-cni addon | `bool` | `true` | no |
| <a name="input_iam_path"></a> [iam\_path](#input\_iam\_path) | An IAM Path to be used for all IAM resources created by this module. Changing this from the default will cause issues with StreamNative's Vendor access, if applicable. | `string` | `"/StreamNative/"` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Whether to manage the aws\_auth configmap | `bool` | `true` | no |
| <a name="input_map_additional_iam_roles"></a> [map\_additional\_iam\_roles](#input\_map\_additional\_iam\_roles) | A list of IAM role bindings to add to the aws-auth ConfigMap. | <pre>list(object({<br/>    rolearn  = string<br/>    username = string<br/>    groups   = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Map of EKS managed node group definitions to create | `any` | `null` | no |
| <a name="input_node_pool_ami_id"></a> [node\_pool\_ami\_id](#input\_node\_pool\_ami\_id) | The AMI ID to use for the EKS cluster nodes. Defaults to the latest EKS Optimized AMI provided by AWS. | `string` | `""` | no |
| <a name="input_node_pool_azs"></a> [node\_pool\_azs](#input\_node\_pool\_azs) | A list of availability zones to use for the EKS node group. If not set, the module will use the same availability zones with the cluster. | `list(string)` | `[]` | no |
| <a name="input_node_pool_capacity_type"></a> [node\_pool\_capacity\_type](#input\_node\_pool\_capacity\_type) | The capacity type for the node group. Defaults to "ON\_DEMAND". If set to "SPOT", the node group will be a spot instance node group. | `string` | `"ON_DEMAND"` | no |
| <a name="input_node_pool_desired_size"></a> [node\_pool\_desired\_size](#input\_node\_pool\_desired\_size) | Desired number of worker nodes in the node pool. | `number` | `0` | no |
| <a name="input_node_pool_disk_iops"></a> [node\_pool\_disk\_iops](#input\_node\_pool\_disk\_iops) | The amount of provisioned IOPS for the worker node root EBS volume. | `number` | `3000` | no |
| <a name="input_node_pool_disk_size"></a> [node\_pool\_disk\_size](#input\_node\_pool\_disk\_size) | Disk size in GiB for worker nodes in the node pool. Defaults to 50. | `number` | `100` | no |
| <a name="input_node_pool_disk_type"></a> [node\_pool\_disk\_type](#input\_node\_pool\_disk\_type) | Disk type for worker nodes in the node pool. Defaults to gp3. | `string` | `"gp3"` | no |
| <a name="input_node_pool_ebs_optimized"></a> [node\_pool\_ebs\_optimized](#input\_node\_pool\_ebs\_optimized) | If true, the launched EC2 instance(s) will be EBS-optimized. Specify this if using a custom AMI with pre-user data. | `bool` | `true` | no |
| <a name="input_node_pool_instance_types"></a> [node\_pool\_instance\_types](#input\_node\_pool\_instance\_types) | Set of instance types associated with the EKS Node Groups. Defaults to ["m6i.large", "m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge", "m6i.8xlarge"], which will create empty node groups of each instance type to account for any workload configurable from StreamNative Cloud. | `list(string)` | <pre>[<br/>  "m6i.large",<br/>  "m6i.xlarge",<br/>  "m6i.2xlarge",<br/>  "m6i.4xlarge",<br/>  "m6i.8xlarge"<br/>]</pre> | no |
| <a name="input_node_pool_labels"></a> [node\_pool\_labels](#input\_node\_pool\_labels) | A map of kubernetes labels to add to the node pool. | `map(string)` | `{}` | no |
| <a name="input_node_pool_max_size"></a> [node\_pool\_max\_size](#input\_node\_pool\_max\_size) | The maximum size of the node pool Autoscaling group. | `number` | n/a | yes |
| <a name="input_node_pool_min_size"></a> [node\_pool\_min\_size](#input\_node\_pool\_min\_size) | The minimum size of the node pool AutoScaling group. | `number` | `0` | no |
| <a name="input_node_pool_pre_userdata"></a> [node\_pool\_pre\_userdata](#input\_node\_pool\_pre\_userdata) | The user data to apply to the worker nodes in the node pool. This is applied before the bootstrap.sh script. | `string` | `""` | no |
| <a name="input_node_pool_tags"></a> [node\_pool\_tags](#input\_node\_pool\_tags) | A map of tags to add to the node groups and supporting resources. | `map(string)` | `{}` | no |
| <a name="input_node_pool_taints"></a> [node\_pool\_taints](#input\_node\_pool\_taints) | A list of taints in map format to apply to the node pool. | `any` | `{}` | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | Additional ingress rules to add to the node security group. Set source\_cluster\_security\_group = true inside rules to set the cluster\_security\_group as source | `any` | `{}` | no |
| <a name="input_node_security_group_id"></a> [node\_security\_group\_id](#input\_node\_security\_group\_id) | An ID of an existing security group to use for the EKS node groups. If not specified, a new security group will be created. | `string` | `""` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access. | `string` | `null` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The ids of existing private subnets. | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | The ids of existing public subnets. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region. | `string` | `null` | no |
| <a name="input_use_runtime_policy"></a> [use\_runtime\_policy](#input\_use\_runtime\_policy) | Legacy variable, will be deprecated in future versions. The preference of this module is to have the parent EKS module create and manage the IAM role. However some older configurations may have had the cluster IAM role managed seperately, and this variable allows for backwards compatibility. | `bool` | `false` | no |
| <a name="input_v3_node_group_core_instance_type"></a> [v3\_node\_group\_core\_instance\_type](#input\_v3\_node\_group\_core\_instance\_type) | The instance to use for the core node group | `string` | `"m6i.large"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC to use. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks"></a> [eks](#output\_eks) | All outputs of module.eks for provide convenient approach to access child module's outputs. |
| <a name="output_eks_cluster_arn"></a> [eks\_cluster\_arn](#output\_eks\_cluster\_arn) | The ARN for the EKS cluster created by this module |
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | The endpoint for the EKS cluster created by this module |
| <a name="output_eks_cluster_identity_oidc_issuer_arn"></a> [eks\_cluster\_identity\_oidc\_issuer\_arn](#output\_eks\_cluster\_identity\_oidc\_issuer\_arn) | The ARN for the OIDC issuer created by this module |
| <a name="output_eks_cluster_identity_oidc_issuer_string"></a> [eks\_cluster\_identity\_oidc\_issuer\_string](#output\_eks\_cluster\_identity\_oidc\_issuer\_string) | A formatted string containing the prefix for the OIDC issuer created by this module. Same as "cluster\_oidc\_issuer\_url", but with "https://" stripped from the name. This output is typically used in other StreamNative modules that request the "oidc\_issuer" input. |
| <a name="output_eks_cluster_identity_oidc_issuer_url"></a> [eks\_cluster\_identity\_oidc\_issuer\_url](#output\_eks\_cluster\_identity\_oidc\_issuer\_url) | The URL for the OIDC issuer created by this module |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | The name of the EKS cluster created by this module |
| <a name="output_eks_cluster_platform_version"></a> [eks\_cluster\_platform\_version](#output\_eks\_cluster\_platform\_version) | The platform version for the EKS cluster created by this module |
| <a name="output_eks_cluster_primary_security_group_id"></a> [eks\_cluster\_primary\_security\_group\_id](#output\_eks\_cluster\_primary\_security\_group\_id) | The id of the primary security group created by the EKS service itself, not by this module. This is labeled "Cluster Security Group" in the EKS console. |
| <a name="output_eks_cluster_secondary_security_group_id"></a> [eks\_cluster\_secondary\_security\_group\_id](#output\_eks\_cluster\_secondary\_security\_group\_id) | The id of the secondary security group created by this module. This is labled "Additional Security Groups" in the EKS console. |
| <a name="output_eks_node_group_iam_role_arn"></a> [eks\_node\_group\_iam\_role\_arn](#output\_eks\_node\_group\_iam\_role\_arn) | The IAM Role ARN used by the Worker configuration |
| <a name="output_eks_node_group_security_group_id"></a> [eks\_node\_group\_security\_group\_id](#output\_eks\_node\_group\_security\_group\_id) | Security group ID attached to the EKS node groups |
| <a name="output_eks_node_groups"></a> [eks\_node\_groups](#output\_eks\_node\_groups) | Map of all attributes of the EKS node groups created by this module |
| <a name="output_inuse_azs"></a> [inuse\_azs](#output\_inuse\_azs) | The availability zones in which the EKS nodes is deployed |
<!-- END_TF_DOCS -->
