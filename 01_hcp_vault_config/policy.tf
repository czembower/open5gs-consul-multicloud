resource "vault_policy" "consul" {
  namespace = vault_namespace.consul.path
  name      = "consul"

  policy = <<EOT
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}
