data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}

resource "azurerm_user_assigned_identity" "aks" {
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "uaid-aks-${random_id.this.hex}"
}

resource "azurerm_role_assignment" "aks" {
  scope              = data.azurerm_subscription.this.id
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = azurerm_user_assigned_identity.aks.principal_id

  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = [
      role_definition_id
    ]
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  depends_on = [
    azurerm_subnet_nat_gateway_association.private,
    azurerm_nat_gateway_public_ip_association.this
  ]

  name                              = "aks-rsa-${random_id.this.hex}"
  location                          = azurerm_resource_group.this.location
  resource_group_name               = azurerm_resource_group.this.name
  kubernetes_version                = null // latest stable
  dns_prefix                        = "aks"
  role_based_access_control_enabled = true
  private_cluster_enabled           = true
  private_dns_zone_id               = "System"
  automatic_channel_upgrade         = "rapid"

  default_node_pool {
    name                   = "default"
    enable_auto_scaling    = true
    min_count              = 3
    max_count              = 5
    vm_size                = "Standard_D2as_v4"
    type                   = "VirtualMachineScaleSets"
    vnet_subnet_id         = azurerm_subnet.this.id
    enable_host_encryption = false
    zones                  = null

    node_labels = {
      nodepool = "default"
    }
  }

  network_profile {
    network_plugin    = "kubenet"
    service_cidr      = local.service_cidr
    dns_service_ip    = local.dns_service_ip
    pod_cidr          = local.pod_cidr
    load_balancer_sku = "standard"
    outbound_type     = "userAssignedNATGateway"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = toset([azurerm_user_assigned_identity.aks.id])
  }

  tags = local.tags
}
