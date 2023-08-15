resource "kubernetes_namespace" "vault" {
  metadata {
    annotations = {
      name = "vault"
    }
    name = "vault"
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"

  set {
    name  = "server.enabled"
    value = false
  }

  set {
    name  = "injector.enabled"
    value = true
  }

  set {
    name  = "injector.replicas"
    value = 2
  }

  set {
    name  = "global.externalVaultAddr"
    value = hcp_vault_cluster.aws_vault.vault_private_endpoint_url
  }
}
