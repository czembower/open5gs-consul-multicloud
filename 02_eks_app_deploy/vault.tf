resource "vault_mount" "pki" {
  path = "pki"
  type = "pki"

  default_lease_ttl_seconds = 31536000
  max_lease_ttl_seconds     = 31536000
}

resource "tls_private_key" "ca_key" {
  algorithm = "ec"
  rsa_bits  = 256
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = "Vault Root CA"
    organization = "HashiCorp"
  }

  validity_period_hours = 175200
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
  is_ca_certificate = true
}

resource "vault_pki_secret_backend_config_ca" "ca_config" {
  depends_on = [vault_mount.pki, tls_private_key.ca_key, tls_self_signed_cert.ca_cert]
  backend    = vault_mount.pki.path
  pem_bundle = "${tls_private_key.ca_key.private_key_pem}\n${tls_self_signed_cert.ca_cert.cert_pem}"
}

resource "vault_pki_secret_backend_config_urls" "pki_config_urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["http://127.0.0.1/v1/pki/ca"]
  crl_distribution_points = ["http://127.0.0.1/v1/pki/crl"]
}
