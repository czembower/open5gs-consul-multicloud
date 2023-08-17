output "eks_cluster_data" {
  value = {
    name    = module.eks.cluster_name
    ca_data = module.eks.cluster_certificate_authority_data
  }
}

output "jump_iam_role" {
  value = aws_iam_role.jump.arn
}

# output "fargate_profiles" {
#   value = module.eks.fargate_profiles
# }

output "eks_managed_node_groups" {
  value = module.eks.eks_managed_node_groups
}

output "hcp_vault_aws" {
  value = hcp_vault_cluster.aws_vault
}

output "hcp_consul_azure" {
  value     = hcp_consul_cluster.azure_consul
  sensitive = true
}

output "hcp_consul_root_token" {
  value     = hcp_consul_cluster_root_token.azure_consul.secret_id
  sensitive = true
}

output "hcp_vault_admin_token" {
  value     = hcp_vault_cluster_admin_token.aws_vault.token
  sensitive = true
}
