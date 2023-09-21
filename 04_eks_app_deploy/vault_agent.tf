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
    value = data.terraform_remote_state.base.outputs.hcp_vault_aws.vault_public_endpoint_url
  }
}

# resource "helm_release" "vault_secrets_operator" {
#   name       = "vault-secrets-operator"
#   namespace  = kubernetes_namespace.vault.metadata[0].name
#   repository = "https://helm.releases.hashicorp.com"
#   chart      = "vault-secrets-operator"

#   set {
#     name  = "controller.replicas"
#     value = 2
#   }

#   set {
#     name  = "defaultVaultConnection.enabled"
#     value = "true"
#   }

#   set {
#     name  = "defaultVaultConnection.address"
#     value = data.terraform_remote_state.base.outputs.hcp_vault_aws.vault_public_endpoint_url
#   }

#   set {
#     name  = "defaultAuthMethod.enabled"
#     value = true
#   }

#   set {
#     name  = "defaultAuthMethod.namespace"
#     value = "admin"
#   }

#   set {
#     name  = "defaultAuthMethod.method"
#     value = "jwt"
#   }

#   set {
#     name  = "defaultAuthMethod.mount"
#     value = "jwt"
#   }

#   set {
#     name  = "defaultAuthMethod.jwt.role"
#     value = "default"
#   }

#   set {
#     name  = "defaultAuthMethod.jwt.serviceAccount"
#     value = "default"
#   }
# }
