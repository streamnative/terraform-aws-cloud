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

resource "aws_s3_bucket" "tiered_storage" {
  bucket = var.bucket_name_override == "" ? format("snc-%s-offload-%s", var.cluster_name, data.aws_region.current.name) : var.bucket_name_override
  tags   = merge({ "Vendor" = "StreamNative", "Attributes" = "offload", "Name" = "offload" }, var.tags)

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tiered_storage" {
  bucket = aws_s3_bucket.tiered_storage.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "tiered_storage" {
  bucket = aws_s3_bucket.tiered_storage.id
  acl    = "private"
}

data "aws_iam_policy_document" "tiered_storage" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:List*",
    ]

    resources = [
      aws_s3_bucket.tiered_storage.arn,
      "${aws_s3_bucket.tiered_storage.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "tiered_storage_sts" {
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
  description          = format("Role used by IRSA and the KSA %s on StreamNative Cloud EKS cluster %s", var.cluster_name, var.service_account_name)
  assume_role_policy   = data.aws_iam_policy_document.tiered_storage_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = merge({ "Vendor" = "StreamNative" }, var.tags)

  lifecycle {
    ignore_changes = [
      assume_role_policy
    ]
  }
}

resource "aws_iam_policy" "tiered_storage" {
  count       = var.use_runtime_policy ? 0 : 1
  name        = format("%s-TieredStoragePolicy", var.cluster_name)
  description = "Policy that defines the permissions for Pulsar's tiered storage offloading to S3, running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.tiered_storage.json
  tags        = merge({ "Vendor" = "StreamNative" }, var.tags)

  lifecycle {
    ignore_changes = [
      policy
    ]
  }
}

resource "aws_iam_role_policy_attachment" "tiered_storage" {
  policy_arn = var.use_runtime_policy ? "StreamNativeCloudRuntimePolicy" : aws_iam_policy.tiered_storage[0].arn
  role       = aws_iam_role.tiered_storage.name
}