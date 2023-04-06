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

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid = "ChangeResourceRecordSets"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:${local.aws_partition}:route53:::hostedzone/${var.hosted_zone_id}"
    ]
    effect = "Allow"
  }

  statement {
    sid = ""
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }
}

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
  name                 = format("%s-extdns-role", module.eks.cluster_id)
  description          = format("Role used by IRSA and the KSA external-dns on StreamNative Cloud EKS cluster %s", module.eks.cluster_id)
  assume_role_policy   = data.aws_iam_policy_document.external_dns_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_policy" "external_dns" {
  count       = var.create_iam_policies ? 1 : 0
  name        = format("%s-ExternalDnsPolicy", module.eks.cluster_id)
  description = "Policy that defines the permissions for the ExternalDNS addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.external_dns.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = var.create_iam_policies ? aws_iam_policy.external_dns[0].arn : local.default_service_policy_arn
  role       = aws_iam_role.external_dns.name
}


locals {
  default_sources = ["service", "ingress"]
  istio_sources   = ["istio-gateway", "istio-virtualservice"]
  sources         = var.enable_istio || var.enable_bootstrap ? concat(local.istio_sources, local.default_sources) : local.default_sources
}

resource "helm_release" "external_dns" {
  count           = var.enable_bootstrap ? 1 : 0
  atomic          = true
  chart           = var.external_dns_helm_chart_name
  cleanup_on_fail = true
  namespace       = "kube-system"
  name            = "external-dns"
  repository      = var.external_dns_helm_chart_repository
  timeout         = 300
  version         = var.external_dns_helm_chart_version

  values = [yamlencode({
    aws = {
      region = var.region
    }
    domainFilters = var.hosted_zone_domain_name_filters
    podSecurityContext = {
      fsGroup   = 65534
      runAsUser = 0
    }
    rbac = {
      create = true
    }
    replicaCount = 2
    serviceAccount = {
      create = true
      name   = "external-dns"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
      }
    }
    sources    = local.sources
    txtOwnerId = module.eks.cluster_id
  })]

  dynamic "set" {
    for_each = var.external_dns_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.eks
  ]
}
