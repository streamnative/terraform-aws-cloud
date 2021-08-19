resource "kubernetes_namespace" "calico" {
  metadata {
    name = "calico-system"
  }
  depends_on = [
    module.eks
  ]
}

resource "helm_release" "calico" {
  atomic          = true
  chart           = var.calico_helm_chart_name
  cleanup_on_fail = true
  name            = "tigera-operator"
  namespace       = kubernetes_namespace.calico.id
  repository      = var.calico_helm_chart_repository
  timeout         = 120
  version         = var.calico_helm_chart_version

  set {
    name  = "installation.kubernetesProvider"
    value = "EKS"
    type  = "string"
  }

  dynamic "set" {
    for_each = var.calico_settings
    content {
      name  = set.key
      value = set.value
    }
  }
}