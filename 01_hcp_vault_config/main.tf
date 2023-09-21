provider "vault" {
  address = data.terraform_remote_state.base.outputs.hcp_vault_aws.vault_public_endpoint_url
  token   = data.terraform_remote_state.base.outputs.hcp_vault_admin_token
}
