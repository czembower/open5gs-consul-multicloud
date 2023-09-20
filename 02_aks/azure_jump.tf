### This file can safely be removed from the workspace if a jump server is not required. ###

resource "azurerm_public_ip" "jumpbox" {
  name                = "${data.terraform_remote_state.base.outputs.random_id}-jumpbox-pip"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}


resource "azurerm_network_interface" "jumpbox" {
  name                = "${data.terraform_remote_state.base.outputs.random_id}-vm-jumpbox-nic"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "${data.terraform_remote_state.base.outputs.random_id}-jump-ipconfig"
    subnet_id                     = data.terraform_remote_state.base.outputs.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "${data.terraform_remote_state.base.outputs.random_id}-vm-jumpbox"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
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
    public_key = data.terraform_remote_state.base.outputs.ssh_pubkey
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = local.tags
}
