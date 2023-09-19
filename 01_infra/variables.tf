variable "tfc_org_token" {
  type = string
}

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

variable "TFC_PROJECT_NAME" {
  type = string
}

variable "vnet_cidr" {
  type    = string
  default = "10.100.0.0/20"
}

variable "vpc_cidr" {
  type    = string
  default = "10.200.0.0/20"
}

variable "aks_cidr" {
  type    = string
  default = "100.100.0.0/14"
}

variable "jump_allowed_cidr" {
  type    = string
  default = null
}

variable "hcp_client_id" {
  type    = string
  default = null
}

variable "hcp_client_secret" {
  type    = string
  default = null
}

variable "hcp_project_id" {
  type    = string
  default = null
}

variable "aws_hvn_cidr" {
  type    = string
  default = "172.25.16.0/20"
}

variable "azure_hvn_cidr" {
  type    = string
  default = "172.26.16.0/20"
}

locals {
  tfc_org         = split("/", var.TFC_WORKSPACE_SLUG)[0]
  tfc_workspace   = split("/", var.TFC_WORKSPACE_SLUG)[1]
  private_subnets = [cidrsubnet(var.vpc_cidr, 2, 0), cidrsubnet(var.vpc_cidr, 2, 1), cidrsubnet(var.vpc_cidr, 2, 2)]    // 3x /26
  public_subnets  = [cidrsubnet(var.vpc_cidr, 4, 12), cidrsubnet(var.vpc_cidr, 4, 13), cidrsubnet(var.vpc_cidr, 4, 14)] // 3x /28
  azs             = chunklist(data.aws_availability_zones.this.names, 3)[0]                                             // returns first three availability zones in the region as a list
  service_cidr    = cidrsubnet(var.aks_cidr, 2, 0)
  pod_cidr        = cidrsubnet(var.aks_cidr, 2, 2)
  dns_service_ip  = cidrhost(local.service_cidr, 10)

  tags = {
    TERRAFORM     = true
    TFC_ORG       = local.tfc_org
    TFC_WORKSPACE = local.tfc_workspace
    GIT_BRANCH    = var.TFC_CONFIGURATION_VERSION_GIT_BRANCH
  }
}
