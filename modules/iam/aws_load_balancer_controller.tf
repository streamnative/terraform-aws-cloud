data "aws_iam_policy_document" "aws_load_balancer_controller_sts" {
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
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "aws-load-balancer-controller")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name                 = format("%s-lbc-role", var.cluster_name)
  description          = format("Role used by IRSA and the KSA aws-load-balancer-controller on StreamNative Cloud EKS cluster %s", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.aws_load_balancer_controller_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = local.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = local.default_lb_policy_arn
}
