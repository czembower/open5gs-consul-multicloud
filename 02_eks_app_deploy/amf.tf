resource "kubernetes_namespace" "free5gc_amf" {
  metadata {
    annotations = {
      name = "free5gc-amf"
    }
    name = "free5gc-amf"
  }
}


resource "helm_release" "free5gc_amf" {
  name       = "towards5gs"
  namespace  = kubernetes_namespace.free5gc_amf.metadata[0].name
  repository = "https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/"
  chart      = "free5gc-amf"

  set {
    name  = "amf.image.tag"
    value = "latest"
  }
}
