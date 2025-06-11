data "aws_iam_policy_document" "csi_sts" {
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
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "ebs-csi-controller-sa")]
      variable = format("%s:sub", local.oidc_issuer)
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = format("%s:aud", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "csi" {
  name                 = format("%s-csi-role", var.cluster_name)
  description          = format("Role used by IRSA and the KSA ebs-csi-controller-sa on StreamNative Cloud EKS cluster %s", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.csi_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = local.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "csi" {
  role       = aws_iam_role.csi.name
  policy_arn = local.default_service_policy_arn
}

resource "aws_iam_role_policy_attachment" "csi_managed" {
  role       = aws_iam_role.csi.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
