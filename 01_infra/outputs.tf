output "eks_cluster_data" {
  value = {
    name = module.eks.cluster_name
  }
}

output "jump_iam_role" {
  value = aws_iam_role.jump.arn
}

output "fargate_profiles" {
  value = module.eks.fargate_profiles
}