# Copyright 2023 StreamNative, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "region" {
  default     = null
  description = "The AWS region."
  type        = string
}


// basic cluster info
variable "cluster_name" {
  default     = ""
  description = "The name of your EKS cluster and associated resources. Must be 16 characters or less."
  type        = string

  validation {
    condition     = can(length(var.cluster_name) <= 16)
    error_message = "The value for variable \"cluster_name\" must be a string of 16 characters or less."
  }
}

variable "cluster_version" {
  default     = "1.20"
  description = "The version of Kubernetes to be installed."
  type        = string
}

variable "additional_tags" {
  default     = {}
  description = "Additional tags to be added to the resources created by this module."
  type        = map(any)
}


// network
variable "cluster_networking" {
  description = "Cluster Networking settings"
  type        = any
  default     = null
}
/** Example
cluster_networking = {
    cluster_service_ipv4_cidr = null

    cluster_security_group_id                  = ""
    cluster_additional_security_group_ids      = []
    create_cluster_security_group              = true 
    cluster_security_group_name                = null
    cluster_security_group_additional_rules    = {}
    cluster_security_group_description         = ""
    create_cluster_primary_security_group_tags = false
}
**/
variable "vpc_id" {
  default     = ""
  description = "The ID of the AWS VPC to use."
  type        = string
  validation {
    condition     = length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-"
    error_message = "The value for variable \"vpc_id\" must be a valid VPC id, starting with \"vpc-\"."
  }
}

variable "private_subnet_ids" {
  default     = []
  description = "The ids of existing private subnets."
  type        = list(string)
}

variable "public_subnet_ids" {
  default     = []
  description = "The ids of existing public subnets."
  type        = list(string)
}

variable "enable_nodes_use_public_subnet" {
  default     = false
  type        = bool
  description = "When set to true, the node groups will use public subnet rather private subnet, and the public subnet must enable auto-assing public ip so that nodes can have public ip to access internet. Default is false."
}

variable "add_vpc_tags" {
  default     = true
  description = "Adds tags to VPC resources necessary for ingress resources within EKS to perform auto-discovery of subnets. Defaults to \"true\". Note that this may cause resource cycling (delete and recreate) if you are using Terraform to manage your VPC resources without having a `lifecycle { ignore_changes = [ tags ] }` block defined within them, since the VPC resources will want to manage the tags themselves and remove the ones added by this module."
  type        = bool
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  type        = string
  default     = null
}

variable "enable_vpc_cni_prefix_delegation" {
  type        = bool
  default     = true
  description = "Whether set ENABLE_PREFIX_DELEGATION for vpc-cni addon"
}


// eks endpoint
variable "disable_public_eks_endpoint" {
  default     = false
  description = "Whether to disable public access to the EKS control plane endpoint. If set to \"true\", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to \"false\" unless you are familiar with this type of configuration."
  type        = bool
}


variable "allowed_public_cidrs" {
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks that are allowed to access the EKS cluster's public endpoint. Defaults to \"0.0.0.0/0\" (any)."
  type        = list(string)
}


// observability
variable "cluster_enabled_log_types" {
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)."
  type        = list(string)
}

variable "enable_node_pool_monitoring" {
  default     = false
  description = "Enable CloudWatch monitoring for the default pool(s)."
  type        = bool
}


// security groups
variable "cluster_security_group_additional_rules" {
  default     = {}
  description = "Additional rules to add to the cluster security group. Set source_node_security_group = true inside rules to set the node_security_group as source."
  type        = any
}

variable "cluster_security_group_id" {
  default     = ""
  description = "The ID of an existing security group to use for the EKS cluster. If not provided, a new security group will be created."
  type        = string
}

variable "create_cluster_security_group" {
  default     = true
  description = "Whether to create a new security group for the EKS cluster. If set to false, you must provide an existing security group via the cluster_security_group_id variable."
  type        = bool
}

variable "create_node_security_group" {
  default     = true
  description = "Whether to create a new security group for the EKS nodes. If set to false, you must provide an existing security group via the node_security_group_id variable."
  type        = bool
}

variable "node_security_group_id" {
  default     = ""
  description = "An ID of an existing security group to use for the EKS node groups. If not specified, a new security group will be created."
  type        = string
}

variable "node_security_group_additional_rules" {
  default     = {}
  description = "Additional ingress rules to add to the node security group. Set source_cluster_security_group = true inside rules to set the cluster_security_group as source"
  type        = any
}


// encryption
variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to `{}`"
  type        = any
  default     = {}
}

variable "disk_encryption_kms_key_arn" {
  default     = ""
  description = "The KMS Key ARN to use for EBS disk encryption. If not set, the default EBS encryption key will be used."
  type        = string
}


// IAM
variable "cluster_iam" {
  description = "Cluster IAM settings"
  type        = any
  default     = null
}
/** Example
cluster_iam = {
  create_iam_role = true
  iam_role_use_name_prefix = false
  iam_role_name = ""
  iam_role_arn = ""
}
**/

variable "iam_path" {
  default     = "/StreamNative/"
  description = "An IAM Path to be used for all IAM resources created by this module. Changing this from the default will cause issues with StreamNative's Vendor access, if applicable."
  type        = string
}

variable "manage_aws_auth_configmap" {
  default     = true
  description = "Whether to manage the aws_auth configmap"
  type        = bool
}

variable "map_additional_iam_roles" {
  default     = []
  description = "A list of IAM role bindings to add to the aws-auth ConfigMap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "enable_sncloud_control_plane_access" {
  default     = true
  description = "Whether to enable access to the EKS control plane endpoint. If set to \"false\", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to \"true\" unless you are familiar with this type of configuration."
  type        = bool
}

variable "permissions_boundary_arn" {
  default     = null
  description = "If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access."
  type        = string
}

variable "use_runtime_policy" {
  default     = false
  description = "Legacy variable, will be deprecated in future versions. The preference of this module is to have the parent EKS module create and manage the IAM role. However some older configurations may have had the cluster IAM role managed seperately, and this variable allows for backwards compatibility."
  type        = bool
}


// node groups
variable "enable_v3_node_groups" {
  default     = false
  description = "Enable v3 node groups, which uses a single ASG and all other node groups enabled elsewhere"
  type        = bool
}

variable "enable_v3_node_migration" {
  default     = false
  description = "Enable v3 node and v2 node groups at the same time. Intended for use with migration to v3 nodes."
  type        = bool
}

variable "enable_v3_node_taints" {
  default     = true
  description = "When v3 node groups are enabled, use the node taints. Defaults to true"
  type        = bool
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = null
}
/** Example
node_groups = {
    snc_core = {
      name            = "snc-core"
      use_name_prefix = true

      create_iam_role               = false 
      iam_role_arn                  = null
      iam_role_name                 = null
      iam_role_use_name_prefix      = true
      iam_role_path                 = null
      iam_role_description          = ""
      iam_role_permissions_boundary = null
      iam_role_tags                 = {}
      iam_role_attach_cni_policy    = true
      iam_role_additional_policies  = {}
      create_iam_role_policy        = true
      iam_role_policy_statements    = []

      create_launch_template = true
      use_custom_launch_template = true
      launch_template_id = ""
      launch_template_name = "snc-core"
      launch_template_use_name_prefix = true
      launch_template_version = null
      launch_template_default_version = null
      update_launch_template_default_version = true
      launch_template_description = ""
      vpc_security_group_ids = []

      instance_types = ["m6i.large"]
      min_size = 2
      max_size = 5
      desired_size = 2
    }
}
**/

variable "v3_node_group_core_instance_type" {
  default     = "m6i.large"
  description = "The instance to use for the core node group"
  type        = string
}

variable "node_pool_ami_id" {
  default     = ""
  description = "The AMI ID to use for the EKS cluster nodes. Defaults to the latest EKS Optimized AMI provided by AWS."
  type        = string
}

variable "node_pool_disk_iops" {
  default     = 3000
  description = "The amount of provisioned IOPS for the worker node root EBS volume."
  type        = number
}

variable "node_pool_ebs_optimized" {
  default     = true
  description = "If true, the launched EC2 instance(s) will be EBS-optimized. Specify this if using a custom AMI with pre-user data."
  type        = bool
}

variable "node_pool_block_device_name" {
  default     = "/dev/nvme0n1"
  description = "The name of the block device to use for the EKS cluster nodes."
  type        = string
}

variable "node_pool_capacity_type" {
  description = "The capacity type for the node group. Defaults to \"ON_DEMAND\". If set to \"SPOT\", the node group will be a spot instance node group."
  type        = string
  default     = "ON_DEMAND"
  
}

variable "node_pool_desired_size" {
  default     = 0
  description = "Desired number of worker nodes in the node pool."
  type        = number
}

variable "node_pool_disk_size" {
  default     = 100
  description = "Disk size in GiB for worker nodes in the node pool. Defaults to 50."
  type        = number
}

variable "node_pool_disk_type" {
  default     = "gp3"
  description = "Disk type for worker nodes in the node pool. Defaults to gp3."
  type        = string
}

variable "node_pool_instance_types" {
  default     = ["m6i.large", "m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge", "m6i.8xlarge"]
  description = "Set of instance types associated with the EKS Node Groups. Defaults to [\"m6i.large\", \"m6i.xlarge\", \"m6i.2xlarge\", \"m6i.4xlarge\", \"m6i.8xlarge\"], which will create empty node groups of each instance type to account for any workload configurable from StreamNative Cloud."
  type        = list(string)
}

variable "node_pool_azs" {
  type        = list(string)
  description = "A list of availability zones to use for the EKS node group. If not set, the module will use the same availability zones with the cluster."
  default     = []
}

variable "node_pool_labels" {
  default     = {}
  description = "A map of kubernetes labels to add to the node pool."
  type        = map(string)
}

variable "node_pool_min_size" {
  default     = 0
  description = "The minimum size of the node pool AutoScaling group."
  type        = number
}

variable "node_pool_max_size" {
  description = "The maximum size of the node pool Autoscaling group."
  type        = number
}

variable "node_pool_pre_userdata" {
  default     = ""
  description = "The user data to apply to the worker nodes in the node pool. This is applied before the bootstrap.sh script."
  type        = string
}

variable "node_pool_taints" {
  default     = {}
  description = "A list of taints in map format to apply to the node pool."
  type        = any
}

variable "node_pool_tags" {
  default     = {}
  description = "A map of tags to add to the node groups and supporting resources."
  type        = map(string)
}


// addons
variable "bootstrap_self_managed_addons" {
  description = "Indicates whether or not to bootstrap self-managed addons after the cluster has been created"
  type        = bool
  default     = null
}


// deprecated
variable "enable_bootstrap" {
  default = false
  type    = bool
}


// deprecated
variable "enable_istio" {
  default = false
  type    = bool
}

// deprecated
variable "enable_cilium" {
  default = false
  type    = bool
}

// deprecated
variable "enable_resource_creation" {
  default = true
  type    = bool
}

// deprecated
variable "create_iam_policies" {
  default     = false
  type        = bool
}