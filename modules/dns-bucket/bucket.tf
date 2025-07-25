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

resource "aws_s3_bucket" "velero" {
  bucket        = format("%s-cluster-backup-snc", var.pm_name)
  tags          = merge({ "Attributes" = "backup", "Name" = "velero-backups" }, local.tags)
  force_destroy = true

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

resource "aws_s3_bucket" "tiered_storage" {
  bucket        = format("%s-tiered-storage-snc", var.pm_name)
  tags          = merge({ "Attributes" = "tiered-storage" }, local.tags)
  force_destroy = true

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

resource "aws_s3_bucket" "loki" {
  count         = var.enable_loki ? 1 : 0
  provider      = aws.source
  region        = var.bucket_location
  bucket        = format("loki-%s-%s", var.pm_namespace, var.pm_name)
  tags          = merge({ "Attributes" = "loki", "Name" = "logs-byoc" }, local.tags)
  force_destroy = true

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

data "aws_kms_key" "s3_default" {
  key_id = "alias/aws/s3"
}

locals {
  s3_kms_key = var.s3_encryption_kms_key_arn == "" ? data.aws_kms_key.s3_default.arn : var.s3_encryption_kms_key_arn
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  bucket = aws_s3_bucket.velero.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.s3_kms_key
      sse_algorithm     = "aws:kms"
    }
  }
}
