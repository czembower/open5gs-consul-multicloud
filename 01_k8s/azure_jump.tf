### This file can safely be removed from the workspace if a jump server is not required. ###

resource "azurerm_public_ip" "jumpbox" {
  name                = "${random_id.this.hex}-jumpbox-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}


resource "azurerm_network_interface" "jumpbox" {
  name                = "${random_id.this.hex}-vm-jumpbox-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "${random_id.this.hex}-jump-ipconfig"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "${random_id.this.hex}-vm-jumpbox"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_D4s_v3"
  admin_username      = "azureuser"
  priority            = "Spot"
  eviction_policy     = "Deallocate"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.jump.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = local.tags
}
