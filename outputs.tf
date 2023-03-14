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
output "cloudwatch_log_group_arn" {
  value       = module.eks.cloudwatch_log_group_arn
  description = "Arn of cloudwatch log group created"
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

output "eks_cluster_primary_security_group_id" {
  value       = module.eks.cluster_primary_security_group_id
  description = "The id of the primary security group created by the EKS service itself, not by this module. This is labeled \"Cluster Security Group\" in the EKS console."
}

output "eks_cluster_secondary_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "The id of the secondary security group created by this module. This is labled \"Additional Security Groups\" in the EKS console."
}

output "node_groups" {
  value       = module.eks.node_groups
  description = "Outputs from EKS node groups. Map of maps, keyed by var.node_groups keys"
}

output "worker_iam_role_arn" {
  value       = module.eks.worker_iam_role_arn
  description = "The IAM Role ARN used by the Worker configuration"
}

output "worker_security_group_id" {
  value       = module.eks.worker_security_group_id
  description = "Security group ID attached to the EKS node groups"
}

output "worker_https_ingress_security_group_rule" {
  value       = module.eks.security_group_rule_cluster_https_worker_ingress
  description = "Security group rule responsible for allowing pods to communicate with the EKS cluster API."
}

output "cert_manager_arn" {
  value = var.enable_cert_manager ? aws_iam_role.cert_manager[0].arn : ""
  description = "The ARN for Cert Manager"
}

output "external_dns_arn" {
  value = var.enable_external_dns ? aws_iam_role.external_dns[0].arn : ""
  description = "The ARN for External DNS"
}

output "aws_loadbalancer_arn" {
  value = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : ""
  description = "ARN for loadbalancer"
}

output "csi_arn" {
  value = var.enable_csi ? aws_iam_role.csi[0].arn : ""
  description = "ARN for csi"
}

output "cluster_autoscaler_arn" {
  value = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : ""
  description = "ARN for Cluster Autoscaler"
}
