resource "kubernetes_namespace" "mongodb" {
  metadata {
    annotations = {
      name = "mongodb"
    }
    name = "mongodb"
  }
}

resource "helm_release" "free5gc_nrf" {
  name       = "mongodb"
  namespace  = kubernetes_namespace.mongodb.metadata[0].name
  repository = "https://mongodb.github.io/helm-charts"
  chart      = "mongodb/community-operator"

  depends_on = [
    helm_release.consul
  ]



}
