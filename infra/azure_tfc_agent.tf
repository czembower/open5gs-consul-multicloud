resource "tfe_agent_pool" "azure" {
  name         = "${local.tfc_org}-agent-pool-azure"
  organization = local.tfc_org
}

resource "tfe_agent_token" "azure" {
  agent_pool_id = tfe_agent_pool.azure.id
  description   = "${local.tfc_org}-agent-token-azure"
}

resource "tls_private_key" "tfc_agent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "azurerm_role_definition" "owner" {
  name = "Owner"
}

resource "azurerm_user_assigned_identity" "tfc_agent" {
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "tfc-agent-${random_id.this.hex}"
}

resource "azurerm_role_assignment" "tfc_agent" {
  scope              = data.azurerm_subscription.this.id
  role_definition_id = data.azurerm_role_definition.owner.id
  principal_id       = azurerm_user_assigned_identity.tfc_agent.principal_id

  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = [
      role_definition_id
    ]
  }
}

data "template_file" "tfc_agent_user_data" {
  template = file("${path.module}/resources/tfc_agent_userdata.sh")

  vars = {
    TFC_AGENT_TOKEN = tfe_agent_token.azure.token
    TFC_AGENT_NAME  = "tfc-agent-azure-${random_id.this.hex}"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "tfc_agent" {
  name                = "tfc-agent-${random_id.this.hex}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Standard_F2s_v2"
  custom_data         = base64encode(data.template_file.tfc_agent_user_data.rendered)
  upgrade_mode        = "Manual"
  admin_username      = "rsa-admin"
  priority            = "Spot"
  eviction_policy     = "Delete"
  tags                = local.tags
  instances           = 1

  admin_ssh_key {
    username   = "rsa-admin"
    public_key = tls_private_key.tfc_agent.public_key_openssh
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.tfc_agent.id]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "tfc-agent-nic-${random_id.this.hex}"
    primary = true

    ip_configuration {
      name      = "tfc-agent-ipconfig-${random_id.this.hex}"
      primary   = true
      subnet_id = azurerm_subnet.this.id
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "tfc_agent" {
  name                = "tfc-agent-autoscale-setting-${random_id.this.hex}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.tfc_agent.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 1
    }
  }
}

