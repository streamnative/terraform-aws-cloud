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

resource "aws_s3_bucket" "tiered_storage" {
  bucket = format("%s-offload", var.cluster_name)
  tags   = merge({ "Attributes" = "offload" }, local.tags)

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

resource "aws_s3_bucket_acl" "tiered_storage" {
  bucket = aws_s3_bucket.tiered_storage.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tiered_storage" {
  bucket = aws_s3_bucket.tiered_storage.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.s3_kms_key
      sse_algorithm     = "aws:kms"
    }
  }
}
