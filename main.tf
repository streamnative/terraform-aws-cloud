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

data "aws_kms_key" "s3_default" {
  key_id = "alias/aws/s3"
}

locals {
  s3_kms_key                 = var.s3_encryption_kms_key_arn == "" ? data.aws_kms_key.s3_default.arn : var.s3_encryption_kms_key_arn
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

  computed_node_taints = merge(
    var.enable_cilium && var.enable_cilium_taint ? {
      cilium = {
        key    = "node.cilium.io/agent-not-ready"
        value  = true
        effect = "NO_EXECUTE"
      }
    } : {}
  )

  node_pool_taints = merge(var.node_pool_taints, local.computed_node_taints)

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
    create_iam_role         = false # We create the IAM role ourselves to reduce complexity in managing the aws-auth configmap
    create_launch_template  = true
    desired_size            = var.node_pool_desired_size
    ebs_optimized           = var.node_pool_ebs_optimized
    enable_monitoring       = var.enable_node_pool_monitoring
    iam_role_arn            = replace(aws_iam_role.ng.arn, replace(var.iam_path, "/^//", ""), "") # Work around for https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/153
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
  v2_node_groups = tomap({
    for node_group in flatten([
      for instance_type in var.node_pool_instance_types : [
        for i, j in data.aws_subnet.private_subnets : {
          subnet_ids     = [data.aws_subnet.private_subnets[i].id]
          instance_types = [instance_type]
          name           = "snc-${split(".", instance_type)[1]}-${data.aws_subnet.private_subnets[i].availability_zone}"
          taints         = {}
          desired_size   = var.node_pool_desired_size
          min_size       = var.node_pool_min_size
          max_size       = var.node_pool_max_size
          labels         = tomap(merge(var.node_pool_labels, { "cloud.streamnative.io/instance-type" = lookup(local.compute_units, split(".", instance_type)[1], "null") }))
        }
      ]
    ]) : "${node_group.name}" => node_group
  })

  v3_node_taints = var.enable_v3_node_taints ? {
    "core" = {
      key    = "node.cloud.streamnative.io/core"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  } : {}

  v3_node_groups = tomap({
    "snc-core" = {
      subnet_ids     = local.node_group_subnet_ids
      instance_types = [var.v3_node_group_core_instance_type]
      name           = "snc-core"
      taints         = local.v3_node_taints
      desired_size   = var.node_pool_desired_size
      min_size       = var.node_pool_min_size
      max_size       = var.node_pool_max_size
      labels = tomap(merge(var.node_pool_labels, {
        "cloud.streamnative.io/instance-type"  = "Small"
        "cloud.streamnative.io/instance-group" = "Core"
      }))
    }
  })

  node_groups = var.enable_v3_node_migration ? merge(local.v3_node_groups, local.v2_node_groups) : var.enable_v3_node_groups ? local.v3_node_groups : local.v2_node_groups

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
      rolearn  = format("arn:${local.aws_partition}:iam::%s:role/StreamNativeCloudManagementRole", local.account_id)
      username = "sn-manager:{{AccountID}}:{{SessionName}}"
      groups   = ["system:masters"]
    }
  ]

  # Add the worker node role back in with the path so the EKS console reports healthy node status
  worker_node_role = [
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
  version = "18.30.2" #"19.6.0"

  ######################################################################################################
  ### This section takes into account the breaking changes made in v18.X of the community EKS module ###
  ### They are only applicable if migration_mode is set to true, for upgrading existing clusters     ###
  ######################################################################################################
  prefix_separator                    = var.migration_mode ? "" : "-"
  iam_role_name                       = var.migration_mode ? var.cluster_name : null
  cluster_security_group_name         = var.migration_mode ? var.cluster_name : null
  cluster_security_group_description  = var.migration_mode ? "EKS cluster security group." : "EKS cluster security group"
  node_security_group_description     = var.migration_mode ? "Security group for all nodes in the cluster." : "EKS node shared security group"
  node_security_group_use_name_prefix = var.migration_mode ? false : true
  node_security_group_name            = var.migration_mode ? var.migration_mode_node_sg_name : null
  ######################################################################################################

  aws_auth_roles                             = local.role_bindings
  cluster_name                               = var.cluster_name
  cluster_version                            = var.cluster_version
  cluster_endpoint_private_access            = true # Always set to true here, which enables private networking for the node groups
  cluster_endpoint_public_access             = var.disable_public_eks_endpoint ? false : true
  cluster_endpoint_public_access_cidrs       = var.allowed_public_cidrs
  cluster_enabled_log_types                  = var.cluster_enabled_log_types
  cluster_security_group_additional_rules    = var.cluster_security_group_additional_rules
  cluster_security_group_id                  = var.cluster_security_group_id
  control_plane_subnet_ids                   = local.cluster_subnet_ids
  create_cloudwatch_log_group                = false
  create_cluster_primary_security_group_tags = false # Cleaner if we handle the tag in aws_ec2_tag.cluster_security_group
  create_cluster_security_group              = var.create_cluster_security_group
  create_node_security_group                 = var.create_node_security_group
  create_iam_role                            = var.use_runtime_policy ? false : true
  eks_managed_node_groups                    = local.node_groups
  eks_managed_node_group_defaults            = local.node_group_defaults
  enable_irsa                                = true
  iam_role_arn                               = var.use_runtime_policy ? aws_iam_role.cluster[0].arn : null
  iam_role_path                              = var.iam_path
  iam_role_permissions_boundary              = var.permissions_boundary_arn
  manage_aws_auth_configmap                  = var.manage_aws_auth_configmap
  node_security_group_id                     = var.node_security_group_id
  node_security_group_additional_rules       = merge(var.node_security_group_additional_rules, local.default_sg_rules)
  openid_connect_audiences                   = ["sts.amazonaws.com"]
  tags                                       = local.tags
  vpc_id                                     = var.vpc_id
  cluster_service_ipv4_cidr                  = var.cluster_service_ipv4_cidr
  bootstrap_self_managed_addons              = var.bootstrap_self_managed_addons
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
  count = var.enable_resource_creation ? 1 : 0
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

moved {
  from = kubernetes_namespace.sn_system
  to   = kubernetes_namespace.sn_system[0]
}

resource "kubernetes_storage_class" "sn_default" {
  count = var.enable_resource_creation ? 1 : 0
  metadata {
    name = "sn-default"
  }
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = local.ebs_kms_key
  }
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

moved {
  from = kubernetes_storage_class.sn_default
  to   = kubernetes_storage_class.sn_default[0]
}

resource "kubernetes_storage_class" "sn_ssd" {
  count = var.enable_resource_creation ? 1 : 0
  metadata {
    name = "sn-ssd"
  }
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = local.ebs_kms_key
  }
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

moved {
  from = kubernetes_storage_class.sn_ssd
  to   = kubernetes_storage_class.sn_ssd[0]
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

