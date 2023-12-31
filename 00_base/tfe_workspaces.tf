data "tfe_oauth_client" "client" {
  organization = local.tfc_org
  name         = "czembower"
}

data "tfe_project" "this" {
  name         = var.TFC_PROJECT_NAME
  organization = local.tfc_org
}

resource "tfe_workspace" "hcp_vault_config" {
  name                = "01_hcp_vault_config"
  organization        = local.tfc_org
  execution_mode      = "remote"
  working_directory   = "01_hcp_vault_config"
  project_id          = data.tfe_project.this.id
  global_remote_state = true

  vcs_repo {
    identifier     = "czembower/open5gs-consul-multicloud"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}

resource "tfe_workspace" "eks" {
  name                = "02_eks"
  organization        = local.tfc_org
  agent_pool_id       = tfe_agent_pool.aws.id
  execution_mode      = "agent"
  working_directory   = "02_eks"
  project_id          = data.tfe_project.this.id
  global_remote_state = true

  vcs_repo {
    identifier     = "czembower/open5gs-consul-multicloud"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}

resource "tfe_variable" "aws_jump_allowed_cidr" {
  key          = "jump_allowed_cidr"
  value        = var.jump_allowed_cidr
  category     = "terraform"
  hcl          = false
  sensitive    = false
  workspace_id = tfe_workspace.eks.id
}

resource "tfe_workspace" "aks" {
  name                = "03_aks"
  organization        = local.tfc_org
  agent_pool_id       = tfe_agent_pool.azure.id
  execution_mode      = "agent"
  working_directory   = "03_aks"
  project_id          = data.tfe_project.this.id
  global_remote_state = true

  vcs_repo {
    identifier     = "czembower/open5gs-consul-multicloud"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}

resource "tfe_variable" "azure_jump_allowed_cidr" {
  key          = "jump_allowed_cidr"
  value        = var.jump_allowed_cidr
  category     = "terraform"
  hcl          = false
  sensitive    = false
  workspace_id = tfe_workspace.aks.id
}

resource "tfe_workspace" "eks_app_deploy" {
  name                = "04_eks_app_deploy"
  organization        = local.tfc_org
  agent_pool_id       = tfe_agent_pool.aws.id
  execution_mode      = "agent"
  working_directory   = "04_eks_app_deploy"
  project_id          = data.tfe_project.this.id
  global_remote_state = true

  vcs_repo {
    identifier     = "czembower/open5gs-consul-multicloud"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}

resource "tfe_variable" "hcp_client_id" {
  key          = "hcp_client_id"
  value        = var.hcp_consul_smc_client_id
  category     = "terraform"
  hcl          = false
  sensitive    = true
  workspace_id = tfe_workspace.eks_app_deploy.id
}

resource "tfe_variable" "hcp_client_secret" {
  key          = "hcp_client_secret"
  value        = var.hcp_consul_smc_client_secret
  category     = "terraform"
  hcl          = false
  sensitive    = true
  workspace_id = tfe_workspace.eks_app_deploy.id
}

resource "tfe_variable" "consul_hcp_resource_id" {
  key          = "consul_hcp_resource_id"
  value        = "organization/${hcp_hvn.aws.organization_id}/project/${hcp_hvn.aws.project_id}/hashicorp.consul.global-network-manager.cluster/${var.aws_region}"
  category     = "terraform"
  hcl          = false
  sensitive    = true
  workspace_id = tfe_workspace.eks_app_deploy.id
}
