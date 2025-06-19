terraform {
  required_version = "1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
}
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  cluster_name                   = var.override_cluster_name != "" ? var.override_cluster_name : "${var.pm_name}-snc"
  aws_partition                  = data.aws_partition.current.partition
  account_id                     = data.aws_caller_identity.current.account_id
  allowed_public_cidrs           = var.protect_k8s_public_endpoint ? concat(var.control_plane_egress_cidrs, var.k8s_public_endpoint_allowed_cidrs) : ["0.0.0.0/0"]
  enable_nodes_use_public_subnet = var.enable_public_ip_nodes == true ? true : false
}


data "aws_eks_cluster" "cluster" {
  name = module.sn_cluster.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.sn_cluster.eks_cluster_name
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  insecure               = false
}

module "sn_cluster" {
  source = "../.."

  cluster_name                  = local.cluster_name
  cluster_version               = var.cluster_version
  region                        = var.region
  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons

  cluster_iam              = var.cluster_iam
  map_additional_iam_roles = var.cluster_role_mapping
  permissions_boundary_arn = var.override_permission_boundary_arn != "" ? var.override_permission_boundary_arn : "arn:${local.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudPermissionBoundary"
  additional_tags          = var.additional_tags

  cluster_networking               = var.cluster_networking
  vpc_id                           = var.vpc_id
  private_subnet_ids               = var.private_subnet_ids
  public_subnet_ids                = var.public_subnet_ids
  allowed_public_cidrs             = local.allowed_public_cidrs
  enable_nodes_use_public_subnet   = local.enable_nodes_use_public_subnet
  enable_vpc_cni_prefix_delegation = var.enable_vpc_cni_prefix_delegation

  node_groups                      = var.node_groups
  enable_v3_node_groups            = var.enable_v3_node_groups
  enable_v3_node_taints            = false
  v3_node_group_core_instance_type = var.node_pool_instance_type
  node_pool_max_size               = var.node_pool_max_size
  node_pool_min_size               = var.enable_topology_aware_gateway && !var.enable_karpenter ? max(length(var.node_pool_azs), length(var.public_subnet_ids), length(var.private_subnet_ids)) : 0
  node_pool_desired_size           = var.enable_topology_aware_gateway && !var.enable_karpenter ? max(length(var.node_pool_azs), length(var.public_subnet_ids), length(var.private_subnet_ids)) : 1 # We need at least one node to run the cluster autoscaler
  enable_node_pool_monitoring      = false
  cluster_enabled_log_types        = var.cluster_enabled_log_types
  node_pool_azs                    = var.node_pool_azs

  use_runtime_policy       = false
  create_iam_policies      = false
  enable_resource_creation = false
  enable_bootstrap         = false
  enable_istio             = false
  enable_cilium            = false
}
