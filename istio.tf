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

# We install the istio control plane in the sn-system namespace, but this will optionally enable use of istio-system, which is convention
resource "kubernetes_namespace" "istio_system" {
  count = var.enable_istio_operator && var.istio_namespace == "istio-system" ? 1 : 0
  metadata {
    name = "istio-system"
  }
}

# The istio operator is conventionally installed installed in the istio-operator namespace, but can optionally be overridden
resource "kubernetes_namespace" "istio_operator" {
  count = var.enable_istio_operator ? 1 : 0
  metadata {
    name = var.istio_operator_namespace
    labels = {
      "istio-operator-managed" = "Reconcile"
      "istio-injection"        = "disabled"
    }
  }
}

resource "helm_release" "istio_operator" {
  count           = var.enable_istio_operator ? 1 : 0
  atomic          = true
  chart           = "${path.module}/charts/istio-operator" #var.istio_operator_chart_name
  cleanup_on_fail = true
  name            = "istio-operator"
  namespace       = kubernetes_namespace.istio_operator[0].metadata[0].name
  timeout         = 200
  # repository      = var.istio_operator_chart_repository
  # version         = var.istio_operator_chart_version

  values = [yamlencode({
    "istioNamespace" : "${var.istio_namespace}",
    "controlPlane" : {
      "install" : true,
      "spec" : {
        "namespace" : "${var.istio_namespace}",
        "profile" : "${var.istio_profile}",
        "revision" : "${var.istio_revision_tag}",
        "values" : {
          "global" : {
            "istioNamespace" : "${var.istio_namespace}",
            "meshID" : "${var.istio_mesh_id}",
            "multiCluster" : {
              "clusterName" : "${module.eks.cluster_id}"
            },
            "network" : "${var.istio_network}"
          }
        },
        "meshConfig" : {
          "trustDomain" : "${var.istio_trust_domain}",
          "defaultConfig" : {
            "proxyMetadata" : {
              "ISTIO_META_DNS_CAPTURE" : "true",
              "ISTIO_META_DNS_AUTO_ALLOCATE" : "true"
            }
          }
        },
        "components" : {
          "cni" : {
            "enabled" : true
          },
          "ingressGateways" : [
            {
              "name" : "istio-ingressgateway",
              "namespace" : "${local.istio_namespace}",
              "enabled" : true,
              "label" : {
                "cloud.streamnative.io/role" : "istio-gateway",
                "istio" : "ingressgateway"
              },
              "k8s" : {
                "service" : {
                  "ports" : [
                    {
                      "port" : 15021,
                      "targetPort" : 15021,
                      "name" : "status-port"
                    },
                    {
                      "port" : 80,
                      "targetPort" : 8080,
                      "name" : "http2"
                    },
                    {
                      "port" : 443,
                      "targetPort" : 8443,
                      "name" : "https"
                    },
                    {
                      "port" : 6651,
                      "targetPort" : 6651,
                      "name" : "tls-pulsar"
                    },
                    {
                      "port" : 9093,
                      "targetPort" : 9093,
                      "name" : "tls-kafka"
                    }
                  ]
                }
              }
            }
          ]
        }
      }
    }
  })]

  dynamic "set" {
    for_each = var.istio_operator_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_namespace.sn_system
  ]
}

resource "helm_release" "kiali_operator" {
  count           = var.enable_istio_operator == true || var.enable_kiali_operator ? 1 : 0
  atomic          = true
  chart           = var.kiali_operator_chart_name
  cleanup_on_fail = true
  name            = "kiali-operator"
  namespace       = var.kiali_operator_namespace
  repository      = var.kiali_operator_chart_repository
  timeout         = 200
  version         = var.kiali_operator_chart_version

  set {
    name  = "cr.create"
    value = "true"
  }

  set {
    name  = "cr.namespace"
    value = var.kiali_operator_namespace
  }

  dynamic "set" {
    for_each = var.kiali_operator_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_namespace.sn_system
  ]
}
