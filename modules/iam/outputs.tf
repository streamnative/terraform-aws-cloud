output "aws_load_balancer_controller_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

output "cert_manager_arn" {
  value = aws_iam_role.cert_manager.arn
}

output "cluster_autoscaler_arn" {
  value = try(aws_iam_role.cluster_autoscaler[0].arn, null)
}

output "csi_arn" {
  value = aws_iam_role.csi.arn
}

output "external_dns_arn" {
  value = aws_iam_role.external_dns.arn
}

output "karpenter_arn" {
  value = try(aws_iam_role.karpenter[0].arn, null)
}

output "velero_arn" {
  value = try(aws_iam_role.velero[0].arn, null)
}