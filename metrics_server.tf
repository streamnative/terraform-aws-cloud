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

resource "helm_release" "metrics_server" {
  count           = var.enable_bootstrap ? 1 : 0
  atomic          = true
  chart           = var.metrics_server_helm_chart_name
  cleanup_on_fail = true
  name            = "metrics-server"
  namespace       = "kube-system"
  repository      = var.metrics_server_helm_chart_repository
  timeout         = 300
  version         = var.metrics_server_helm_chart_version
  values = [yamlencode({
    replicas = 2
    }
  )]

  dynamic "set" {
    for_each = var.metrics_server_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.eks
  ]
}