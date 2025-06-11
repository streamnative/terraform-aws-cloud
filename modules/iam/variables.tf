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

variable "s3_encryption_kms_key_arn" {
  default     = ""
  description = "KMS key ARN to use for S3 encryption. If not set, the default AWS S3 key will be used."
  type        = string
}

variable "backup_bucket" {
  description = "The name of the s3 bucket to use for backups"
  type        = string
}

variable "velero_backup_schedule" {
  default     = "0 5 * * *"
  description = "The scheduled time for Velero to perform backups. Written in cron expression, defaults to \"0 5 * * *\" or \"at 5:00am every day\""
  type        = string
}


variable "extra_aws_tags" {
  default     = {}
  description = "extra aws tags to add to any resources"
  type        = map(string)
}