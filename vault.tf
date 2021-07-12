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

module "vault" {
  count   = var.enable_vault ? 1 : 0
  source  = "streamnative/managed-cloud/aws//modules/vault_resources"
  version = "0.4.1"

  prefix = coalesce(var.vault_prefix_override, module.this.id)
}

data "aws_iam_policy_document" "vault_base_policy" {
  statement {
    actions = [
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "vault" {
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
      values   = [format("system:serviceaccount:%s:%s", var.pulsar_namespace, "vault")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "vault" {
  count              = var.enable_vault ? 1 : 0
  name               = format("%s-vault-role", module.eks.cluster_id)
  description        = format("Role assumed by EKS ServiceAccount %s", local.vault_sa_id)
  assume_role_policy = data.aws_iam_policy_document.vault.json

  inline_policy {
    name   = format("%s-vault-base-policy", module.eks.cluster_id)
    policy = data.aws_iam_policy_document.vault_base_policy.json
  }
}

resource "aws_iam_role_policy_attachment" "vault" {
  count      = var.enable_vault ? 1 : 0
  role       = aws_iam_role.vault[0].name
  policy_arn = module.vault[0].policy_arn
}
