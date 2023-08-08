resource "kubernetes_namespace" "free5gc_nrf" {
  metadata {
    annotations = {
      name = "free5gc-nrf"
    }
    name = "free5gc-nrf"
  }
}


resource "helm_release" "free5gc_nrf" {
  name       = "towards5gs"
  namespace  = kubernetes_namespace.free5gc_nrf.metadata[0].name
  repository = "https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/"
  chart      = "free5gc-nrf"

  set {
    name  = "nrf.image.tag"
    value = "latest"
  }
}
