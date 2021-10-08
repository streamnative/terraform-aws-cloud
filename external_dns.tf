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

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid = "ChangeResourceRecordSets"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
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
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", var.aws_partition, local.account_id, local.oidc_issuer)]
    }
    condition {
      test     = "StringLike"
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "external-dns")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name                 = format("%s-external-dns-role", module.eks.cluster_id)
  description          = "Role assumed by EKS ServiceAccount external-dns"
  assume_role_policy   = data.aws_iam_policy_document.external_dns_sts.json
  tags                 = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn

  inline_policy {
    name   = format("%s-external-dns-policy", module.eks.cluster_id)
    policy = data.aws_iam_policy_document.external_dns.json
  }
}

resource "helm_release" "external_dns" {
  atomic          = true
  chart           = var.external_dns_helm_chart_name
  cleanup_on_fail = true
  namespace       = "kube-system"
  name            = "external-dns"
  repository      = var.external_dns_helm_chart_repository
  timeout         = 300
  version         = var.external_dns_helm_chart_version

  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "podSecurityContext.fsGroup"
    value = "65534"
  }

  set {
    name  = "podSecurityContext.runAsUser"
    value = "0"
  }

  set {
    name  = "rbac.create"
    value = "true"
    type  = "string"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
    type  = "string"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
    type  = "string"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com\\/role\\-arn"
    value = aws_iam_role.external_dns.arn
    type  = "string"
  }

  set {
    name  = "sources"
    value = var.disable_istio_sources == true ? "{service,ingress}" : "{service,ingress,istio-gateway,istio-virtualservice}"
  }

  set {
    name  = "txtOwnerId"
    value = module.eks.cluster_id
  }

  dynamic "set" {
    for_each = var.external_dns_settings
    content {
      name  = set.key
      value = set.value
    }
  }
}
