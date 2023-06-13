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

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
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
      name = "open5gs-consul-multicloud"
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
