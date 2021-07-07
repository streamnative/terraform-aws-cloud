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

module "function_mesh_operator" {
  count  = var.enable_function_mesh_operator ? 1 : 0
  source = "./modules/function-mesh-operator"

  namespace = kubernetes_namespace.sn_system.id
}

module "olm" {
  count  = var.enable_olm ? 1 : 0
  source = "./modules/operator-lifecycle-manager"

  depends_on = [
    kubernetes_namespace.sn_system
  ]
}

module "olm_subscriptions" {
  count  = var.enable_olm && var.enable_olm_subscriptions ? 1 : 0
  source = "./modules/olm-subscriptions"

  namespace = "olm"

  depends_on = [
    module.olm
  ]
}

module "pulsar_operator" {
  count  = var.enable_pulsar_operator ? 1 : 0
  source = "./modules/pulsar-operator"

  namespace = kubernetes_namespace.sn_system.id
}

module "vault_operator" {
  count  = var.enable_vault_operator ? 1 : 0
  source = "./modules/vault-operator"

  namespace = kubernetes_namespace.sn_system.id
}
