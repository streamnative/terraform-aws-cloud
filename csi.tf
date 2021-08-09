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
      values   = [format("system:serviceaccount:%s:%s", var.csi_namespace, var.csi_sa_name)]
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
  name               = format("%s-%s-role", module.eks.cluster_id, var.csi_sa_name)
  description        = format("Role assumed by EKS ServiceAccount %s", var.csi_sa_name)
  assume_role_policy = data.aws_iam_policy_document.csi_sts.json

  inline_policy {
    name   = format("%s-%s-policy", module.eks.cluster_id, var.csi_sa_name)
    policy = data.aws_iam_policy_document.csi.json
  }
}

resource "helm_release" "csi" {
  atomic          = true
  chart           = "aws-ebs-csi-driver"
  cleanup_on_fail = true
  name            = "aws-ebs-csi-driver"
  namespace       = var.csi_namespace
  repository      = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  timeout         = 300

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
    type  = "string"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = var.csi_sa_name
    type  = "string"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com\\/role\\-arn"
    value = aws_iam_role.csi.arn
    type  = "string"
  }
}

resource "kubernetes_storage_class" "sn_default" {
  metadata {
    name = "sn-default"
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  parameters = {
    type = "gp2"
  }
}

resource "kubernetes_storage_class" "sn_ssd" {
  metadata {
    name = "sn-ssd"
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  parameters = {
    type = "gp2"
  }
}