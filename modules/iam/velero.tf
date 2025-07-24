data "aws_iam_policy_document" "velero_sts" {
  count = var.enable_velero ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", local.aws_partition, local.account_id, local.oidc_issuer)]
    }
    condition {
      test     = "StringLike"
      values   = [format("system:serviceaccount:%s:%s", "velero", "velero")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "velero" {
  count = var.enable_velero ? 1 : 0

  name                 = format("%s-velero-backup-role", var.cluster_name)
  description          = format("Role used by IRSA and the KSA velero on StreamNative Cloud EKS cluster %s", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.velero_sts.0.json
  tags                 = local.tags
  path                 = "/StreamNative/"
  permissions_boundary = local.permissions_boundary_arn
}

resource "aws_iam_role_policy_attachment" "velero" {
  count = var.enable_velero ? 1 : 0

  role       = aws_iam_role.velero.0.name
  policy_arn = local.default_service_policy_arn
}
