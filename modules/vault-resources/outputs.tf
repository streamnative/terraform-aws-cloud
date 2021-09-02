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

output "dynamo_table_name" {
  value       = aws_dynamodb_table.vault_table.id
  description = "The name of the dynamodb table used by Vault"
}

output "dynamo_table_arn" {
  value       = aws_dynamodb_table.vault_table.arn
  description = "The arn of the dynamodb table used by Vault"
}

output "kms_key_alias_name" {
  value       = aws_kms_alias.vault_key.name
  description = "The name of the kms key alias used by Vault"
}

output "kms_key_alias_arn" {
  value       = aws_kms_alias.vault_key.arn
  description = "The arn of the kms key alias used by Vault"
}

output "kms_key_target_arn" {
  value       = aws_kms_key.vault_key.arn
  description = "The arn of the kms key used by Vault"
}

output "role_arn" {
  value       = aws_iam_role.vault.arn
  description = "The arn of the IAM role used by Vault. This needs to be annotated on the corresponding Kubernetes Service account in order for IRSA to work properly, e.g. \"eks.amazonaws.com/role-arn\" : \"<this_arn>\""
}

output "role_name" {
  value       = aws_iam_role.vault.name
  description = "The name of the IAM role used by Vault"
}
