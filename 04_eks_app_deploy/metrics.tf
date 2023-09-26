// metrics-server https://kubernetes-sigs.github.io/metrics-server/

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server/metrics-server"
}
