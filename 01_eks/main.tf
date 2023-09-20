provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

terraform {
  backend "remote" {
    organization = "team-rsa"
    workspaces {
      name = "01_eks"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "tls_private_key" "jump" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
