### Root CA ###
resource "tls_private_key" "consul_ca_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "consul_ca_cert" {
  private_key_pem = tls_private_key.consul_ca_key.private_key_pem

  subject {
    common_name  = "${vault_mount.pki_consul_root.path} Certificate Authority"
    organization = "HashiCorp"
  }

  validity_period_hours = 175200
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
  is_ca_certificate = true
}

resource "vault_mount" "pki_consul_root" {
  namespace = vault_namespace.consul.path
  path      = "consul-root"
  type      = "pki"

  default_lease_ttl_seconds = 31536000
  max_lease_ttl_seconds     = 31536000
}

resource "vault_pki_secret_backend_config_ca" "consul_ca_config" {
  namespace  = vault_namespace.consul.path
  depends_on = [vault_mount.pki_consul_root, tls_private_key.consul_ca_key, tls_self_signed_cert.consul_ca_cert]
  backend    = vault_mount.pki_consul_root.path
  pem_bundle = "${tls_private_key.consul_ca_key.private_key_pem}\n${tls_self_signed_cert.consul_ca_cert.cert_pem}"
}

resource "vault_pki_secret_backend_config_urls" "pki_consul_root_config_urls" {
  namespace               = vault_namespace.consul.path
  backend                 = vault_mount.pki_consul_root.path
  issuing_certificates    = ["http://127.0.0.1/v1/${vault_mount.pki_consul_root.path}/ca"]
  crl_distribution_points = ["http://127.0.0.1/v1/${vault_mount.pki_consul_root.path}/crl"]
}

### Intermediate CA ###
resource "vault_mount" "pki_consul_int" {
  namespace = vault_namespace.consul.path
  path      = "consul-intermediate"
  type      = "pki"

  default_lease_ttl_seconds = 7776000
  max_lease_ttl_seconds     = 7776000
}

resource "vault_pki_secret_backend_config_urls" "pki_consul_intermediate_config_urls" {
  namespace               = vault_namespace.consul.path
  backend                 = vault_mount.pki_consul_int.path
  issuing_certificates    = ["http://127.0.0.1/v1/${vault_mount.pki_consul_int.path}/ca"]
  crl_distribution_points = ["http://127.0.0.1/v1/${vault_mount.pki_consul_int.path}/crl"]
}

resource "vault_pki_secret_backend_intermediate_cert_request" "consul_intermediate" {
  namespace  = vault_namespace.consul.path
  depends_on = [vault_mount.pki_consul_int]
  backend    = vault_mount.pki_consul_int.path
  type       = "internal"

  common_name        = "${vault_mount.pki_consul_int.path} Certificate Authority"
  format             = "pem"
  private_key_format = "der"
  key_type           = "ec"
  key_bits           = "384"
  organization       = "HashiCorp"
  country            = "US"
  locality           = "San Francisco"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "consul_intermediate" {
  namespace    = vault_namespace.consul.path
  depends_on   = [vault_pki_secret_backend_intermediate_cert_request.consul_intermediate, vault_pki_secret_backend_config_ca.consul_ca_config]
  backend      = vault_mount.pki_consul_root.path
  csr          = vault_pki_secret_backend_intermediate_cert_request.consul_intermediate.csr
  common_name  = "${vault_mount.pki_consul_int.path} Certificate Authority"
  organization = "HashiCorp"
  ttl          = 7776000

  exclude_cn_from_sans = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "consul_intermediate" {
  namespace   = vault_namespace.consul.path
  backend     = vault_mount.pki_consul_int.path
  certificate = "${vault_pki_secret_backend_root_sign_intermediate.consul_intermediate.certificate}\n${tls_self_signed_cert.consul_ca_cert.cert_pem}"
}

resource "vault_pki_secret_backend_role" "consul" {
  namespace          = vault_namespace.consul.path
  backend            = vault_mount.pki_consul_int.path
  name               = "consul"
  allowed_domains    = ["svc.cluster.local", "*consul*"]
  allow_subdomains   = true
  allow_glob_domains = true
  allow_any_name     = false
  enforce_hostnames  = true
  allow_ip_sans      = true
  server_flag        = true
  client_flag        = true
  key_usage          = ["DigitalSignature", "KeyAgreement", "KeyEncipherment"]
  key_type           = "ec"
  key_bits           = 256

  ou           = ["consul"]
  organization = ["HashiCorp"]
  country      = ["US"]
  locality     = ["San Francisco"]

  max_ttl        = 86400
  ttl            = 86400
  no_store       = false
  generate_lease = true
}
