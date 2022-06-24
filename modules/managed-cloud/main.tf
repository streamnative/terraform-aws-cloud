#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "streamnative_vendor_access" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.streamnative_vendor_access_role_arns
    }
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  external_id = (var.external_id != "" ? [
    { test : "StringEquals", variable : "sts:ExternalId", values : [var.external_id] }
  ] : [])
  source_identity = (length(var.source_identities) > 0 ? [
    { test : var.source_identity_test, variable : "sts:SourceIdentity", values : var.source_identities }
  ] : [])
  assume_conditions         = concat(local.external_id, local.source_identity)
  bootstrap_policy_path     = var.use_runtime_policy ? "${path.module}/files/bootstrap_role_iam_policy_runtime.json.tpl" : "${path.module}/files/bootstrap_role_iam_policy.json.tpl"
  perm_boundary_policy_path = var.use_runtime_policy ? "${path.module}/files/permission_boundary_iam_policy_runtime.json.tpl" : "${path.module}/files/permission_boundary_iam_policy.json.tpl"
  arn_like_vpcs             = formatlist("\"arn:%s:ec2:%s:%s:vpc/%s\"", var.partition, var.region, local.account_id, var.runtime_vpc_allowed_ids)
  arn_like_vpcs_str         = format("[%s]", join(",", local.arn_like_vpcs))
  tag_set                   = merge({ Vendor = "StreamNative", SNVersion = var.sn_policy_version }, var.tags)
}

data "aws_iam_policy_document" "streamnative_control_plane_access" {
  statement {
    sid     = "AllowStreamNativeVendorAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.streamnative_vendor_access_role_arns
    }
    dynamic "condition" {
      for_each = local.assume_conditions
      content {
        test     = condition.value["test"]
        values   = condition.value["values"]
        variable = condition.value["variable"]
      }
    }
  }

  statement {
    sid     = "AllowStreamNativeControlPlaneAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "accounts.google.com"
      ]
    }
    condition {
      test     = "StringEquals"
      values   = [var.streamnative_google_account_id]
      variable = "accounts.google.com:aud"
    }
  }
}

######
#-- Create the IAM Permission Boundary used by all StreamNative
#-- IAM Resources. This restricts what type of access we have
#-- within your AWS Account and is applied to all our IAM Roles
######
resource "aws_iam_policy" "permission_boundary" {
  name        = "StreamNativeCloudPermissionBoundary"
  description = "This policy sets the permission boundary for StreamNative's vendor access. It defines the limits of what StreamNative can do within this AWS account."
  path        = "/StreamNative/"
  policy = templatefile(local.perm_boundary_policy_path,
    {
      account_id = local.account_id
      partition  = var.partition
      region     = var.region
  })
  tags = local.tag_set
}

resource "local_file" "permission_boundary_policy" {
  count = var.write_policy_files ? 1 : 0
  content = templatefile(local.perm_boundary_policy_path,
    {
      account_id = local.account_id
      region     = var.region
  })
  filename = "permission_boundary_policy.json"
}

######
#-- Create the IAM role for bootstraping of the StreamNative Cloud
#-- This role is only needed for the initial StreamNative Cloud
#-- deployment to an AWS account, or when it is being removed.
######
resource "aws_iam_role" "bootstrap_role" {
  count                = var.create_bootstrap_role ? 1 : 0
  name                 = "StreamNativeCloudBootstrapRole"
  description          = "This role is used to bootstrap the StreamNative Cloud within the AWS account. It is limited in scope to the attached policy and also the permission boundary."
  assume_role_policy   = data.aws_iam_policy_document.streamnative_vendor_access.json
  path                 = "/StreamNative/"
  permissions_boundary = aws_iam_policy.permission_boundary.arn
  tags                 = local.tag_set
}

resource "aws_iam_policy" "bootstrap_policy" {
  count       = var.create_bootstrap_role ? 1 : 0
  name        = "StreamNativeCloudBootstrapPolicy"
  description = "This policy sets the minimum amount of permissions needed by the StreamNativeCloudBootstrapRole to bootstrap the StreamNative Cloud deployment."
  path        = "/StreamNative/"
  policy = templatefile(local.bootstrap_policy_path,
    {
      account_id       = local.account_id
      region           = var.region
      vpc_ids          = local.arn_like_vpcs_str
      bucket_pattern   = var.runtime_s3_bucket_pattern
      nodepool_pattern = var.runtime_eks_nodepool_pattern
      cluster_pattern  = var.runtime_eks_cluster_pattern
      partition        = var.partition
  })
  tags = local.tag_set
}

resource "local_file" "bootstrap_policy" {
  count = var.write_policy_files ? 1 : 0
  content = templatefile(local.bootstrap_policy_path,
    {
      account_id       = local.account_id
      region           = var.region
      vpc_ids          = local.arn_like_vpcs_str
      bucket_pattern   = var.runtime_s3_bucket_pattern
      nodepool_pattern = var.runtime_eks_nodepool_pattern
      cluster_pattern  = var.runtime_eks_cluster_pattern
  })
  filename = "bootstrap_policy.json"
}

resource "aws_iam_role_policy_attachment" "bootstrap_policy" {
  count      = var.create_bootstrap_role ? 1 : 0
  policy_arn = aws_iam_policy.bootstrap_policy[0].arn
  role       = aws_iam_role.bootstrap_role[0].name
}

######
#-- Create the IAM role for the management of the StreamNative Cloud
#-- This role is used by StreamNative for management and troubleshooting
#-- of the managed deployment.
######
resource "aws_iam_policy" "management_role" {
  name        = "StreamNativeCloudManagementPolicy"
  description = "This policy sets the limits for the management role needed for StreamNative's vendor access."
  path        = "/StreamNative/"
  policy = templatefile("${path.module}/files/management_role_iam_policy.json.tpl",
    {
      account_id = data.aws_caller_identity.current.account_id
      partition  = var.partition
      region     = var.region
  })
  tags = local.tag_set
}

resource "local_file" "management_policy" {
  count = var.write_policy_files ? 1 : 0
  content = templatefile("${path.module}/files/management_role_iam_policy.json.tpl",
    {
      account_id = data.aws_caller_identity.current.account_id
      region     = var.region
      partition  = var.partition
  })
  filename = "management_policy.json"
}

resource "aws_iam_role" "management_role" {
  name                 = "StreamNativeCloudManagementRole"
  description          = "This role is used by StreamNative for the day to day management of the StreamNative Cloud deployment."
  assume_role_policy   = data.aws_iam_policy_document.streamnative_control_plane_access.json
  path                 = "/StreamNative/"
  permissions_boundary = aws_iam_policy.permission_boundary.arn
  tags                 = local.tag_set
}

resource "aws_iam_role_policy_attachment" "management_role" {
  policy_arn = aws_iam_policy.management_role.arn
  role       = aws_iam_role.management_role.name
}

######
#-- Creates the IAM Policies used by EKS Cluster add-on services
######
data "aws_ebs_default_kms_key" "current" {}
data "aws_kms_key" "default_ebs" {
  key_id = data.aws_ebs_default_kms_key.current.key_arn
}

locals {
  kms_key_arns = length(var.runtime_ebs_kms_key_arns) > 0 ? var.runtime_ebs_kms_key_arns : [
    data.aws_kms_key.default_ebs.arn
  ]
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
      variable = "autoscaling:ResourceTag/eks:cluster-name"
      values   = [var.runtime_eks_cluster_pattern]
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
    resources = ["arn:${var.partition}:s3:::${var.runtime_s3_bucket_pattern}"]
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
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.runtime_eks_cluster_pattern}"
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
      "arn:${var.partition}:ec2:*:*:volume/*",
      "arn:${var.partition}:ec2:*:*:snapshot/*"
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
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.runtime_eks_cluster_pattern}"
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
      vpc_ids   = local.arn_like_vpcs_str
      partition = var.partition
  })
  tags = local.tag_set
}

resource "local_file" "runtime_policy" {
  count    = var.write_policy_files ? 1 : 0
  content  = data.aws_iam_policy_document.runtime_policy.json
  filename = "runtime_policy.json"
}

resource "local_file" "alb_policy" {
  count = var.write_policy_files ? 1 : 0
  content = templatefile("${path.module}/files/aws_lb_controller.json.tpl",
    {
      vpc_ids   = local.arn_like_vpcs_str
      partition = var.partition
  })
  filename = "alb_policy.json"
}
