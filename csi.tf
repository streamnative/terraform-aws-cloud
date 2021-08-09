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
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag"
      values   = ["efs.csi.aws.com/cluster: \"true\""]
    }
  }
  statement {
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag"
      values   = ["efs.csi.aws.com/cluster: \"true\""]
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
      test     = "StringLike"
      values   = [format("system:serviceaccount:%s:%s", var.csi_namespace, var.csi_sa_name)]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "csi" {
  count              = var.cluster_version >= "1.20" ? 1 : 0
  name               = format("%s-%s-role", module.eks.cluster_id, var.csi_sa_name)
  description        = format("Role assumed by EKS ServiceAccount %s", var.csi_sa_name)
  assume_role_policy = data.aws_iam_policy_document.csi_sts.json

  inline_policy {
    name   = format("%s-%s-policy", module.eks.cluster_id, var.csi_sa_name)
    policy = data.aws_iam_policy_document.csi.json
  }
}

resource "kubernetes_service_account" "csi" {
  count = var.cluster_version >= "1.20" ? 1 : 0

  metadata {
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.csi[0].arn
    }

    labels = {
      "app.kubernetes.io/name" = "aws-efs-csi-driver"
    }

    name      = "efs-csi-controller-sa"
    namespace = "kube-system"
  }
  depends_on = [
    module.eks
  ]
}

resource "helm_release" "csi" {
  count            = var.cluster_version >= "1.20" ? 1 : 0
  atomic           = true
  chart            = "aws-efs-csi-driver"
  cleanup_on_fail  = true
  create_namespace = false
  name             = "aws-efs-csi-driver"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  timeout          = 300
  wait             = true

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = trimprefix(kubernetes_service_account.csi[0].id, "kube-system/")
    type  = "string"
  }
}
