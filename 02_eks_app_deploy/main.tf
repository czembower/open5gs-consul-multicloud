provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# RANDOM ID TO USE FOR UNIQUE RESOURCE NAMING
resource "random_id" "this" {
  byte_length = 4
}

# TERRAFORM BLOCK CAN BE MODIFIED FOR OPEN SOURCE USAGE
terraform {
  backend "remote" {
    organization = "team-rsa"
    workspaces {
      name = "02_k8s_app_deploy"
    }
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}