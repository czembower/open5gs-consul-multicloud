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

  set {
    name  = "global.tls.enabled"
    value = true
  }

  set {
    name  = "server.enabled"
    value = false
  }

  set {
    name  = "externalServers.enabled"
    value = true
  }

  set {
    name  = "externalServers.hosts.0"
    value = data.terraform_remote_state.infra.outputs.hcp_vault_consul.consul_public_endpoint_url
  }

  set {
    name  = "client.enabled"
    value = true
  }

  set {
    name  = "client.join"
    value = data.terraform_remote_state.infra.outputs.hcp_vault_consul.consul_public_endpoint_url
  }

  set {
    name  = "dns.enabled"
    value = true
  }
}
