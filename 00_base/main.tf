# REQUIRED ENVIRONMENT VARIABLES
# ARM_TENANT_ID
# ARM_SUBSCRIPTION_ID
# ARM_CLIENT_ID
# ARM_CLIENT_SECRET

# RANDOM ID TO USE FOR UNIQUE RESOURCE NAMING
resource "random_id" "this" {
  byte_length = 4
}

provider "tfe" {
  token = var.tfc_org_token
}

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
  project_id    = var.hcp_project_id
}

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
      name = "00_base"
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
      source  = "hashicorp/hcp"
      version = "0.70.0"
    }
  }
}

resource "tls_private_key" "jump" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
