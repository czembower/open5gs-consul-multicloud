### Root CA ###
resource "vault_mount" "pki" {
  path = "pki"
  type = "pki"

  default_lease_ttl_seconds = 31536000
  max_lease_ttl_seconds     = 31536000
}

resource "tls_private_key" "ca_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
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

### Intermediate CA ###
resource "vault_mount" "pki_int" {
  path = "pki_int"
  type = "pki"

  default_lease_ttl_seconds = 7776000
  max_lease_ttl_seconds     = 7776000
}

resource "vault_pki_secret_backend_config_urls" "pki_int_config_urls" {
  backend                 = vault_mount.pki_int.path
  issuing_certificates    = ["http://127.0.0.1/v1/pki_int/ca"]
  crl_distribution_points = ["http://127.0.0.1/v1/pki_int/crl"]
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on = [vault_mount.pki_int]
  backend    = vault_mount.pki_int.path
  type       = "internal"

  common_name        = "Vault Intermediate CA"
  format             = "pem"
  private_key_format = "der"
  key_type           = "ec"
  key_bits           = "384"
  organization       = "HashiCorp"
  country            = "US"
  locality           = "San Francisco"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  depends_on   = [vault_pki_secret_backend_intermediate_cert_request.intermediate, vault_pki_secret_backend_config_ca.ca_config]
  backend      = vault_mount.pki.path
  csr          = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name  = "Vault Intermediate CA"
  organization = "HashiCorp"
  ttl          = 7776000

  exclude_cn_from_sans = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.pki_int.path
  certificate = "${vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate}\n${tls_self_signed_cert.ca_cert.cert_pem}"
}

resource "vault_pki_secret_backend_role" "consul" {
  backend            = vault_mount.pki_int.path
  name               = "consul"
  allowed_domains    = ["consul", "svc.cluster.local"]
  allow_subdomains   = true
  allow_glob_domains = false
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
  no_store       = true
  generate_lease = false
}

### Auth Methods ###

resource "vault_jwt_auth_backend" "this" {
  description            = "JWT Auth Backend for Kubernetes"
  path                   = "jwt"
  jwt_validation_pubkeys = [data.terraform_remote_state.infra.outputs.eks_cluster_data.ca_data]
}

resource "vault_jwt_auth_backend_role" "default" {
  backend         = vault_jwt_auth_backend.this.path
  role_name       = "default"
  bound_audiences = ["https://kubernetes.default.svc.cluster.local", "vault://vault-issuer-jwt"]
  user_claim      = "sub"
  role_type       = "jwt"
  token_ttl       = 3600
  token_type      = "default"
  token_policies  = ["default"]
}

resource "vault_jwt_auth_backend_role" "consul" {
  backend         = vault_jwt_auth_backend.this.path
  role_name       = "consul-role"
  bound_audiences = ["https://kubernetes.default.svc.cluster.local", "vault://vault-issuer-jwt"]
  user_claim      = "sub"
  role_type       = "jwt"
  token_ttl       = 3600
  token_type      = "default"
  token_policies  = ["consul-policy"]
}
