variable "TFC_WORKSPACE_SLUG" {
  type = string
}

variable "TFC_CONFIGURATION_VERSION_GIT_BRANCH" {
  type = string
}

locals {
  tfc_org = split("/", var.TFC_WORKSPACE_SLUG)[0]
}
