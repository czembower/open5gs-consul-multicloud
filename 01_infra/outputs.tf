output "eks_cluster_data" {
  value = {
    name = module.eks.cluster_name
  }
}

output "jump_iam_role" {
  value = aws_iam_role.jump.arn
}

output "fargate_iam_role_arn" {
  value = module.eks.module.fargate_profile["default"].aws_iam_role.this.arn
}
