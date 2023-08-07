output "eks_cluster_data" {
  value = {
    name = module.eks.cluster_name
  }
}
