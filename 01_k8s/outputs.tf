output "eks_cluster_data" {
  value = {
    name    = module.eks.cluster_name
    ca_data = module.eks.cluster_certificate_authority_data
  }
}

output "eks_managed_node_groups" {
  value = module.eks.eks_managed_node_groups
}

output "jump_iam_role" {
  value = aws_iam_role.jump.arn
}
