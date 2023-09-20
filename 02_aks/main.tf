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

terraform {
  backend "remote" {
    organization = "team-rsa"
    workspaces {
      name = "02_aks"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/azurerm"
    }
  }
}
