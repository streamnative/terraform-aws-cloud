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

variable "create_iam_policy_for_vault" {
  default     = true
  description = "Whether to create the IAM policy used by Hashicorp Vault. For enhanced security, we allow for these IAM policies to be created seperately from this module. Defaults to \"true\". If set to \"false\", you must provide the ARN for the IAM policy needed for Vault to function."
  type        = bool
}

variable "iam_policy_arn" {
  default     = null
  description = "The arn for the IAM policy used by Hasicorp Vault. For enhanced security, we allow for IAM policies used by cluster addon services to be created seperately from this module. This is only required if the input \"create_iam_policy_for_vault\" is set to \"false\". If created elsewhere, the expected name of the policy is \"StreamNativeCloudVaultPolicy\"."
  type        = string
}

variable "dynamo_billing_mode" {
  default     = "PAY_PER_REQUEST"
  description = "the billing mode for the dynamodb table that will be created"
  type        = string
}

variable "dynamo_provisioned_capacity" {
  default = {
    read : 10,
    write : 10
  }
  description = "when using \"PROVISIONED\" billing mode, the specified values will be use for throughput, in all other modes they are ignored"
  type = object({
    read  = number,
    write = number
  })
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
  description = "The kubernetes namespace where Pulsar has been deployed. This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account for Vault access to use the IAM role"
  type        = string
}
variable "tags" {
  default     = {}
  description = "Tags that will be added to resources"
  type        = map(string)
}

variable "service_account_name" {
  default     = "vault"
  description = "The name of the kubernetes service account to by vault. Defaults to \"vault\""
  type        = string
}
