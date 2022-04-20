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

data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid       = "ListSecrets"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    sid = "GetSecrets"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets",
    ]
    resources = coalescelist(var.asm_secret_arns, ["arn:*:secretsmanager:${var.region}:${local.account_id}:secret:*"]) # Defaults to allow access to all secrets for ASM in the module's region
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "external_secrets_sts" {
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
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "external-secrets")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count                = var.enable_external_secrets ? 1 : 0
  name                 = format("%s-extsec-role", module.eks.cluster_id)
  description          = format("Role used by IRSA and the KSA external-secrets on StreamNative Cloud EKS cluster %s", module.eks.cluster_id)
  assume_role_policy   = data.aws_iam_policy_document.external_secrets_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
}

resource "aws_iam_policy" "external_secrets" {
  count       = local.create_ext_sec_policy == "" ? 1 : 0
  name        = format("%s-ExternalSecretsPolicy", module.eks.cluster_id)
  description = "Policy that defines the permissions for the kubernetes-external-secrets addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.external_secrets.json
  tags        = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count      = var.enable_external_secrets ? 1 : 0
  policy_arn = local.sn_serv_policy_arn != "" ? local.sn_serv_policy_arn : aws_iam_policy.external_secrets[0].arn
  role       = aws_iam_role.external_secrets[0].name
}

resource "helm_release" "external_secrets" {
  count           = var.enable_external_secrets ? 1 : 0
  atomic          = true
  chart           = var.external_secrets_helm_chart_name
  cleanup_on_fail = true
  namespace       = "kube-system"
  name            = "external-secrets"
  repository      = var.external_secrets_helm_chart_repository
  timeout         = 300
  version         = var.external_secrets_helm_chart_version
  values = [yamlencode({
    env = {
      AWS_REGION = var.region
    }
    securityContext = {
      fsGroup = 65534
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets[0].arn
      }
      name = "external-secrets"
    }
  })]

  dynamic "set" {
    for_each = var.external_secrets_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.eks
  ]
}
