resource "azurerm_virtual_network" "this" {
  name                = "vnet-${random_id.this.hex}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]

  tags = local.tags
}

resource "azurerm_subnet" "this" {
  name                 = "subnet-${random_id.this.hex}"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.this.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 2, 0)]
}

resource "azurerm_public_ip" "nat" {
  name                    = "pip-nat-${random_id.this.hex}"
  location                = azurerm_virtual_network.this.location
  resource_group_name     = azurerm_resource_group.this.name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30

  tags = local.tags
}

resource "azurerm_nat_gateway" "this" {
  name                = "nat-gateway-${random_id.this.hex}"
  location            = azurerm_virtual_network.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.this.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}
