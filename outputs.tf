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

output "eks_cluster_arn" {
  value       = module.eks.cluster_arn
  description = "The ARN for the EKS cluster created by this module"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint for the EKS cluster created by this module"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS cluster created by this module"
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

output "eks_cluster_platform_version" {
  value       = module.eks.cluster_platform_version
  description = "The platform version for the EKS cluster created by this module"
}

output "eks_cluster_primary_security_group_id" {
  value       = module.eks.cluster_primary_security_group_id
  description = "The id of the primary security group created by the EKS service itself, not by this module. This is labeled \"Cluster Security Group\" in the EKS console."
}

output "eks_cluster_secondary_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "The id of the secondary security group created by this module. This is labled \"Additional Security Groups\" in the EKS console."
}

output "eks_node_group_iam_role_arn" {
  value       = aws_iam_role.ng.arn
  description = "The IAM Role ARN used by the Worker configuration"
}

output "eks_node_group_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Security group ID attached to the EKS node groups"
}

output "eks_node_groups" {
  value       = module.eks.eks_managed_node_groups
  description = "Map of all attributes of the EKS node groups created by this module"
}

output "tiered_storage_s3_bucket_arn" {
  value       = var.enable_resource_creation ? aws_s3_bucket.tiered_storage[0].arn : null
  description = "The ARN for the tiered storage S3 bucket created by this module"
}

output "velero_s3_bucket_arn" {
  value       = var.enable_resource_creation ? aws_s3_bucket.velero[0].arn : null
  description = "The ARN for the Velero S3 bucket created by this module"
}

output "cert_manager_arn" {
  value       = var.enable_resource_creation ? aws_iam_role.cert_manager[0].arn : null
  description = "The ARN for Cert Manager"
}

output "external_dns_arn" {
  value       = var.enable_resource_creation ? aws_iam_role.external_dns[0].arn : null
  description = "The ARN for External DNS"
}

output "aws_loadbalancer_arn" {
  value       = var.enable_resource_creation ? aws_iam_role.aws_load_balancer_controller[0].arn : null
  description = "ARN for loadbalancer"
}

output "csi_arn" {
  value       = var.enable_resource_creation ? aws_iam_role.csi[0].arn : null
  description = "ARN for csi"
}

output "cluster_autoscaler_arn" {
  value       = var.enable_resource_creation ? aws_iam_role.cluster_autoscaler[0].arn : null
  description = "ARN for Cluster Autoscaler"
}

output "velero_arn" {
  value       = var.enable_resource_creation ? aws_iam_role.velero[0].arn : null
  description = "ARN for Velero"
}

output "eks_cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "eks" {
  value       = module.eks
  description = "All outputs of module.eks for provide convenient approach to access child module's outputs."
}

output "inuse_azs" {
  value       = distinct([for index, subnet in local.node_group_subnets : subnet.availability_zone])
  description = "The availability zones in which the EKS nodes is deployed"
}
