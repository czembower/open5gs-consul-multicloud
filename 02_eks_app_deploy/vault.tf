resource "kubernetes_namespace" "vault" {
  metadata {
    annotations = {
      name = "vault"
    }
    name = "vault"
  }
}
