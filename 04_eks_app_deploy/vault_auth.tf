## Auth Methods ###

data "tls_certificate" "eks_ca" {
  content = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_data.ca_data)
}

data "external" "pubkey_conversion" {
  program = ["jq", "-n", "--arg", "pubkey", "\"$(echo \"${chomp(data.tls_certificate.eks_ca.certificates[0].cert_pem)}\" | openssl x509 -noout -pubkey | awk '{printf \"%s\\n\", $0}')\"", "'{\"public_key_pem\":$pubkey}'"
  ]
}

resource "vault_jwt_auth_backend" "this" {
  namespace              = "consul"
  description            = "JWT Auth Backend for Kubernetes"
  path                   = "kubernetes"
  jwt_validation_pubkeys = [data.external.pubkey_conversion.result]
}

resource "vault_jwt_auth_backend_role" "consul" {
  namespace       = "consul"
  backend         = vault_jwt_auth_backend.this.path
  role_name       = "consul"
  bound_audiences = ["https://kubernetes.default.svc"]
  user_claim      = "sub"
  role_type       = "jwt"
  token_ttl       = 3600
  token_type      = "default"
  token_policies  = ["consul"]
}
