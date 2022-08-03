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

data "aws_subnet" "private_cidrs" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

locals {
  account_id           = data.aws_caller_identity.current.account_id
  cluster_subnet_ids   = concat(var.private_subnet_ids, var.public_subnet_ids)
  oidc_issuer          = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
  private_subnet_cidrs = var.enable_node_group_private_networking == false ? [] : [for i, v in var.private_subnet_ids : data.aws_subnet.private_cidrs[i].cidr_block]

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


  func_pool_defaults = {
    ami_id               = var.func_pool_ami_id
    ami_is_eks_optimized = var.func_pool_ami_is_eks_optimized
    enable_monintoring   = var.enable_func_pool_monitoring
    desired_capacity     = var.func_pool_desired_size
    disk_size            = var.func_pool_disk_size
    disk_type            = var.func_pool_disk_type
    instance_types       = var.func_pool_instance_types
    k8s_labels           = merge(var.func_pool_labels, { NodeGroup = "functions" })
    min_capacity         = var.func_pool_min_size
    max_capacity         = var.func_pool_max_size
    pre_userdata         = var.func_pool_pre_userdata
    taints = [{
      key    = "reserveGroup"
      value  = "functions"
      effect = "NO_SCHEDULE"
    }]
  }

  node_pool_defaults = {
    ami_id               = var.node_pool_ami_id
    ami_is_eks_optimized = var.node_pool_ami_is_eks_optimized
    enable_monintoring   = var.enable_node_pool_monitoring
    desired_capacity     = var.node_pool_desired_size
    disk_size            = var.node_pool_disk_size
    disk_type            = var.node_pool_disk_type
    instance_types       = var.node_pool_instance_types
    k8s_labels           = var.node_pool_labels
    min_capacity         = var.node_pool_min_size
    max_capacity         = var.node_pool_max_size
    pre_userdata         = var.node_pool_pre_userdata
    taints               = []
  }

  snc_node_config       = { for i, v in var.private_subnet_ids : "snc-node-pool${i}" => merge(local.node_pool_defaults, { subnets = [var.private_subnet_ids[i]], name = "snc-node-pool${i}" }) }
  snc_extra_node_config = (length(var.extra_node_pool_instance_types) == 0 ? {} : { for i, v in var.private_subnet_ids : "snc-extra-node-pool${i}" => merge(local.node_pool_defaults, { subnets = [var.private_subnet_ids[i]], name = "snc-extra-node-pool${i}", instance_types = var.extra_node_pool_instance_types }) })
  snc_func_config       = { for i, v in var.private_subnet_ids : "snc-func-pool${i}" => merge(local.func_pool_defaults, { subnets = [var.private_subnet_ids[i]], name = "snc-func-pool${i}" }) }
  node_groups           = (var.enable_func_pool ? merge(local.snc_node_config, local.snc_func_config, local.snc_extra_node_config) : merge(local.snc_node_config, local.snc_extra_node_config))
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.24.0"

  cluster_name                                   = var.cluster_name
  cluster_version                                = var.cluster_version
  cluster_create_endpoint_private_access_sg_rule = var.enable_node_group_private_networking
  cluster_endpoint_private_access                = var.enable_node_group_private_networking
  cluster_endpoint_private_access_cidrs          = local.private_subnet_cidrs
  cluster_endpoint_public_access_cidrs           = var.allowed_public_cidrs
  cluster_enabled_log_types                      = var.cluster_enabled_log_types
  cluster_iam_role_name                          = var.use_runtime_policy ? aws_iam_role.cluster[0].name : ""
  cluster_log_kms_key_id                         = var.cluster_log_kms_key_id
  cluster_log_retention_in_days                  = var.cluster_log_retention_in_days
  enable_irsa                                    = true
  openid_connect_audiences                       = ["sts.amazonaws.com"]
  iam_path                                       = "/StreamNative/"
  manage_cluster_iam_resources                   = var.use_runtime_policy ? false : true
  manage_worker_iam_resources                    = true
  map_accounts                                   = var.map_additional_aws_accounts
  map_roles                                      = var.map_additional_iam_roles
  map_users                                      = var.map_additional_iam_users
  permissions_boundary                           = var.permissions_boundary_arn
  subnets                                        = local.cluster_subnet_ids
  vpc_id                                         = var.vpc_id
  wait_for_cluster_timeout                       = var.wait_for_cluster_timeout // This was added in version 17.1.0, and if set above 0, causes TF to crash.
  write_kubeconfig                               = false

  node_groups = local.node_groups

  node_groups_defaults = {
    additional_tags = merge({
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      format("k8s.io/cluster-autoscaler/%s", var.cluster_name) = "owned",
      "Vendor"                                                 = "StreamNative"
      },
    )
    create_launch_template = true
    disk_encrypted         = true
    disk_kms_key_id        = local.kms_key # sourced from csi.tf -> locals{}
  }

  tags = {
    format("k8s.io/cluster/%s", var.cluster_name) = "owned",
    "Vendor"                                      = "StreamNative"
  }

  depends_on = [
    aws_iam_role.cluster
  ]
}

resource "aws_autoscaling_group_tag" "asg_group_vendor_tags" {
  count = length(module.eks.workers_asg_names)

  autoscaling_group_name = module.eks.workers_asg_names[count.index]

  tag {
    key   = "Vendor"
    value = "StreamNative"

    propagate_at_launch = true
  }
}

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
