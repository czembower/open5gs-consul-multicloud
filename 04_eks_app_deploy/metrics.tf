// metrics-server https://kubernetes-sigs.github.io/metrics-server/

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
}

resource "helm_release" "prometheus" {
  name       = "prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
}

# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo update
# helm upgrade \
#   --install prometheus-stack prometheus-community/kube-prometheus-stack \
#   --namespace monitoring \
#   --create-namespace
