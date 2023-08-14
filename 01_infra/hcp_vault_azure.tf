resource "azuread_service_principal" "azure_vault" {
  application_id = hcp_azure_peering_connection.azure_vault.application_id
}

resource "azurerm_role_definition" "azure_vault" {
  name  = "hcp-hvn-peering-access-${random_id.this.hex}"
  scope = azurerm_virtual_network.this.id

  assignable_scopes = [
    azurerm_virtual_network.this.id
  ]

  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/peer/action",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write"
    ]
  }
}

resource "azurerm_role_assignment" "azure_vault" {
  principal_id       = azuread_service_principal.azure_vault.id
  scope              = azurerm_virtual_network.this.id
  role_definition_id = azurerm_role_definition.azure_vault.role_definition_resource_id
}

resource "hcp_hvn" "azure_vault" {
  hvn_id         = "hvn-azure-${random_id.this.hex}"
  cloud_provider = "azure"
  region         = var.azure_location
  cidr_block     = var.azure_hvn_cidr
}

resource "hcp_vault_cluster" "azure_vault" {
  cluster_id = "vault-cluster-azure-${random_id.this.hex}"
  hvn_id     = hcp_hvn.azure_vault.hvn_id
  tier       = "plus_small"

  public_endpoint = false
  primary_link    = hcp_vault_cluster.aws_vault.self_link

  major_version_upgrade_config {
    upgrade_type            = "SCHEDULED"
    maintenance_window_day  = "FRIDAY"
    maintenance_window_time = "WINDOW_12AM_4AM"
  }
}

resource "hcp_azure_peering_connection" "azure_vault" {
  hvn_link                 = hcp_hvn.azure_vault.self_link
  peering_id               = "hvn-azure-peering-${random_id.this.hex}"
  peer_vnet_name           = azurerm_virtual_network.this.name
  peer_subscription_id     = data.azurerm_subscription.this.subscription_id
  peer_tenant_id           = data.azurerm_subscription.this.tenant_id
  peer_resource_group_name = azurerm_resource_group.this.name
  peer_vnet_region         = azurerm_virtual_network.this.location

  depends_on = [azurerm_role_assignment.azure_vault]
}

data "hcp_azure_peering_connection" "azure_vault" {
  hvn_link              = hcp_hvn.azure_vault.self_link
  peering_id            = hcp_azure_peering_connection.azure_vault.peering_id
  wait_for_active_state = true
}

resource "hcp_hvn_route" "azure_vault" {
  hvn_link         = hcp_hvn.azure_vault.self_link
  hvn_route_id     = "hvn-route-azure-${random_id.this.hex}"
  destination_cidr = azurerm_virtual_network.this.address_space[0]
  target_link      = data.hcp_azure_peering_connection.azure_vault.self_link
}
