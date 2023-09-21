data "terraform_remote_state" "base" {
  backend = "remote"

  config = {
    hostname     = "app.terraform.io"
    organization = local.tfc_org
    workspaces = {
      name = "00_base"
    }
  }
}

data "terraform_remote_state" "eks" {
  backend = "remote"

  config = {
    hostname     = "app.terraform.io"
    organization = local.tfc_org
    workspaces = {
      name = "01_eks"
    }
  }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_data.name
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_data.name
}
