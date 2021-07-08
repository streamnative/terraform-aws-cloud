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
  count  = var.enable_function_mesh_operator && var.disable_olm ? 1 : 0
  source = "./modules/function-mesh-operator"

  chart_name       = var.function_mesh_operator_chart_name
  chart_repository = var.function_mesh_operator_chart_repository
  chart_version    = var.function_mesh_operator_chart_version
  cleanup_on_fail  = var.function_mesh_operator_cleanup_on_fail
  namespace        = kubernetes_namespace.sn_system.id
  release_name     = var.function_mesh_operator_release_name
  settings         = var.function_mesh_operator_settings
  timeout          = var.function_mesh_operator_timeout
}

module "olm" {
  count  = var.disable_olm ? 0 : 1
  source = "./modules/operator-lifecycle-manager"

  olm_namespace           = var.olm_namespace
  olm_operators_namespace = var.olm_operators_namespace
  settings                = var.olm_settings

  depends_on = [
    kubernetes_namespace.sn_system
  ]
}

module "olm_subscriptions" {
  count  = var.disable_olm ? 0 : 1
  source = "./modules/olm-subscriptions"

  catalog_namespace = var.olm_namespace
  namespace         = kubernetes_namespace.sn_system.id
  settings          = merge(var.olm_subscription_settings, { "components.vault" = "false" }) // Note: the vault subscription isn't working, so we're opting for a helm install instead

  depends_on = [
    module.olm
  ]
}

module "prometheus_operator" {
  count  = var.enable_prometheus_operator && var.disable_olm ? 1 : 0
  source = "./modules/prometheus-operator"

  chart_name       = var.prometheus_operator_chart_name
  chart_repository = var.prometheus_operator_chart_repository
  chart_version    = var.prometheus_operator_chart_version
  cleanup_on_fail  = var.prometheus_operator_cleanup_on_fail
  namespace        = kubernetes_namespace.sn_system.id
  release_name     = var.prometheus_operator_release_name
  settings         = var.prometheus_operator_settings
  timeout          = var.prometheus_operator_timeout
}

module "pulsar_operator" {
  count  = var.enable_pulsar_operator && var.disable_olm ? 1 : 0
  source = "./modules/pulsar-operator"

  chart_name       = var.pulsar_operator_chart_name
  chart_repository = var.pulsar_operator_chart_repository
  chart_version    = var.pulsar_operator_chart_version
  cleanup_on_fail  = var.pulsar_operator_cleanup_on_fail
  namespace        = kubernetes_namespace.sn_system.id
  release_name     = var.pulsar_operator_release_name
  settings         = var.pulsar_operator_settings
  timeout          = var.pulsar_operator_timeout
}

module "vault_operator" {
  count  = var.enable_vault ? 1 : 0
  source = "./modules/vault-operator"

  chart_name       = var.vault_operator_chart_name
  chart_repository = var.vault_operator_chart_repository
  chart_version    = var.vault_operator_chart_version
  cleanup_on_fail  = var.vault_operator_cleanup_on_fail
  namespace        = kubernetes_namespace.sn_system.id
  release_name     = var.vault_operator_release_name
  settings         = var.vault_operator_settings
  timeout          = var.vault_operator_timeout
}
