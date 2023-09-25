resource "kubernetes_namespace" "consul" {
  metadata {
    annotations = {
      name = "consul"
    }
    name = "consul"
  }
}

resource "kubernetes_secret_v1" "consul_hcp_client_id" {
  metadata {
    name      = "consul-hcp-client-id"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  data = {
    client-id = var.hcp_client_id
  }

  type = "opaque"
}

resource "kubernetes_secret_v1" "consul_hcp_client_secret" {
  metadata {
    name      = "consul-hcp-client-secret"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  data = {
    client-secret = var.hcp_client_id
  }

  type = "opaque"
}

resource "kubernetes_secret_v1" "consul_hcp_resource_id" {
  metadata {
    name      = "consul-hcp-resource-id"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  data = {
    resource-id = var.consul_hcp_resource_id
  }

  type = "opaque"
}

resource "helm_release" "consul" {
  name       = "consul"
  namespace  = kubernetes_namespace.consul.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"

  depends_on = [
    helm_release.vault,
    vault_jwt_auth_backend_role.consul,
    vault_jwt_auth_backend.this
  ]

  values = [<<EOT
  global:
    secretsBackend:
      vault:
        agentAnnotations: |
          vault.hashicorp.com/auth-config-path: /var/run/secrets/kubernetes.io/serviceaccount/token
          vault.hashicorp.com/auth-config-remove_jwt_after_reading: "false"
          vault.hashicorp.com/auth-type: "jwt"
          vault.hashicorp.com/auth-path: "auth/jwt"
          vault.hashicorp.com/log-level: "debug"
    cloud:
      enabled: true
      resourceId:
        secretName: ${kubernetes_secret_v1.consul_hcp_resource_id.data[0].name}
        secretKey: "resource-id"
      clientId:
        secretName: ${kubernetes_secret_v1.consul_hcp_client_id.data[0].name}
        secretKey: "client-id"
      clientSecret:
        secretName: ${kubernetes_secret_v1.consul_hcp_client_secret.data[0].name}
        secretKey: "client-secret"
  EOT
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

  # set {
  #   name  = "global.secretsBackend.vault.manageSystemACLsRole"
  #   value = "consul"
  # }

  set {
    name  = "global.secretsBackend.vault.consulCARole"
    value = "consul"
  }

  set {
    name  = "global.secretsBackend.vault.connectInjectRole"
    value = "consul"
  }

  set {
    name  = "global.secretsBackend.vault.connectCA.authMethodPath"
    value = "jwt"
  }

  set {
    name  = "global.secretsBackend.vault.connectCA.rootPKIPath"
    value = "consul-connect-root"
  }

  set {
    name  = "global.secretsBackend.vault.connectCA.intermediatePKIPath"
    value = "consul-connect-intermediate"
  }

  set {
    name  = "global.secretsBackend.vault.connectInject.tlsCert.secretName"
    value = "consul-connect-root/issue/consul-connect"
  }

  set {
    name  = "global.secretsBackend.vault.connectInject.caCert.secretName"
    value = "consul-connect-root/cert/ca"
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

  set {
    name  = "global.gossipEncryption.autoGenerate"
    value = false
  }

  set {
    name  = "global.gossipEncryption.secretName"
    value = "kv/data/gossip_key"
  }

  set {
    name  = "global.gossipEncryption.secretKey"
    value = "key"
  }

  set {
    name  = "global.acls.manageSystemACLs"
    value = false
  }

  # set {
  #   name  = "global.acls.bootstrapToken.secretName"
  #   value = "kv/data/acl_bootstrap_token"
  # }

  # set {
  #   name  = "global.acls.bootstrapToken.secretKey"
  #   value = "token"
  # }

  # set {
  #   name  = "global.acls.createReplicationToken"
  #   value = true
  # }

  # set {
  #   name  = "global.acls.replicationToken.secretName"
  #   value = "kv/data/replication_token"
  # }

  # set {
  #   name  = "global.acls.replicationToken.secretKey"
  #   value = "token"
  # }

  set {
    name  = "global.federation.enabled"
    value = true
  }

  set {
    name  = "global.federation.createFederationSecret"
    value = false
  }

  set {
    name  = "meshGateway.enabled"
    value = true
  }

  set {
    name  = "meshGateway.replicas"
    value = 2
  }

  set {
    name  = "connectInject.replicas"
    value = 2
  }
}
