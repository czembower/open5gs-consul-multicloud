## Auth Methods ###

data "kubernetes_secret_v1" "sa_public_key" {
  metadata {
    name = "sa-public-key"
  }
}

resource "vault_jwt_auth_backend" "this" {
  namespace              = "consul"
  description            = "JWT Auth Backend for Kubernetes"
  path                   = "jwt"
  jwt_validation_pubkeys = [chomp(data.kubernetes_secret_v1.sa_public_key.data["sa.pub"])]
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
