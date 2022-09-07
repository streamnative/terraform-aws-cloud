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

data "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

resource "random_id" "ng_suffix" {
  byte_length = 1
}

locals {
  account_id           = data.aws_caller_identity.current.account_id
  cluster_subnet_ids   = concat(var.private_subnet_ids, var.public_subnet_ids)
  oidc_issuer          = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
  private_subnet_cidrs = var.enable_node_group_private_networking == false ? [] : [for i, v in var.private_subnet_ids : data.aws_subnet.private_subnets[i].cidr_block]

  ## switches for roles
  default_lb_arn         = "arn:${var.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudLBPolicy"
  default_service_arn    = "arn:${var.aws_partition}:iam::${local.account_id}:policy/StreamNative/StreamNativeCloudRuntimePolicy"
  lb_policy_arn          = var.sncloud_services_lb_policy_arn != "" ? var.sncloud_services_lb_policy_arn : (var.use_runtime_policy ? local.default_lb_arn : "")
  sn_serv_policy_arn     = var.sncloud_services_iam_policy_arn != "" ? var.sncloud_services_iam_policy_arn : (var.use_runtime_policy ? local.default_service_arn : "")
  create_lb_policy       = !(var.sncloud_services_lb_policy_arn != "" || var.use_runtime_policy || !var.enable_aws_load_balancer_controller)
  create_cert_man_policy = !(var.sncloud_services_iam_policy_arn != "" || var.use_runtime_policy || !var.enable_cert_manager)
  create_ca_policy       = !(var.sncloud_services_iam_policy_arn != "" || var.use_runtime_policy || !var.enable_cluster_autoscaler)
  create_csi_policy      = !(var.sncloud_services_iam_policy_arn != "" || var.use_runtime_policy || !var.enable_csi)
  create_ext_dns_policy  = !(var.sncloud_services_iam_policy_arn != "" || var.use_runtime_policy || !var.enable_external_dns)
  create_ext_sec_policy  = !(var.sncloud_services_iam_policy_arn != "" || var.use_runtime_policy || !var.enable_external_secrets)

  ## Node Group Configuration
  node_group_defaults = {
    ami_id = var.node_pool_ami_id
    block_device_mappings = {
      xvdb = {
        device_name = var.node_pool_block_device_name 
        ebs = {
          volume_size           = var.node_pool_disk_size
          volume_type           = "gp3"
          iops                  = 3000
          encrypted             = true
          kms_key_id            = local.kms_key
          delete_on_termination = true
        }
      }
    }
    create_launch_template  = true
    enable_monitoring       = var.enable_node_pool_monitoring
    desired_size            = var.node_pool_desired_size
    labels                  = var.node_pool_labels
    min_size                = var.node_pool_min_size
    max_size                = var.node_pool_max_size
    pre_bootstrap_user_data = var.node_pool_pre_userdata
    taints                  = var.node_pool_taints
    tags = merge(var.node_pool_tags, {
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      format("k8s.io/cluster-autoscaler/%s", var.cluster_name) = "owned",
      "Vendor"                                                 = "StreamNative"
    })
  }

  ## Create the node groups, one for each instance type AND each availability zone/subnet
  node_groups = {
    for node_group in flatten([
      for instance_type in var.node_pool_instance_types : [
        for i, j in data.aws_subnet.private_subnet : {
          subnet_id     = data.aws_subnet.subnet[i].id
          instance_type = instance_type,
          name          = "snc-node-pool-${split(".", instance_type)[1]}-${data.aws_subnet.private_subnet[i].availability_zone}-${random_id.ng_suffix.hex}"
        }
      ]
    ]) : "${node_group.name}" => node_group
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0"

  # cluster_endpoint_private_access_cidrs          = local.private_subnet_cidrs
  # cluster_iam_role_name                          = var.use_runtime_policy ? aws_iam_role.cluster[0].name : ""
  # map_accounts                                   = var.map_additional_aws_accounts
  # map_roles                                      = var.map_additional_iam_roles
  # map_users                                      = var.map_additional_iam_users
  # cluster_create_endpoint_private_access_sg_rule = var.enable_node_group_private_networking
  # manage_worker_iam_resources                    = true

  ### Added these to avoid issues with the module refactor from 17.X to 18.X. Future versions of the terraform-aws-eks module may not require these to be specified.
  prefix_separator                   = ""
  iam_role_name                      = var.cluster_name
  cluster_security_group_name        = var.cluster_name
  cluster_security_group_description = "EKS cluster security group."
  ###
  cluster_name                               = var.cluster_name
  cluster_version                            = var.cluster_version
  create_cluster_primary_security_group_tags = true
  cluster_endpoint_private_access            = var.enable_node_group_private_networking
  cluster_endpoint_public_access_cidrs       = var.allowed_public_cidrs
  cluster_enabled_log_types                  = var.cluster_enabled_log_types
  cloudwatch_log_group_kms_key_id            = var.cluster_log_kms_key_id
  cloudwatch_log_group_retention_in_days     = var.cluster_log_retention_in_days
  eks_managed_node_groups                    = local.node_groups
  eks_managed_node_group_defaults            = local.node_group_defaults
  enable_irsa                                = true
  openid_connect_audiences                   = ["sts.amazonaws.com"]
  iam_role_path                              = "/StreamNative/"
  iam_role_arn                               = var.use_runtime_policy ? aws_iam_role.cluster[0].arn : null
  create_iam_role                            = var.use_runtime_policy ? false : true
  iam_role_permissions_boundary              = var.permissions_boundary_arn
  control_plane_subnet_ids                   = local.cluster_subnet_ids
  vpc_id                                     = var.vpc_id




  node_security_group_tags = merge(var.additional_tags, {
    format("k8s.io/cluster/%s", var.cluster_name) = "owned",
    "Vendor"                                      = "StreamNative",
    "kubernetes.io/cluster/${var.cluster_name}"   = null
  })

  tags = {
    format("k8s.io/cluster/%s", var.cluster_name) = "owned",
    "Vendor"                                      = "StreamNative"
  }

  cluster_tags = merge(var.additional_tags, {
    format("k8s.io/cluster/%s", var.cluster_name) = "owned",
    "Vendor"                                      = "StreamNative"
  })
  cluster_security_group_tags = merge(var.additional_tags, {
    format("k8s.io/cluster/%s", var.cluster_name) = "owned",
    "Vendor"                                      = "StreamNative"
  })

  depends_on = [
    aws_iam_role.cluster
  ]
}

# resource "aws_autoscaling_group_tag" "asg_group_vendor_tags" {
#   count = length(module.eks.workers_asg_names)

#   autoscaling_group_name = module.eks.workers_asg_names[count.index]

#   tag {
#     key   = "Vendor"
#     value = "StreamNative"

#     propagate_at_launch = true
#   }
# }

resource "kubernetes_namespace" "sn_system" {
  metadata {
    name = "sn-system"

    labels = {
      "istio.io/rev" = "sn-stable"
    }
  }
  depends_on = [
    module.eks
  ]
}

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
  tags                 = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  count      = var.use_runtime_policy ? 1 : 0
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  count      = var.use_runtime_policy ? 1 : 0
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceControllerPolicy" {
  count      = var.use_runtime_policy ? 1 : 0
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[0].name
}
