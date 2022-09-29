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

data "aws_iam_policy_document" "csi" {
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:${local.aws_partition}:ec2:*:*:volume/*",
      "arn:${local.aws_partition}:ec2:*:*:snapshot/*"
    ]
    effect = "Allow"
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateVolume", "CreateSnapshot"]
    }
  }
  statement {
    actions = [
      "ec2:DeleteTags"
    ]
    resources = [
      "arn:${local.aws_partition}:ec2:*:*:volume/*",
      "arn:${local.aws_partition}:ec2:*:*:snapshot/*"
    ]
    effect = "Allow"
  }
  statement {
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
  statement {
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }
  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }
  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
  statement {
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }
  statement {
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
  statement {
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = [local.ebs_kms_key]
    effect    = "Allow"
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [local.ebs_kms_key]
    effect    = "Allow"
  }
}

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
  name                 = format("%s-csi-role", module.eks.cluster_id)
  description          = format("Role used by IRSA and the KSA ebs-csi-controller-sa on StreamNative Cloud EKS cluster %s", module.eks.cluster_id)
  assume_role_policy   = data.aws_iam_policy_document.csi_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_policy" "csi" {
  count       = var.create_iam_policies ? 1 : 0
  name        = format("%s-CsiPolicy", module.eks.cluster_id)
  description = "Policy that defines the permissions for the EBS Container Storage Interface CSI addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.csi.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "csi_managed" {
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.csi.name
}

resource "aws_iam_role_policy_attachment" "csi" {
  policy_arn = var.create_iam_policies ? aws_iam_policy.csi[0].arn : local.default_service_policy_arn
  role       = aws_iam_role.csi.name
}

resource "helm_release" "csi" {
  count           = var.enable_bootstrap ? 1 : 0
  atomic          = true
  chart           = var.csi_helm_chart_name
  cleanup_on_fail = true
  name            = "aws-ebs-csi-driver"
  namespace       = "kube-system"
  repository      = var.csi_helm_chart_repository
  timeout         = 300
  version         = var.csi_helm_chart_version
  values = [yamlencode({
    controller = {
      extraVolumeTags = merge(var.additional_tags, {
        "Vendor" = "StreamNative"
      })
      serviceAccount = {
        create = true
        name   = "ebs-csi-controller-sa"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.csi.arn
        }
      }
    }
  })]

  dynamic "set" {
    for_each = var.csi_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.eks
  ]
}
