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
  value       = join("", aws_iam_role.cert_manager.*.arn)
  description = "The IAM Role ARN used by the Certificate Manager configuration"
}

output "cluster_autoscaler_role_arn" {
  value       = join("", aws_iam_role.cluster_autoscaler.*.arn)
  description = "The IAM Role ARN used by the Cluster Autoscaler configuration"
}

output "eks_cluster_arn" {
  value       = module.eks.cluster_arn
  description = "The ARN for the EKS cluster created by this module"
}

output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "The id/name of the EKS cluster created by this module"
}

output "eks_cluster_identity_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "The URL for the OIDC issuer created by this module"
}

output "eks_cluster_identity_oidc_issuer_arn" {
  value       = module.eks.oidc_provider_arn
  description = "The ARN for the OIDC issuer created by this module"
}

output "eks_cluster_identity_oidc_issuer_string" {
  value       = local.oidc_issuer
  description = "A formatted string containing the prefix for the OIDC issuer created by this module. Same as \"cluster_oidc_issuer_url\", but with \"https://\" stripped from the name. This output is typically used in other StreamNative modules that request the \"oidc_issuer\" input."
}

output "external_dns_role_arn" {
  value       = join("", aws_iam_role.external_dns.*.arn)
  description = "The IAM Role ARN used by the ExternalDNS configuration"
}

output "sn_system_namespace" {
  value       = join("", kubernetes_namespace.sn_system.*.id)
  description = "The namespace used for StreamNative system resources, i.e. operators et all"
}

output "worker_iam_role_arn" {
  value       = module.eks.worker_iam_role_arn
  description = "The IAM Role ARN used by the Worker configuration"
}