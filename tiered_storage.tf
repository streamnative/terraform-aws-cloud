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
  count  = var.enable_resource_creation ? 1 : 0
  bucket = format("%s-offload", var.cluster_name)
  tags   = merge({ "Attributes" = "offload" }, local.tags)

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

moved {
  from = aws_s3_bucket.tiered_storage
  to   = aws_s3_bucket.tiered_storage[0]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tiered_storage" {
  count  = var.enable_resource_creation ? 1 : 0
  bucket = aws_s3_bucket.tiered_storage[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.s3_kms_key
      sse_algorithm     = "aws:kms"
    }
  }
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.tiered_storage
  to   = aws_s3_bucket_server_side_encryption_configuration.tiered_storage[0]
}