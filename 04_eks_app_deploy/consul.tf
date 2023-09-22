resource "kubernetes_namespace" "consul" {
  metadata {
    annotations = {
      name = "consul"
    }
    name = "consul"
  }
}

resource "helm_release" "consul" {
  name       = "consul"
  namespace  = kubernetes_namespace.consul.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"

  depends_on = [
    vault_jwt_auth_backend_role.consul
  ]

  set {
    name  = "global.datacenter"
    value = "aws-${var.aws_region}"
  }

  set {
    name  = "server.enabled"
    value = true
  }

  set {
    name  = "server.replicas"
    value = 3
  }

  set {
    name  = "client.enabled"
    value = true
  }

  set {
    name  = "dns.enabled"
    value = true
  }

  set {
    name  = "global.secretsBackend.vault.enabled"
    value = true
  }

  set {
    name  = "global.secretsBackend.vault.agentAnnotations\\.vault\\.hashicorp\\.com/auth-config-path"
    value = "/var/run/secrets/kubernetes.io/serviceaccount/token"
  }

  set {
    name  = "global.secretsBackend.vault.vaultNamespace"
    value = "admin/consul"
  }

  set {
    name  = "global.secretsBackend.vault.consulServerRole"
    value = "consul"
  }

  set {
    name  = "global.secretsBackend.vault.consulClientRole"
    value = "consul"
  }

  set {
    name  = "global.secretsBackend.vault.manageSystemACLsRole"
    value = "consul"
  }

  set {
    name  = "global.secretsBackend.vault.consulCARole"
    value = "consul"
  }

  set {
    name  = "global.tls.enabled"
    value = true
  }

  set {
    name  = "global.tls.enableAutoEncrypt"
    value = true
  }

  set {
    name  = "global.tls.caCert.secretName"
    value = "consul-root/cert/ca"
  }

  set {
    name  = "server.serverCert.secretName"
    value = "consul-intermediate/issue/consul"
  }
}
