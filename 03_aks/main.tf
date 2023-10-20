data "http" "azure_login" {
  url = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"
  request_headers = {
    Metadata = true
  }
}

data "http" "azure_instance_metadata" {
  url = "http://169.254.169.254/metadata/instance?api-version=2021-10-01"
  request_headers = {
    Metadata = true
  }
}

data "http" "azure_account" {
  url = "https://management.azure.com/subscriptions/${local.subscription_id}?api-version=2021-04-01"
  request_headers = {
    Authorization = "Bearer ${local.azure_jwt}"
  }
}

locals {
  azure_jwt       = jsondecode(data.http.azure_login.body)["access_token"]
  subscription_id = jsondecode(data.http.azure_instance_metadata.body)["compute"]["subscriptionId"]
  tenant_id       = jsondecode(data.http.azure_account.body)["tenantId"]
}

provider "azurerm" {
  use_msi         = true
  subscription_id = local.subscription_id
  tenant_id       = local.tenant_id
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
      name = "03_aks"
    }
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}
