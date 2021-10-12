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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.20.0"

  # cluster_iam_role_name        = aws_iam_role.cluster.name
  cluster_name                  = var.cluster_name
  cluster_version               = var.cluster_version
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  cluster_log_kms_key_id        = var.cluster_log_kms_key_id
  cluster_log_retention_in_days = var.cluster_log_retention_in_days
  enable_irsa                   = true
  kubeconfig_output_path        = var.kubeconfig_output_path
  iam_path                      = "/StreamNative/"
  manage_cluster_iam_resources  = true
  manage_worker_iam_resources   = true
  map_accounts                  = var.map_additional_aws_accounts
  map_roles                     = var.map_additional_iam_roles
  map_users                     = var.map_additional_iam_users
  permissions_boundary          = var.permissions_boundary_arn
  subnets                       = local.cluster_subnet_ids
  vpc_id                        = var.vpc_id
  wait_for_cluster_timeout      = var.wait_for_cluster_timeout // This was added in version 17.1.0, and if set above 0, causes TF to crash.
  # workers_role_name            = aws_iam_role.nodes.name
  write_kubeconfig = var.write_kubeconfig


  node_groups = local.node_groups

  node_groups_defaults = {
    additional_tags = merge({
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      format("k8s.io/cluster-autoscaler/%s", var.cluster_name) = "owned",
      "Vendor"                                                 = "StreamNative"
      },
      var.additional_tags
    )
    # iam_role_arn = aws_iam_role.nodes.arn
    subnets = var.private_subnet_ids
  }

  tags = {
    format("k8s.io/cluster/%s", var.cluster_name) = "owned",
    "Vendor"                                      = "StreamNative"
  }
}

resource "kubernetes_namespace" "sn_system" {
  metadata {
    name = "sn-system"
  }
  depends_on = [
    module.eks
  ]
}

######
### IAM Resources for the EKS Cluster
######
# data "aws_iam_policy_document" "cluster_assume_role_policy" {
#   statement {
#     actions = [
#       "sts:AssumeRole"
#     ]
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["eks.amazonaws.com"]
#     }
#   }
# }

# data "aws_iam_policy_document" "cluster_elb_sl_role_creation" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "ec2:DescribeAccountAttributes",
#       "ec2:DescribeInternetGateways",
#       "ec2:DescribeAddresses"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "cluster_elb_sl_role_creation" {
#   name_prefix = "${var.cluster_name}-elb-sl-role-creation"
#   description = "Permissions for EKS to create AWSServiceRoleForElasticLoadBalancing service-linked role"
#   policy      = data.aws_iam_policy_document.cluster_elb_sl_role_creation.json
#   tags        = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
# }

# resource "aws_iam_role" "cluster" {
#   name                 = format("%s-cluster-role", var.cluster_name)
#   description          = format("The IAM Role used by the %s EKS cluster", var.cluster_name)
#   assume_role_policy   = data.aws_iam_policy_document.cluster_assume_role_policy.json
#   tags                 = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
#   path                 = "/StreamNative/"
#   permissions_boundary = format("arn:aws:iam::%s:policy/StreamNativePermissionBoundary", local.account_id)
# }

# resource "aws_iam_role_policy_attachment" "cluster_elb_sl_role_creation" {
#   policy_arn = aws_iam_policy.cluster_elb_sl_role_creation.arn
#   role       = aws_iam_role.cluster.name
# }

# resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.cluster.name
# }

# resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#   role       = aws_iam_role.cluster.name
# }

# resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceControllerPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
#   role       = aws_iam_role.cluster.name
# }

# ######
# ### IAM Resources for the node groups
# ######
# data "aws_iam_policy_document" "nodes_assume_role_policy" {
#   statement {
#     actions = [
#       "sts:AssumeRole"
#     ]
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "nodes" {
#   name               = format("%s-nodes-role", var.cluster_name)
#   description        = format("The IAM Role used by the %s EKS cluster's node groups", var.cluster_name)
#   assume_role_policy = data.aws_iam_policy_document.nodes_assume_role_policy.json
#   tags               = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
#   path               = "/StreamNative/"
#   permissions_boundary = format("arn:aws:iam::%s:policy/StreamNativePermissionBoundary", local.account_id)
# }

# resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSnodeNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.nodes.name
# }

# resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.nodes.name
# }

# resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.nodes.name
# }
