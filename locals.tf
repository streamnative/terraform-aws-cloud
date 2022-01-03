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

locals {
  account_id         = data.aws_caller_identity.current.account_id
  cluster_subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)
  oidc_issuer        = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")

  k8s_to_autoscaler_version = {
    "1.18" = "v1.18.3",
    "1.19" = "v1.19.2",
    "1.20" = "v1.20.1",
    "1.21" = "v1.21.1",
    "1.22" = "v1.22.1",
  }

  ### Istio Config
  default_sources = ["service", "ingress"]
  istio_sources   = ["istio-gateway", "istio-virtualservice"]
  sources         = var.enable_istio ? concat(local.istio_sources, local.default_sources) : local.default_sources

  ### Node Groups
  func_pool_defaults = {
    desired_capacity = coalesce(var.func_pool_desired_size, var.node_pool_desired_size)
    disk_size        = var.func_pool_disk_size
    instance_types   = coalesce(var.func_pool_instance_types, var.node_pool_instance_types)
    k8s_labels       = { NodeGroup = "functions" }
    min_capacity     = coalesce(var.func_pool_min_size, var.node_pool_min_size)
    max_capacity     = coalesce(var.func_pool_max_size, var.node_pool_max_size)
    taints           = ["reserveGroup=functions:NoSchedule"]
  }

  node_pool_defaults = {
    desired_capacity = var.node_pool_desired_size
    disk_size        = var.node_pool_disk_size
    instance_types   = var.node_pool_instance_types
    k8s_labels       = {}
    min_capacity     = var.node_pool_min_size
    max_capacity     = var.node_pool_max_size
    taints           = []
  }

  snc_node_config = { for i, v in var.private_subnet_ids : "snc-node-pool${i}" => merge(local.node_pool_defaults, { subnet = var.private_subnet_ids[i], name = "snc-node-pool${i}" }) }

  snc_func_config = { for i, v in var.private_subnet_ids : "snc-func-pool${i}" => merge(local.func_pool_defaults, { subnet = var.private_subnet_ids[i], name = "snc-func-pool${i}" }) }

  node_groups = (var.enable_func_pool ? merge(local.snc_node_config, local.snc_func_config) : local.snc_node_config)
}
