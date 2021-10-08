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

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "pulsar_offload" {
  acl    = "private"
  bucket = format("%s-storage-offload-%s", var.cluster_name, data.aws_region.current.name)

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = merge({ "Vendor" = "StreamNative", "Attributes" = "offload", "Name" = "offload" }, var.tags)
}

data "aws_iam_policy_document" "tiered_storage_base_policy" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:List*",
    ]

    resources = [
      aws_s3_bucket.pulsar_offload.arn,
      "${aws_s3_bucket.pulsar_offload.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "tiered_storage_sts_policy" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", var.aws_partition, data.aws_caller_identity.current.account_id, var.oidc_issuer)]
    }
    condition {
      test     = "StringLike"
      values   = [format("system:serviceaccount:%s:%s", var.pulsar_namespace, var.service_account_name)]
      variable = format("%s:sub", var.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "tiered_storage" {
  name                 = format("%s-tiered-storage-role", var.cluster_name)
  description          = format("Role assumed by EKS ServiceAccount %s", var.service_account_name)
  assume_role_policy   = data.aws_iam_policy_document.tiered_storage_sts_policy.json
  tags                 = merge({ "Vendor" = "StreamNative" }, var.tags)
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn

  inline_policy {
    name   = format("%s-tiered-storage-base-policy", var.cluster_name)
    policy = data.aws_iam_policy_document.tiered_storage_base_policy.json
  }
}
