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

output "cert_manager_role_arn" {
  value = aws_iam_role.cert_manager.arn
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_identity_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "eks_cluster_identity_oidc_issuer_arn" {
  value = module.eks.oidc_provider_arn
}

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "tiered_storage_role_arn" {
  value = aws_iam_role.tiered_storage.arn
}

output "vault_role_arn" {
  value = aws_iam_role.vault[0].arn
}
