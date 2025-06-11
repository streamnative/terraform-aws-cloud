data "aws_iam_policy_document" "cluster_autoscaler_sts" {
  count = var.enable_karpenter ? 1 : 0

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
      test     = "StringEquals"
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "cluster-autoscaler")]
      variable = format("%s:sub", local.oidc_issuer)
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = format("%s:aud", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_karpenter ? 1 : 0

  name                 = format("%s-ca-role", var.cluster_name)
  description          = format("Role used by IRSA and the KSA cluster-autoscaler on StreamNative Cloud EKS cluster %s", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.cluster_autoscaler_sts.0.json
  path                 = "/StreamNative/"
  permissions_boundary = local.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_karpenter ? 1 : 0

  policy_arn = local.default_service_policy_arn
  role       = aws_iam_role.cluster_autoscaler.0.name
}
