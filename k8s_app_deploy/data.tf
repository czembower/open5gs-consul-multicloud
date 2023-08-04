data "terraform_remote_state" "infra" {
  backend = "remote"

  config = {
    hostname     = "app.terraform.io"
    organization = local.tfc_org
    workspaces = {
      name = "01_infra"
    }
  }
}
data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.infra.outputs.eks_cluster_data.name
}
