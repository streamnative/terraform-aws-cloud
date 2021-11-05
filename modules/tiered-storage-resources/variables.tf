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

variable "cluster_name" {
  description = "The name of your EKS cluster and associated resources"
  type        = string
}

variable "create_iam_policy_for_tiered_storage" {
  default     = true
  description = "Whether to create the IAM policy used by Pulsar's tiered storage offloading. For enhanced security, we allow for these IAM policies to be created seperately from this module. Defaults to \"true\". If set to \"false\", you must provide the ARN for the IAM policy needed for tiered storage offloading to function."
  type        = bool
}

variable "iam_policy_arn" {
  default     = null
  description = "The arn for the IAM policy used for Pulsar's tiered storage offloading. For enhanced security, we allow for IAM policies used by cluster addon services to be created seperately from this module. This is only required if the input \"create_iam_policy_for_tiered_storage\" is set to \"false\". If created elsewhere, the expected name of the policy is \"StreamNativeCloudTieredStoragedPolicy\"."
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
  description = "The kubernetes namespace where Pulsar has been deployed. This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role"
  type        = string
}

variable "service_account_name" {
  default     = "pulsar"
  description = "The name of the kubernetes service account to by tiered storage offloading. Defaults to \"pulsar\". This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tags to be added to the bucket and corresponding resources"
  type        = map(string)
}
