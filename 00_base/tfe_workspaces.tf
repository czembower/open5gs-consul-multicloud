data "tfe_oauth_client" "client" {
  organization = local.tfc_org
  name         = "czembower"
}

data "tfe_project" "this" {
  name         = var.TFC_PROJECT_NAME
  organization = local.tfc_org
}

resource "tfe_workspace" "eks" {
  name                = "01_eks"
  organization        = local.tfc_org
  agent_pool_id       = tfe_agent_pool.aws.id
  execution_mode      = "agent"
  working_directory   = "01_eks"
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
  name                = "02_aks"
  organization        = local.tfc_org
  agent_pool_id       = tfe_agent_pool.azure.id
  execution_mode      = "agent"
  working_directory   = "02_aks"
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
  name                = "03_eks_app_deploy"
  organization        = local.tfc_org
  agent_pool_id       = tfe_agent_pool.aws.id
  execution_mode      = "agent"
  working_directory   = "03_eks_app_deploy"
  project_id          = data.tfe_project.this.id
  global_remote_state = true

  vcs_repo {
    identifier     = "czembower/open5gs-consul-multicloud"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}
