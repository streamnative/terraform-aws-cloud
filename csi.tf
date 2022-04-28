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

data "aws_kms_key" "ebs_default" {
  key_id = "alias/aws/ebs"
}

locals {
  kms_key = var.disk_encryption_kms_key_id == "" ? data.aws_kms_key.ebs_default.arn : var.disk_encryption_kms_key_id
}

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
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
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
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
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
    resources = [local.kms_key]
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
    resources = [local.kms_key]
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
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", var.aws_partition, local.account_id, local.oidc_issuer)]
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
  tags                 = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
}

resource "aws_iam_policy" "csi" {
  count       = var.sncloud_services_iam_policy_arn == "" ? 1 : 0
  name        = format("%s-CsiPolicy", module.eks.cluster_id)
  description = "Policy that defines the permissions for the EBS Container Storage Interface CSI addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.csi.json
  tags        = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
}

resource "aws_iam_role_policy_attachment" "csi" {
  policy_arn = var.sncloud_services_iam_policy_arn != "" ? var.sncloud_services_policy_arn : aws_iam_policy.csi[0].arn
  role       = aws_iam_role.csi[0].name
}

resource "helm_release" "csi" {
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
          "eks.amazonaws.com/role-arn" = aws_iam_role.csi[0].arn
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

resource "kubernetes_storage_class" "sn_default" {
  metadata {
    name = "sn-default"
  }
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = local.kms_key
  }
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

resource "kubernetes_storage_class" "sn_ssd" {
  metadata {
    name = "sn-ssd"
  }
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = local.kms_key
  }
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}
