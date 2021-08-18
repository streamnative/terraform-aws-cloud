resource "helm_release" "node_termination_handler" {
  atomic          = true
  chart           = var.node_termination_handler_helm_chart_name
  cleanup_on_fail = true
  name            = "node-termination-handler"
  namespace       = "kube-system"
  repository      = var.node_termination_handler_helm_chart_repository
  timeout         = 300

  dynamic "set" {
    for_each = var.node_termination_handler_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.eks
  ]
}