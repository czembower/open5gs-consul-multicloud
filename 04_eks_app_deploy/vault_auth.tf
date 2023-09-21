## Auth Methods ###

data "tls_certificate" "eks_ca" {
  content = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_data.ca_data)
}

resource "vault_jwt_auth_backend" "this" {
  namespace              = "consul"
  description            = "JWT Auth Backend for Kubernetes"
  path                   = "kubernetes"
  jwt_validation_pubkeys = [chomp(data.tls_certificate.eks_ca.certificates[0].cert_pem)]
}

resource "vault_jwt_auth_backend_role" "consul" {
  namespace       = "consul"
  backend         = vault_jwt_auth_backend.this.path
  role_name       = "consul"
  bound_audiences = ["https://kubernetes.default.svc.cluster.local"]
  user_claim      = "sub"
  role_type       = "jwt"
  token_ttl       = 3600
  token_type      = "default"
  token_policies  = ["consul"]
}
