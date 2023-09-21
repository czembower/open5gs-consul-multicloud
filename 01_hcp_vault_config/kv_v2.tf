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

resource "random_id" "gossip_key" {
  byte_length = 32
}

resource "vault_kv_secret_v2" "this" {
  namespace = vault_namespace.consul.path
  mount     = vault_mount.kvv2.path
  name      = "gossip_key"
  data_json = jsonencode(
    {
      key = "${random_id.gossip_key.b64_std}"
    }
  )
}
