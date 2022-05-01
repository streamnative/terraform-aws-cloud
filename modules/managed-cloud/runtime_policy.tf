data "aws_ebs_default_kms_key" "current" {}
data "aws_kms_key" "default_ebs" {
  key_id = data.aws_ebs_default_kms_key.current.key_arn
}

locals {
  kms_key_arns = length(var.runtime_ebs_kms_key_arns) > 0 ? var.runtime_ebs_kms_key_arns : [data.aws_kms_key.default_ebs.arn]
}

data "aws_iam_policy_document" "runtime_policy" {
  statement {
    sid    = "ro"
    effect = "Allow"
    actions = [
      "autoscaling:Describe*",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "route53:GetChange",
      "route53:ListHostedZones*",
      "route53:ListTagsForResource",
      "route53:ListResourceRecordSets",
      "route53:ListHostedZones",
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "r53sc"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = var.runtime_hosted_zone_allowed_ids
  }

  statement {
    sid    = "asg"
    effect = "Allow"
    actions = [
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:SetDesiredCapacity"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = ["sn-*"]
      variable = "autoscaling:ResourceTag/cluster-name"
    }
  }
  statement {
    sid    = "csik1"
    effect = "Allow"
    actions = [
      "kms:RevokeGrant",
      "kms:ListGrants",
      "kms:CreateGrant"
    ]
    resources = local.kms_key_arns
    condition {
      test     = "Bool"
      values   = ["true"]
      variable = "kms:GrantIsForAWSResource"
    }
  }
  statement {
    sid    = "csik2"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    resources = local.kms_key_arns
  }
  statement {
    sid    = "s3b"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListMultipart*",
    ]
    resources = ["arn:aws:s3:::sn-*"]
  }
  statement {
    sid    = "s3o"
    effect = "Allow"
    actions = [
      "s3:*Object",
      "s3:*Multipart*"
    ]
    resources = local.kms_key_arns
  }
  statement {
    sid    = "vbc"
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:CreateSnapshot"
    ]
    condition {
      test     = "StringLike"
      values   = ["owned"]
      variable = "aws:RequestTag/kubernetes.io/cluster/sn-*"
    }
    resources = ["*"]
  }
  statement {
    sid    = "vbt"
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    condition {
      test     = "StringEquals"
      values   = ["CreateVolume", "CreateSnapshot"]
      variable = "ec2:CreateAction"
    }
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
    ]
  }
  statement {
    sid    = "vbd"
    effect = "Allow"
    actions = [
      "ec2:DeleteSnapshot"
    ]
    condition {
      test     = "StringLike"
      values   = ["owned"]
      variable = "aws:ResourceTag/kubernetes.io/cluster/sn-*"
    }
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = var.runtime_enable_secretsmanager ? [1] : []

    content {
      sid    = "sm"
      effect = "Allow"
      actions = [
        "secretsmanager:ListSecretVersionIds",
        "secretsmanager:GetSecretValue",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:DescribeSecret"
      ]
      condition {
        test     = "StringEquals"
        values   = ["StreamNative"]
        variable = "aws:ResourceTag/Vendor"
      }
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "runtime_policy" {
  count       = var.use_runtime_policy ? 1 : 0
  name        = "StreamNativeCloudRuntimePolicy"
  description = "This policy defines almost all used by StreamNative cluster components"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.runtime_policy.json
  tags        = local.tag_set
}

resource "aws_iam_policy" "alb_policy" {
  count       = var.use_runtime_policy ? 1 : 0
  name        = "StreamNativeCloudLBPolicy"
  description = "The AWS policy as defined by https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json"
  path        = "/StreamNative/"
  policy = templatefile("${path.module}/files/aws_lb_controller.json.tpl",
    {
      vpc_ids = local.arn_like_vpcs_str
  })
  tags = local.tag_set
}

resource "local_file" "runtime_policy" {
  count    = var.write_policy_files ? 1 : 0
  content  = data.aws_iam_policy_document.runtime_policy.json
  filename = "runtime_policy.json"
}

resource "local_file" "alb_policy" {
  count    = var.write_policy_files ? 1 : 0
  content  = templatefile("${path.module}/files/aws_lb_controller.json.tpl",
    {
      vpc_ids = local.arn_like_vpcs_str
  })
  filename = "alb_policy.json"
}
