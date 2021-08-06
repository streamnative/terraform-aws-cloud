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

module "tiered_storage" {
  source  = "streamnative/managed-cloud/aws//modules/tiered_storage"
  version = "0.4.1"

  bucket_name = var.s3_bucket_name_override
  bucket_tags = merge(local.bucket_tags, var.additional_tags)
}

data "aws_iam_policy_document" "tiered_storage" {
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
      values   = [format("system:serviceaccount:%s:%s", var.pulsar_namespace, "pulsar")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "tiered_storage" {
  name               = format("%s-tiered-storage-role", module.eks.cluster_id)
  description        = format("Role assumed by EKS ServiceAccount %s", local.tiered_storage_sa_id)
  assume_role_policy = data.aws_iam_policy_document.tiered_storage.json
  tags               = merge(local.bucket_tags, var.additional_tags)
}

resource "aws_iam_role_policy_attachment" "tiered_storage" {
  role       = aws_iam_role.tiered_storage.name
  policy_arn = module.tiered_storage.policy_arn
}
