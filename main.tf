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

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

data "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
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
  ebs_kms_key                = var.disk_encryption_kms_key_arn == "" ? data.aws_kms_key.ebs_default.arn : var.disk_encryption_kms_key_arn
  oidc_issuer                = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")

  nodes_available_subnets = var.enable_nodes_use_public_subnet ? data.aws_subnet.public_subnets : data.aws_subnet.private_subnets
  node_group_subnets = length(var.node_pool_azs) != 0 ? [
    for index, subnet in local.nodes_available_subnets : subnet if contains(var.node_pool_azs, subnet.availability_zone)
  ] : local.nodes_available_subnets
  node_group_subnet_ids = [for index, subnet in local.node_group_subnets : subnet.id]

  tags = merge(
    {
      "Vendor"       = "StreamNative"
      "cluster-name" = var.cluster_name
    },
    var.additional_tags,
  )

  ## Node Group Configuration
  compute_units = {
    "large"   = "Small"
    "xlarge"  = "Medium"
    "2xlarge" = "Medium"
    "4xlarge" = "Large"
    "8xlarge" = "Large"
  }

  v3_compute_units = {
    "large" = "Small"
  }

  computed_node_taints = {}

  node_pool_taints        = merge(var.node_pool_taints, local.computed_node_taints)
  node_group_iam_role_arn = replace(aws_iam_role.ng.arn, replace(var.iam_path, "/^//", ""), "") # Work around for https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/153

  node_group_defaults = {
    create_security_group = false
    ami_id                = var.node_pool_ami_id
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = var.node_pool_disk_size
          volume_type           = "gp3"
          iops                  = var.node_pool_disk_iops
          encrypted             = true
          kms_key_id            = local.ebs_kms_key
          delete_on_termination = true
        }
      }
    }
    update_config = {
      max_unavailable = 1
    }
    create_iam_role         = false # We create the IAM role ourselves to reduce complexity in managing the aws-auth configmap
    iam_role_arn            = local.node_group_iam_role_arn
    create_launch_template  = true
    desired_size            = var.node_pool_desired_size
    ebs_optimized           = var.node_pool_ebs_optimized
    enable_monitoring       = var.enable_node_pool_monitoring
    min_size                = var.node_pool_min_size
    max_size                = var.node_pool_max_size
    pre_bootstrap_user_data = var.node_pool_pre_userdata
    taints                  = local.node_pool_taints
    tags = merge(var.node_pool_tags, local.tags, {
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      format("k8s.io/cluster-autoscaler/%s", var.cluster_name) = "owned",
      "cluster-name"                                           = var.cluster_name
    })
  }

  ## Create the node groups, one for each instance type AND each availability zone/subnet
  v2_node_groups = {
    for node_group in flatten([
      for instance_type in var.node_pool_instance_types : [
        for i, j in data.aws_subnet.private_subnets : {
          subnet_ids      = [data.aws_subnet.private_subnets[i].id]
          instance_types  = [instance_type]
          name            = "snc-${split(".", instance_type)[1]}-${data.aws_subnet.private_subnets[i].availability_zone}"
          use_name_prefix = true
          taints          = {}
          desired_size    = var.node_pool_desired_size
          min_size        = var.node_pool_min_size
          max_size        = var.node_pool_max_size
          labels          = tomap(merge(var.node_pool_labels, { "cloud.streamnative.io/instance-type" = lookup(local.compute_units, split(".", instance_type)[1], "null") }))
        }
      ]
    ]) : "${node_group.name}" => node_group
  }

  v3_node_taints = var.enable_v3_node_taints ? {
    "core" = {
      key    = "node.cloud.streamnative.io/core"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  } : {}

  v3_node_groups = {
    "snc-core" = {
      subnet_ids      = local.node_group_subnet_ids
      instance_types  = [var.v3_node_group_core_instance_type]
      name            = "snc-core"
      use_name_prefix = true
      taints          = local.v3_node_taints
      desired_size    = var.node_pool_desired_size
      min_size        = var.node_pool_min_size
      max_size        = var.node_pool_max_size
      labels = tomap(merge(var.node_pool_labels, {
        "cloud.streamnative.io/instance-type"  = "Small"
        "cloud.streamnative.io/instance-group" = "Core"
      }))
    }
  }

  node_groups = var.enable_v3_node_migration ? merge(local.v3_node_groups, local.v2_node_groups) : var.enable_v3_node_groups ? local.v3_node_groups : local.v2_node_groups
  defaulted_node_groups = var.node_groups != null ? {
    for k, v in var.node_groups : k => merge(
      v,
      contains(keys(v), "subnet_ids") ? {} : { "subnet_ids" = local.node_group_subnet_ids },
    )
  } : {}
  eks_managed_node_groups = [local.defaulted_node_groups, local.node_groups][var.node_groups != null ? 0 : 1]

  ## Node Security Group Configuration
  default_sg_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    ingress_cluster = {
      description              = "Allow workers pods to receive communication from the cluster control plane."
      protocol                 = "tcp"
      source_security_group_id = module.eks.cluster_security_group_id
      from_port                = 1025
      to_port                  = 65535
      type                     = "ingress"
    }
  }

  ### IAM role bindings
  sncloud_control_plane_access = [
    {
      rolearn  = format("arn:${local.aws_partition}:iam::%s:role/StreamNativeCloudBootstrapRole", local.account_id)
      username = "sn-manager:{{AccountID}}:{{SessionName}}"
      groups   = ["system:masters"]
    },
    {
      rolearn  = format("arn:${local.aws_partition}:iam::%s:role/StreamNativeCloudManagementRole", local.account_id)
      username = "sn-manager:{{AccountID}}:{{SessionName}}"
      groups   = ["system:masters"]
    }
  ]

  # Add the worker node role back in with the path so the EKS console reports healthy node status
  worker_node_role = [
    {
      rolearn  = local.node_group_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = aws_iam_role.ng.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  # Switches for different role binding scenarios
  role_bindings = var.enable_sncloud_control_plane_access && var.iam_path != "" ? concat(local.sncloud_control_plane_access, local.worker_node_role, var.map_additional_iam_roles) : var.enable_sncloud_control_plane_access && var.iam_path == "" ? concat(local.sncloud_control_plane_access, var.map_additional_iam_roles) : var.enable_sncloud_control_plane_access == false && var.iam_path != "" ? concat(var.map_additional_iam_roles, local.worker_node_role) : var.map_additional_iam_roles
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.29.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_private_access          = true # Always set to true here, which enables private networking for the node groups
  cluster_endpoint_public_access           = var.disable_public_eks_endpoint ? false : true
  cluster_endpoint_public_access_cidrs     = var.allowed_public_cidrs
  enable_irsa                              = true
  openid_connect_audiences                 = ["sts.amazonaws.com"]
  enable_cluster_creator_admin_permissions = true
  cluster_encryption_config                = var.cluster_encryption_config
  cluster_encryption_policy_path           = var.iam_path

  iam_role_arn                  = try(var.cluster_iam.iam_role_arn, aws_iam_role.cluster[0].arn, null)
  create_iam_role               = try(var.cluster_iam.create_iam_role, true)
  iam_role_use_name_prefix      = try(var.cluster_iam.iam_role_use_name_prefix, true)
  iam_role_name                 = try(var.cluster_iam.iam_role_name, substr("${var.cluster_name}-cluster", 0, 37), null)
  iam_role_path                 = try(var.cluster_iam.iam_role_path, var.iam_path, "/StreamNative/")
  iam_role_permissions_boundary = try(var.cluster_iam.iam_role_permissions_boundary, var.permissions_boundary_arn, null)

  vpc_id                                     = var.vpc_id
  control_plane_subnet_ids                   = local.cluster_subnet_ids
  cluster_service_ipv4_cidr                  = try(var.cluster_networking.cluster_service_ipv4_cidr, var.cluster_service_ipv4_cidr, null)
  cluster_security_group_id                  = try(var.cluster_networking.cluster_security_group_id, var.cluster_security_group_id, "")
  cluster_additional_security_group_ids      = try(var.cluster_networking.cluster_additional_security_group_ids, [])
  create_cluster_security_group              = try(var.cluster_networking.create_cluster_security_group, var.create_cluster_security_group, true)
  cluster_security_group_name                = try(var.cluster_networking.cluster_security_group_name, null)
  cluster_security_group_additional_rules    = try(var.cluster_networking.cluster_security_group_additional_rules, var.cluster_security_group_additional_rules, {})
  create_cluster_primary_security_group_tags = false # Cleaner if we handle the tag in aws_ec2_tag.cluster_security_group

  eks_managed_node_groups         = local.eks_managed_node_groups
  eks_managed_node_group_defaults = local.node_group_defaults

  node_security_group_id               = var.node_security_group_id
  create_node_security_group           = var.create_node_security_group
  node_security_group_additional_rules = merge(var.node_security_group_additional_rules, local.default_sg_rules)

  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = merge(var.enable_vpc_cni_prefix_delegation ? {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        } : {})
      })
    }
  }

  cluster_enabled_log_types   = var.cluster_enabled_log_types
  create_cloudwatch_log_group = false
  tags                        = local.tags
}

module "eks_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.29.0"

  manage_aws_auth_configmap = var.manage_aws_auth_configmap
  aws_auth_roles            = local.role_bindings

  depends_on = [module.eks]
}

moved {
  from = module.eks.kubernetes_config_map_v1_data.aws_auth[0]
  to   = module.eks_auth.kubernetes_config_map_v1_data.aws_auth[0]
}

### Additional Tags
module "vpc_tags" {
  source = "./modules/eks-vpc-tags"
  count  = var.add_vpc_tags ? 1 : 0

  cluster_name       = var.cluster_name
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  node_pool_azs      = var.node_pool_azs
}

resource "aws_ec2_tag" "cluster_security_group" {
  resource_id = module.eks.cluster_primary_security_group_id
  key         = "Vendor"
  value       = "StreamNative"
}

### Cluster IAM Role
data "aws_iam_policy_document" "cluster_assume_role_policy" {
  count = var.use_runtime_policy ? 1 : 0
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
  assume_role_policy   = data.aws_iam_policy_document.cluster_assume_role_policy[0].json
  tags                 = local.tags
  path                 = var.iam_path
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
  path                 = var.iam_path
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

