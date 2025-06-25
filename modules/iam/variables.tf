variable "region" {
  description = "AWS Region"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "oidc_issuer" {
  description = "The oidc issuer for the cluster"
  type        = string
}

variable "permissions_boundary_arn_override" {
  default     = ""
  description = "Override the permission boundary arn, otherwise will construct an arn"
  type        = string
}

variable "runtime_policy_arn_override" {
  default     = ""
  description = "Override the runtime policy arn, otherwise will construct an arn"
  type        = string
}

variable "load_balancer_policy_arn_override" {
  default     = ""
  description = "Override the runtime policy arn, otherwise will construct an arn"
  type        = string
}

variable "enable_karpenter" {
  type        = bool
  default     = false
  description = "Enable karpenter for autoscaling. If set to false, no karpenter resources will be created."
}

variable "cluster_node_group_iam_role_arn" {
  type = string
}

variable "enable_velero" {
  type        = bool
  default     = true
  description = "Enable velero for backups. If set to false, no velero resources will be created."
}

variable "extra_aws_tags" {
  default     = {}
  description = "extra aws tags to add to any resources"
  type        = map(string)
}