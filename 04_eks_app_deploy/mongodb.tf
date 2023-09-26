resource "kubernetes_namespace" "mongodb" {
  metadata {
    annotations = {
      name = "mongodb"
    }
    name = "mongodb"
  }
}

resource "helm_release" "mongodb_operator" {
  name       = "mongodb-operator"
  namespace  = kubernetes_namespace.mongodb.metadata[0].name
  repository = "https://mongodb.github.io/helm-charts"
  chart      = "community-operator"

  depends_on = [
    helm_release.consul
  ]



}
