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
  account_id               = data.aws_caller_identity.current.account_id
  cluster_subnet_ids       = concat(var.private_subnet_ids, var.public_subnet_ids)
  istio_namespace          = var.istio_namespace == "istio-system" ? "istio-system" : var.istio_namespace
  istio_operator_namespace = var.istio_operator_namespace == "istio-operator" ? "istio-operator" : var.istio_operator_namespace
  oidc_issuer              = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")

  ### Node Groups
  func_pool_config = {
    desired_capacity = coalesce(var.func_pool_desired_size, var.node_pool_desired_size)
    disk_size        = var.func_pool_disk_size
    instance_types   = coalesce(var.func_pool_instance_types, var.node_pool_instance_types)
    min_capacity     = coalesce(var.func_pool_min_size, var.node_pool_min_size)
    max_capacity     = coalesce(var.func_pool_max_size, var.node_pool_max_size)
    name             = "snc-func-pool"
  }

  node_pool_config = {
    desired_capacity = var.node_pool_desired_size
    disk_size        = var.node_pool_disk_size
    instance_types   = var.node_pool_instance_types
    min_capacity     = var.node_pool_min_size
    max_capacity     = var.node_pool_max_size
    name             = "snc-node-pool"
  }

  node_groups = var.enable_func_pool ? { "snc-node-pool" = local.node_pool_config, "snc-func-pool" = local.func_pool_config } : { "snc-node-pool" = local.node_pool_config }
}
