resource "kubernetes_namespace" "free5gc_udr" {
  metadata {
    annotations = {
      name = "free5gc-udr"
    }
    name = "free5gc-udr"
  }
}


resource "helm_release" "free5gc_udr" {
  name       = "towards5gs"
  namespace  = kubernetes_namespace.free5gc_udr.metadata[0].name
  repository = "https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/"
  chart      = "free5gc-udr"

  set {
    name  = "udr.image.tag"
    value = "latest"
  }
}
