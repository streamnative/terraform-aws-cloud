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

variable "aws_partition" {
  default     = "aws"
  description = "AWS partition: 'aws', 'aws-cn', or 'aws-us-gov'"
  type        = string
}

variable "bucket_name_override" {
  default     = ""
  description = "Manually specify the bucket name. This allows for backwards compatability with older versions of this module, but should be coordinated with the \"var.s3_bucket_pattern\" input in the \"terraform-aws-cloud//modules/managed-cloud\" module"
  type        = string
}

variable "cluster_name" {
  description = "The name of your EKS cluster and associated resources"
  type        = string
}

variable "kms_key_id" {
  default     = "aws/s3"
  description = "The KMS key ID to use for server side encryption. Defaults to \"aws/s3\"."
  type        = string
}

variable "oidc_issuer" {
  description = "The OIDC issuer for the EKS cluster"
  type        = string
}

variable "permissions_boundary_arn" {
  default     = null
  description = "If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access."
  type        = string
}

variable "pulsar_namespace" {
  description = "The kubernetes namespace where Pulsar has been deployed, used to scope IRSA permissions. This is typically the Organization ID found in the StreamNative Console."
  type        = string
}

variable "service_account_name" {
  default     = "pulsar-broker"
  description = "The name of the kubernetes service account to by tiered storage offloading. Defaults to \"pulsar-broker\". This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tags to be added to the bucket and corresponding resources"
  type        = map(string)
}

variable "use_runtime_policy" {
  default     = false
  description = "Determines if this module should create or attach the needed IAM policy for the IAM role. This should be coordinated with the \"var.use_runtime_policy\" input in the \"terraform-aws-cloud//modules/managed-cloud\" module"
  type        = bool
}