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
    configuration:
      configuration: |-
        MongoDBUrl: mongodb://my-user:<your-password-here>@mongodb.mongodb:27017
  EOT
  ]

  set {
    name  = "db.enabled"
    value = false
  }

  set {
    name  = "mongodb.service.name"
    value = "mongodb.mongodb"
  }

  set {
    name  = "nrf.image.tag"
    value = "latest"
  }

  set {
    name  = "nrf.replicaCount"
    value = 2
  }

  set {
    name  = "nrf.podAnnotations.consul\\.hashicorp\\.com/connect-inject"
    value = "true"
    type  = "string"
  }
}
