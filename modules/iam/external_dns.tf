data "aws_iam_policy_document" "external_dns_sts" {
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
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "external-dns")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name                 = format("%s-extdns-role", var.cluster_name)
  description          = format("Role used by IRSA and the KSA external-dns on StreamNative Cloud EKS cluster %s", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.external_dns_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = local.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = local.default_service_policy_arn
}
