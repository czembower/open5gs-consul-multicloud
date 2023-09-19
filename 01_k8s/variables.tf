variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aks_cidr" {
  type    = string
  default = "100.100.0.0/14"
}

variable "jump_allowed_cidr" {
  type    = string
  default = null
}

locals {
  tfc_org        = split("/", var.TFC_WORKSPACE_SLUG)[0]
  tfc_workspace  = split("/", var.TFC_WORKSPACE_SLUG)[1]
  service_cidr   = cidrsubnet(var.aks_cidr, 2, 0)
  pod_cidr       = cidrsubnet(var.aks_cidr, 2, 2)
  dns_service_ip = cidrhost(local.service_cidr, 10)

  tags = {
    TERRAFORM     = true
    TFC_ORG       = local.tfc_org
    TFC_WORKSPACE = local.tfc_workspace
    GIT_BRANCH    = var.TFC_CONFIGURATION_VERSION_GIT_BRANCH
  }
}
