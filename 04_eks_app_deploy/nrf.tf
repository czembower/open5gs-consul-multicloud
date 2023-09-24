resource "kubernetes_namespace" "free5gc_nrf" {
  metadata {
    annotations = {
      name = "free5gc-nrf"
    }
    name = "free5gc-nrf"
  }
}

resource "helm_release" "free5gc_nrf" {
  name       = "nrf"
  namespace  = kubernetes_namespace.free5gc_nrf.metadata[0].name
  repository = "https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/"
  chart      = "free5gc-nrf"

  depends_on = [
    helm_release.consul
  ]

  values = [<<EOT
  nrf:
    podAnnotations:
      "consul.hashicorp.com/connect-inject: true"
  EOT
  ]

  set {
    name  = "nrf.image.tag"
    value = "latest"
  }
}
