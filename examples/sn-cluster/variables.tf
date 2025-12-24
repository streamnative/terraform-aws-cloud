variable "pm_name" {
  description = "The name of the poolmember, for new clusters, this should be like `pm-<xxxxx>`"
  type        = string
}

variable "private_subnet_ids" {
  description = "The private subnet IDs to use for the cluster. If not provided, the module will create them."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "The public subnet IDs to use for the cluster. If not provided, the module will create them."
  type        = list(string)
}

variable "enable_public_ip_nodes" {
  type        = bool
  default     = false
  description = "If set to true, will not create NAT Gateway and EC2 Nodes should put in public subnets. This could be useful when wanna save costs from nat gateway."
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID to use for the cluster. If not provided, the module will create one."
  type        = string
}

variable "namespace" {
  description = "the namespace the pool-member is in"
  type        = string
  default     = ""
}

variable "protect_k8s_public_endpoint" {
  description = "Determines whether to protect the public endpoint with a whitelist"
  type        = bool
  default     = false
}

variable "control_plane_egress_cidrs" {
  description = "The CIDR blocks of StreamNative Cloud control plane egress traffic, mainly used by ArgoCD, ArgoWorkflows and Crossplane Provider."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "k8s_public_endpoint_allowed_cidrs" {
  description = "The CIDR blocks that are allowed to access the public Kubernetes API server."
  type        = list(string)
  default     = []
}

# used to create debug info for the cluster

variable "customer_role" {
  description = "The customer role to use for the cluster"
  type        = string
}

variable "sn_role" {
  description = "The SN role to use for the cluster"
  type        = string
}

# commonly chagned - these are the "tuneables" for the cluster. In most cases, the defaults are fine

variable "node_pool_instance_type" {
  description = "The instance to use for the node group"
  type        = string
  default     = "m6i.xlarge"
}

variable "node_pool_max_size" {
  description = "The maximum size of the node pool Autoscaling group."
  type        = number
  default     = 12
}

variable "node_pool_azs" {
  type        = list(string)
  description = "A list of availability zones to use for the EKS node group. If not set, the module will use the same availability zones with the cluster."
  default     = []
}

# customer overrides - used to customize certain aspects for certain customers
variable "additional_tags" {
  description = "Additional tags to add to the cluster"
  type        = map(string)
  default     = {}
}

variable "override_cluster_name" {
  description = "Override the cluster name. This should typically only be done for improts"
  type        = string
  default     = ""
}

variable "cluster_role_mapping" {
  default     = []
  description = "A list of maps containing the IAM role ARNs to map to the Kubernetes RBAC groups"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "cluster_enabled_log_types" {
  default     = []
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)."
  type        = list(string)
}

variable "override_permission_boundary_arn" {
  default     = ""
  type        = string
  description = "Boundary Role ARN to use (or empty to use the manager's identity)"
}

variable "enable_topology_aware_gateway" {
  description = "Whether to use topology aware gateway"
  type        = bool
  default     = false
}

# defaults - these should be changed as we move to new versions

variable "cluster_version" {
  description = "The Kubernetes version to use for the cluster"
  type        = string
  default     = "1.29"
}

variable "enable_v3_node_groups" {
  description = "Enable the use of v3 node groups"
  type        = bool
  default     = true
}

variable "cluster_iam" {
  description = "Cluster IAM settings"
  type        = any
  default     = null
}

variable "cluster_networking" {
  description = "Cluster Networking settings"
  type        = any
  default     = null
}

variable "bootstrap_self_managed_addons" {
  description = "Indicates whether or not to bootstrap self-managed addons after the cluster has been created"
  type        = bool
  default     = null
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = null
}

variable "enable_karpenter" {
  type        = bool
  default     = false
  description = "Enable karpenter will disable cluster autoscaler"
}

variable "enable_vpc_cni_prefix_delegation" {
  type        = bool
  default     = true
  description = "Whether set ENABLE_PREFIX_DELEGATION for vpc-cni addon"
}