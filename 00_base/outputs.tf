output "hcp_vault_aws" {
  value = hcp_vault_cluster.aws_vault
}

# output "hcp_consul_azure" {
#   value     = hcp_consul_cluster.azure_consul
#   sensitive = true
# }

# output "hcp_consul_root_token" {
#   value     = hcp_consul_cluster_root_token.azure_consul.secret_id
#   sensitive = true
# }

output "hcp_vault_admin_token" {
  value     = hcp_vault_cluster_admin_token.aws_vault.token
  sensitive = true
}

output "random_id" {
  value = random_id.this.hex
}

output "azure_resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "azure_vnet" {
  value = azurerm_virtual_network.this
}

output "aws_vpc" {
  value = module.vpc
}

output "tfc_agent_sg_id" {
  value = aws_security_group.tfc_agent.id
}

output "azure_subnet" {
  value = azurerm_subnet.this
}

output "ssh_pubkey" {
  value = tls_private_key.jump.public_key_openssh
}
