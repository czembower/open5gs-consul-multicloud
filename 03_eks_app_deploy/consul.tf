resource "consul_autopilot_config" "this" {
  cleanup_dead_servers   = true
  last_contact_threshold = "5s"
  max_trailing_logs      = 500
}

resource "consul_certificate_authority" "connect_vault" {
  connect_provider = "vault"

  config_json = jsonencode({
    Address             = data.terraform_remote_state.base.outputs.hcp_vault_aws.vault_public_endpoint_url
    Token               = data.terraform_remote_state.base.outputs.hcp_vault_admin_token
    RootPKIPath         = "consul-connect-root"
    IntermediatePKIPath = "consul-connect-intermediate"
  })
}
