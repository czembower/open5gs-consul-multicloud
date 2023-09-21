resource "vault_mount" "kvv2" {
  namespace   = vault_namespace.consul.path
  path        = "kv"
  type        = "kv"
  options     = { version = "2" }
  description = "KV for Consul Backend"
}

resource "vault_kv_secret_backend_v2" "this" {
  namespace = vault_namespace.consul.path
  mount     = vault_mount.kvv2.path
}
