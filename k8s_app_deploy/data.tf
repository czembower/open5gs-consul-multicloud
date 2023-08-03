data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.infra.outputs.eks_cluster_name
}
