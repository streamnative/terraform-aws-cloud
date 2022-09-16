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

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

data "aws_kms_key" "ebs_default" {
  key_id = "alias/aws/ebs"
}

locals {
  aws_partition              = data.aws_partition.current.partition
  account_id                 = data.aws_caller_identity.current.account_id
  cluster_subnet_ids         = concat(var.private_subnet_ids, var.public_subnet_ids)
  default_lb_policy_arn      = "arn:${local.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudLBPolicy"
  default_service_policy_arn = "arn:${local.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudRuntimePolicy"
  kms_key                    = var.disk_encryption_kms_key_id == "" ? data.aws_kms_key.ebs_default.arn : var.disk_encryption_kms_key_id
  oidc_issuer                = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
  private_subnet_cidrs       = var.enable_node_group_private_networking == false ? [] : [for i, v in var.private_subnet_ids : data.aws_subnet.private_subnets[i].cidr_block]

  tags = merge(
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned",
      "k8s.io/cluster/${var.cluster_name}"        = "owned",
      "Vendor"                                    = "StreamNative"
    },
    var.additional_tags,
  )

  ## Node Group Configuration
  node_group_defaults = {
    ami_id = var.node_pool_ami_id
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = var.node_pool_disk_size
          volume_type           = "gp3"
          iops                  = var.node_pool_disk_iops
          encrypted             = true
          kms_key_id            = local.kms_key
          delete_on_termination = true
        }
      }
    }
    create_iam_role         = false # We create the IAM role ourselves to reduce complexity in managing the aws-auth configmap
    create_launch_template  = true
    desired_size            = var.node_pool_desired_size
    ebs_optimized           = var.node_pool_ebs_optimized
    enable_monitoring       = var.enable_node_pool_monitoring
    iam_role_arn            = aws_iam_role.ng.arn
    labels                  = var.node_pool_labels
    min_size                = var.node_pool_min_size
    max_size                = var.node_pool_max_size
    pre_bootstrap_user_data = var.node_pool_pre_userdata
    taints                  = var.node_pool_taints
    tags = merge(var.node_pool_tags, {
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      format("k8s.io/cluster-autoscaler/%s", var.cluster_name) = "owned",
    })
  }

  ## Create the node groups, one for each instance type AND each availability zone/subnet
  node_groups = {
    for node_group in flatten([
      for instance_type in var.node_pool_instance_types : [
        for i, j in data.aws_subnet.private_subnets : {
          subnet_ids     = [data.aws_subnet.private_subnets[i].id]
          instance_types = [instance_type],
          name           = "snc-${split(".", instance_type)[1]}-${data.aws_subnet.private_subnets[i].availability_zone}"
        }
      ]
    ]) : "${node_group.name}" => node_group
  }


  ### IAM role bindings
  sncloud_control_plane_access = [
    {
      rolearn  = format("arn:${local.aws_partition}:iam::%s:role/StreamNativeCloudManagementRole", local.account_id)
      username = "sn-manager:{{AccountID}}:{{SessionName}}"
      groups   = ["system:masters"]
    }
  ]

  # Remove the IAM Path from the role
  # Work around for https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/153
  worker_node_role = [
    {
      rolearn  = replace(aws_iam_role.ng.arn, replace(var.iam_path, "/^//", ""), "")
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  # Switches for different role binding scenarios
  role_bindings = var.enable_sncloud_control_plane_access && var.iam_path != "" ? concat(local.sncloud_control_plane_access, local.worker_node_role, var.map_additional_iam_roles) : var.enable_sncloud_control_plane_access && var.iam_path == "" ? concat(local.sncloud_control_plane_access, var.map_additional_iam_roles) : var.enable_sncloud_control_plane_access == false && var.iam_path != "" ? concat(var.map_additional_iam_roles, local.worker_node_role) : var.map_additional_iam_roles

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0"

  ##############################################################################################
  ### Added these to avoid issues with the module refactor from 17.X to 18.X.                ###
  ### Future versions of the terraform-aws-eks module may not require these to be specified. ###
  prefix_separator                   = ""
  iam_role_name                      = var.cluster_name
  cluster_security_group_name        = var.cluster_name
  cluster_security_group_description = "EKS cluster security group."
  ###############################################################################################

  # aws_auth_accounts                          = var.map_additional_aws_accounts
  aws_auth_roles = local.role_bindings
  # aws_auth_users                             = var.map_additional_iam_users
  cluster_name                               = var.cluster_name
  cluster_version                            = var.cluster_version
  create_cluster_primary_security_group_tags = false
  cluster_endpoint_private_access            = true # Always set to true here, which enables private networking for the node groups
  cluster_endpoint_public_access             = var.disable_public_eks_endpoint ? false : true
  cluster_endpoint_public_access_cidrs       = var.allowed_public_cidrs
  cluster_enabled_log_types                  = var.cluster_enabled_log_types
  control_plane_subnet_ids                   = local.cluster_subnet_ids
  create_cloudwatch_log_group                = false
  create_iam_role                            = var.use_runtime_policy ? false : true
  eks_managed_node_groups                    = local.node_groups
  eks_managed_node_group_defaults            = local.node_group_defaults
  enable_irsa                                = true
  iam_role_arn                               = var.use_runtime_policy ? aws_iam_role.cluster[0].arn : null
  iam_role_path                              = var.iam_path
  iam_role_permissions_boundary              = var.permissions_boundary_arn
  manage_aws_auth_configmap                  = true
  openid_connect_audiences                   = ["sts.amazonaws.com"]
  tags                                       = local.tags
  vpc_id                                     = var.vpc_id
}

### Additional Tags
module "vpc_tags" {
  source = "./modules/eks-vpc-tags"
  count  = var.add_vpc_tags ? 1 : 0

  cluster_name       = var.cluster_name
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
}

resource "aws_ec2_tag" "cluster_security_group" {
  resource_id = module.eks.cluster_primary_security_group_id
  key         = "Vendor"
  value       = "StreamNative"
}

### Kubernetes Configurations
resource "kubernetes_namespace" "sn_system" {
  metadata {
    name = "sn-system"

    labels = {
      "istio.io/rev" = var.istio_revision_tag
    }
  }
  depends_on = [
    module.eks
  ]
}

resource "kubernetes_storage_class" "sn_default" {
  metadata {
    name = "sn-default"
  }
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = local.kms_key
  }
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

resource "kubernetes_storage_class" "sn_ssd" {
  metadata {
    name = "sn-ssd"
  }
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = local.kms_key
  }
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

### Cluster IAM Role
data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  count                = var.use_runtime_policy ? 1 : 0
  name                 = format("%s-cluster-role", var.cluster_name)
  description          = format("The IAM Role used by the %s EKS cluster", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.cluster_assume_role_policy.json
  tags                 = local.tags
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  count      = var.use_runtime_policy ? 1 : 0
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  count      = var.use_runtime_policy ? 1 : 0
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceControllerPolicy" {
  count      = var.use_runtime_policy ? 1 : 0
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[0].name
}

### Node Group IAM Role
data "aws_iam_policy_document" "ng_assume_role_policy" {
  statement {
    sid = "EKSNodeAssumeRole"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ng" {
  name                 = format("%s-ng-role", var.cluster_name)
  description          = format("The IAM Role used by the %s EKS cluster's worker nodes", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.ng_assume_role_policy.json
  tags                 = local.tags
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_role_policy_attachment" "ng_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.ng.name
}

resource "aws_iam_role_policy_attachment" "ng_AmazonEKSServicePolicy" {
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ng.name
}

resource "aws_iam_role_policy_attachment" "ng_AmazonEKSVPCResourceControllerPolicy" {
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.ng.name
}