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

variable "vnet_cidr" {
  type    = string
  default = "10.100.0.0/20"
}

variable "vpc_cidr" {
  type    = string
  default = "10.200.0.0/20"
}

locals {
  tfc_org         = split("/", var.TFC_WORKSPACE_SLUG)[0]
  tfc_workspace   = split("/", var.TFC_WORKSPACE_SLUG)[1]
  private_subnets = [cidrsubnet(var.vpc_cidr, 2, 0), cidrsubnet(var.vpc_cidr, 2, 1), cidrsubnet(var.vpc_cidr, 2, 2)]    // 3x /26
  public_subnets  = [cidrsubnet(var.vpc_cidr, 4, 12), cidrsubnet(var.vpc_cidr, 4, 13), cidrsubnet(var.vpc_cidr, 4, 14)] // 3x /28
  azs             = chunklist(data.aws_availability_zones.this.names, 3)[0]                                             // returns first three availability zones in the region as a list
}
