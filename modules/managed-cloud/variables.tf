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

variable "additional_iam_policiy_arns" {
  default     = []
  description = "Provide a list of additional IAM policy arns allowed for use with iam:AttachRolePolicy, defined in the StreamNativePermissionBoundary."
  type        = list(string)
}

variable "create_bootstrap_role" {
  default     = true
  description = "Whether or not to create the bootstrap role, which is used by StreamNative for the initial deployment of the StreamNative Cloud"
  type        = string

}

variable "partition" {
  default     = "aws"
  description = "AWS partition: 'aws', 'aws-cn', or 'aws-us-gov', used when constructing IRSA trust relationship policies."
  type        = string
}

variable "region" {
  default     = "*"
  description = "The AWS region where your instance of StreamNative Cloud is deployed. Defaults to all regions \"*\""
  type        = string
}

variable "external_id" {
  default     = ""
  description = "The external ID, provided by StreamNative, which is used for all assume role calls. If not provided, no check for external_id is added. (NOTE: a future version will force the passing of this parameter)"
  type        = string
}

variable "source_identities" {
  default     = []
  description = "Place an additional constraint on source identity, disabled by default and only to be used if specified by StreamNative"
  type        = list(any)
}

variable "source_identity_test" {
  default     = "ForAnyValue:StringLike"
  description = "The test to use for source identity"
  type        = string
}

variable "streamnative_google_account_id" {
  default     = "108050666045451143798"
  description = "The Google Cloud service account ID used by StreamNative for Control Plane operations"
  type        = string
}


variable "streamnative_vendor_access_role_arns" {
  default     = ["arn:aws:iam::311022431024:role/cloud-manager"]
  description = "A list ARNs provided by StreamNative that enable us to work with the Vendor Access Roles created by this module (StreamNativeCloudBootstrapRole, StreamNativeCloudManagementRole). This is how StreamNative is granted access into your AWS account, and should typically be the default value."
  type        = list(string)
}

variable "use_runtime_policy" {
  description = "instead of relying on permission boundary use static runtime policies"
  default     = false
  type        = bool
}

variable "runtime_vpc_allowed_ids" {
  description = "when using runtime policy, allows for further scoping down policy for allowed VPC"
  default     = ["*"]
  type        = list(any)
}

variable "runtime_hosted_zone_allowed_ids" {
  description = "when using runtime policy, allows for further scoping down policy for allowed hosted zones"
  default     = ["*"]
  type        = list(any)
}

variable "runtime_ebs_kms_key_arns" {
  description = "when using runtime policy, sets the list of allowed kms key arns, if not set, uses the default ebs kms key"
  default     = []
  type        = list(any)
}

variable "runtime_enable_secretsmanager" {
  description = "when using runtime policy, allows for secretsmanager access"
  default     = false
  type        = bool
}

variable "runtime_eks_cluster_pattern" {
  description = "when using runtime policy, defines the eks clsuter prefix for streamnative clusters"
  default     = "aws*snc"
  type        = string
}

variable "runtime_eks_nodepool_pattern" {
  description = "when using runtime policy, defines the bucket prefix for streamnative managed buckets (backup and offload)"
  default     = "snc-*-pool*"
  type        = string
}

variable "runtime_s3_bucket_pattern" {
  description = "when using runtime policy, defines the bucket prefix for streamnative managed buckets (backup and offload)"
  default     = "snc-*"
  type        = string
}

variable "sn_policy_version" {
  default     = "2.0"
  description = "The value of SNVersion tag"
  type        = string
}



variable "tags" {
  default     = {}
  description = "Extra tags to apply to the resources created by this module."
  type        = map(string)
}


variable "write_policy_files" {
  default     = false
  description = "Write the policy files locally to disk for debugging and validation"
  type        = bool
}
