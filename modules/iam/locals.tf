data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  aws_partition = data.aws_partition.current.partition
  dns_suffix    = data.aws_partition.current.dns_suffix
  oidc_issuer   = var.oidc_issuer

  permissions_boundary_arn   = var.permissions_boundary_arn_override != "" ? var.permissions_boundary_arn_override : "arn:${local.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudPermissionBoundary"
  default_service_policy_arn = var.runtime_policy_arn_override != "" ? var.runtime_policy_arn_override : "arn:${local.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudRuntimePolicy"
  default_lb_policy_arn      = var.load_balancer_policy_arn_override != "" ? var.load_balancer_policy_arn_override : "arn:${local.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudLBPolicy"

  tags = merge({
    "Vendor"       = "StreamNative"
    "cluster-name" = var.cluster_name
  }, var.extra_aws_tags)
}
