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

variable "pm_namespace" {
  type        = string
  description = "The namespace of the poolmember"
}

variable "pm_name" {
  description = "The name of the poolmember, for new clusters, this should be like `pm-<xxxxx>`"
  type        = string
}

variable "parent_zone_name" {
  type        = string
  description = "The parent zone in which we create the delegation records"
}

variable "custom_dns_zone_id" {
  type        = string
  default     = ""
  description = "if specified, then a streamnative zone will not be created, and this zone will be used instead. Otherwise, we will provision a new zone and delegate access"
}

variable "custom_dns_zone_name" {
  type        = string
  default     = ""
  description = "must be passed if custom_dns_zone_id is passed, this is the zone name to use"
}


variable "s3_encryption_kms_key_arn" {
  default     = ""
  description = "KMS key ARN to use for S3 encryption. If not set, the default AWS S3 key will be used."
  type        = string
}

variable "extra_aws_tags" {
  default     = {}
  description = "Additional to apply to the resources. Note that this module sets the tags Name, Type, and Vendor by default. They can be overwritten, but it is not recommended."
  type        = map(string)
}

locals {
  tags = merge({
    "Vendor" = "StreamNative"
  }, var.extra_aws_tags)
}

variable "enable_loki" {
  type        = bool
  default     = false
  description = "Enable loki storage bucket creation"
}