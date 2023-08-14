# REQUIRED ENVIRONMENT VARIABLES
# ARM_TENANT_ID
# ARM_SUBSCRIPTION_ID
# ARM_CLIENT_ID
# ARM_CLIENT_SECRET

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

data "azurerm_subscription" "this" {}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
  project_id    = var.hcp_project_id
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
      name = "01_infra"
    }
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    aws = {
      source = "hashicorp/aws"
    }
    hcp = {
      source = "hashicorp/hcp"
    }
  }
}

provider "tfe" {
  token = var.tfc_org_token
}

resource "tls_private_key" "jump" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
