variable "azure_location" {
  type    = string
  default = "eastus2"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "TFC_WORKSPACE_SLUG" {
  type = string
}

variable "TFC_CONFIGURATION_VERSION_GIT_BRANCH" {
  type = string
}

variable "hcp_client_id" {
  type    = string
  default = null
}

variable "hcp_client_secret" {
  type    = string
  default = null
}

variable "consul_hcp_resource_id" {
  type    = string
  default = null
}

locals {
  tfc_org       = split("/", var.TFC_WORKSPACE_SLUG)[0]
  tfc_workspace = split("/", var.TFC_WORKSPACE_SLUG)[1]
  tags = {
    TERRAFORM     = true
    TFC_ORG       = local.tfc_org
    TFC_WORKSPACE = local.tfc_workspace
    GIT_BRANCH    = var.TFC_CONFIGURATION_VERSION_GIT_BRANCH
  }
}
