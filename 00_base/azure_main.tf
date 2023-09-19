data "azurerm_subscription" "this" {}

# ALL RESOURCES IN THIS WORKSPACE WILL BE DEPLOYED INTO THE FOLLOWING RESOURCE GROUP
resource "azurerm_resource_group" "this" {
  name     = "open5gs-${random_id.this.hex}"
  location = var.azure_location
}
