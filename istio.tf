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

locals {
  lb_annotations = {
    internet_facing = {
      "service.beta.kubernetes.io/aws-load-balancer-scheme"                   = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-type"                     = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Vendor=StreamNative"
    },
    internal_only = {
      "service.beta.kubernetes.io/aws-load-balancer-internal" : "true"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"                   = "internal"
      "service.beta.kubernetes.io/aws-load-balancer-type"                     = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Vendor=StreamNative"
    }
  }
}

module "istio" {
  count = var.enable_bootstrap ? 1 : 0
  source = "github.com/streamnative/terraform-helm-charts//modules/istio-operator?ref=v0.8.4"

  enable_istio_operator = true
  enable_kiali_operator = true

  istio_cluster_name              = module.eks.cluster_id
  istio_network                   = var.istio_network
  istio_profile                   = var.istio_profile
  istio_revision_tag              = var.istio_revision_tag
  istio_mesh_id                   = var.istio_mesh_id
  istio_trust_domain              = var.istio_trust_domain
  istio_gateway_certificate_name  = "istio-ingressgateway-tls"
  istio_gateway_certificate_hosts = ["*.${var.service_domain}"]
  istio_gateway_certificate_issuer = {
    group = "cert-manager.io"
    kind  = "ClusterIssuer"
    name  = "external"
  }
  istio_settings = var.istio_settings

  istio_ingress_gateway_service_annotations = var.disable_public_pulsar_endpoint ? local.lb_annotations.internal_only : local.lb_annotations.internet_facing
  kiali_gateway_hosts                       = ["kiali.${var.service_domain}"]
  kiali_gateway_tls_secret                  = "istio-ingressgateway-tls"
  kiali_operator_settings                   = var.kiali_operator_settings

  depends_on = [
    helm_release.cert_issuer,
    helm_release.aws_load_balancer_controller
  ]
}
