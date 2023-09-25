resource "kubernetes_namespace" "free5gc_udr" {
  metadata {
    annotations = {
      name = "free5gc-udr"
    }
    name = "free5gc-udr"
  }
}

resource "helm_release" "free5gc_udr" {
  name       = "udr"
  namespace  = kubernetes_namespace.free5gc_udr.metadata[0].name
  repository = "https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/"
  chart      = "free5gc-udr"

  depends_on = [
    helm_release.consul,
    helm_release.free5gc_nrf
  ]

  set {
    name  = "udr.image.tag"
    value = "latest"
  }

  set {
    name  = "global.nrf.service.name"
    value = "nrf-nnrf.${kubernetes_namespace.free5gc_nrf.metadata[0].name}.svc.cluster.local"
  }

  set {
    name  = "udr.podAnnotations.consul\\.hashicorp\\.com/connect-inject"
    value = "true"
    type  = "string"
  }

  set {
    name  = "initContainers"
    value = null
  }
}
