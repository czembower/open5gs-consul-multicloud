resource "kubernetes_namespace" "consul" {
  metadata {
    annotations = {
      name = "consul"
    }
    name = "consul"
  }
}

resource "tls_private_key" "consul_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "consul_ca" {
  private_key_pem = tls_private_key.consul_ca.private_key_pem

  subject {
    common_name  = "Consul Root CA"
    organization = "HashiCorp RSA"
  }

  validity_period_hours = 175200
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
  is_ca_certificate = true
}

resource "kubernetes_secret" "consul_ca_cert" {
  metadata {
    name      = "consul-ca-cert"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  data = {
    "tls.crt" = "${tls_self_signed_cert.consul_ca.cert_pem}"
    "tls.key" = "${tls_private_key.consul_ca.private_key_pem}"
  }

  type = "kubernetes.io/tls"
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
    name  = "global.tls.enableAutoEncrypt"
    value = true
  }

  set {
    name  = "global.tls.caCert.secretName"
    value = kubernetes_secret.consul_ca_cert.metadata[0].name
  }

  set {
    name  = "global.tls.caCert.secretKey"
    value = "tls.crt"
  }

  set {
    name  = "global.tls.caKey.secretName"
    value = kubernetes_secret.consul_ca_cert.metadata[0].name
  }

  set {
    name  = "global.tls.caKey.secretKey"
    value = "tls.key"
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
    name  = "externalServers.hosts"
    value = "{${split("//", data.terraform_remote_state.base.outputs.hcp_consul_azure.consul_public_endpoint_url)[1]}}"
  }

  set {
    name  = "client.enabled"
    value = true
  }

  set {
    name  = "client.join"
    value = "{${split("//", data.terraform_remote_state.base.outputs.hcp_consul_azure.consul_public_endpoint_url)[1]}}"
  }

  set {
    name  = "dns.enabled"
    value = true
  }

  # set {
  #   name  = "secretsBackend.vault.enabled"
  #   value = true
  # }
}
