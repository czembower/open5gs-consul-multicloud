// cowboysysop https://cowboysysop.github.io/charts/

resource "helm_release" "vpa" {
  name       = "vpa"
  namespace  = "kube-system"
  repository = "https://cowboysysop.github.io/charts/"
  chart      = "vertical-pod-autoscaler"

  depends_on = [
    helm_release.metrics_server
  ]
}
