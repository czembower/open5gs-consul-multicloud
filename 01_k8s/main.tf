provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }

    virtual_machine_scale_set {
      roll_instances_when_required = false
    }
  }
}

provider "azuread" {}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

# TERRAFORM BLOCK CAN BE MODIFIED FOR OPEN SOURCE USAGE
terraform {
  backend "remote" {
    organization = "team-rsa"
    workspaces {
      name = "01_k8s"
    }
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "tls_private_key" "jump" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
