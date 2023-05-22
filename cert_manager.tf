# Copyright 2023 StreamNative, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "aws_iam_policy_document" "cert_manager" {
  statement {
    sid = "Changes"
    actions = [
      "route53:GetChange"
    ]
    resources = [
      "arn:${local.aws_partition}:route53:::change/*"
    ]
    effect = "Allow"
  }

  statement {
    sid = "Update"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "arn:${local.aws_partition}:route53:::hostedzone/${var.hosted_zone_id}"
    ]
    effect = "Allow"
  }

  statement {
    sid = "List"
    actions = [
      "route53:ListHostedZonesByName"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "cert_manager_sts" {
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
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "cert-manager-controller")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  count                = var.enable_resource_creation ? 1 : 0
  name                 = format("%s-cm-role", module.eks.cluster_id)
  description          = format("Role assumed by IRSA and the KSA cert-manager on StreamNative Cloud EKS cluster %s", module.eks.cluster_id)
  assume_role_policy   = data.aws_iam_policy_document.cert_manager_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

// add the move for this now being optional!
moved {
  from = aws_iam_role.cert_manager
  to   = aws_iam_role.cert_manager[0]
}

resource "aws_iam_policy" "cert_manager" {
  count       = (var.enable_resource_creation && var.create_iam_policies) ? 1 : 0
  name        = format("%s-CertManagerPolicy", module.eks.cluster_id)
  description = "Policy that defines the permissions for the Cert-Manager addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.cert_manager.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  count      = var.enable_resource_creation ? 1 : 0
  policy_arn = var.create_iam_policies ? aws_iam_policy.cert_manager[0].arn : local.default_service_policy_arn
  role       = aws_iam_role.cert_manager[0].name
}

moved {
  from = aws_iam_role_policy_attachment.cert_manager
  to   = aws_iam_role_policy_attachment.cert_manager[0]
}

resource "helm_release" "cert_manager" {
  count           = (var.enable_resource_creation && var.enable_bootstrap) ? 1 : 0
  atomic          = true
  chart           = var.cert_manager_helm_chart_name
  cleanup_on_fail = true
  name            = "cert-manager"
  namespace       = "kube-system"
  repository      = var.cert_manager_helm_chart_repository
  timeout         = 300
  version         = var.cert_manager_helm_chart_version
  values = [yamlencode({
    installCRDs = true
    controller = {
      args = [
        "--issuer-ambient-credentials=true"
      ]
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cert_manager[0].arn
        }
      }
      podSecurityContext = {
        fsGroup = 65534
      }
    }
    kubeVersion = var.cluster_version
  })]

  dynamic "set" {
    for_each = var.cert_manager_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "cert_issuer" {
  count           = (var.enable_resource_creation && var.enable_bootstrap) ? 1 : 0
  atomic          = true
  chart           = "${path.module}/charts/cert-issuer"
  cleanup_on_fail = true
  name            = "cert-issuer"
  namespace       = kubernetes_namespace.sn_system[0].metadata[0].name
  timeout         = 300
  values = [yamlencode({
    supportEmail = var.cert_issuer_support_email
    dns01 = {
      region = var.region
    }
  })]

  depends_on = [
    helm_release.cert_manager
  ]
}
