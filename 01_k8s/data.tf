data "terraform_remote_state" "base" {
  backend = "remote"

  config = {
    hostname     = "app.terraform.io"
    organization = local.tfc_org
    workspaces = {
      name = "00_base"
    }
  }
}

data "azurerm_resource_group" "this" {
  name = data.terraform_remote_state.base.outputs.azure_resource_group_name
}
