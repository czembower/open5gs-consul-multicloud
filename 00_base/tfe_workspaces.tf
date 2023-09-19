data "tfe_oauth_client" "client" {
  organization = local.tfc_org
  name         = "czembower"
}

data "tfe_project" "this" {
  name         = var.TFC_PROJECT_NAME
  organization = local.tfc_org
}

resource "tfe_workspace" "k8s" {
  name              = "01_k8s"
  organization      = local.tfc_org
  agent_pool_id     = tfe_agent_pool.aws.id
  execution_mode    = "agent"
  working_directory = "01_k8s"
  project_id        = data.tfe_project.this.id

  vcs_repo {
    identifier     = "czembower/open5gs-consul-multicloud"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}

resource "tfe_variable" "jump_allowed_cidr" {
  key          = "jump_allowed_cidr"
  value        = var.jump_allowed_cidr
  category     = "terraform"
  hcl          = false
  sensitive    = false
  workspace_id = tfe_workspace.k8s.id
}

resource "tfe_workspace" "eks_app_deploy" {
  name              = "02_eks_app_deploy"
  organization      = local.tfc_org
  agent_pool_id     = tfe_agent_pool.aws.id
  execution_mode    = "agent"
  working_directory = "02_eks_app_deploy"
  project_id        = data.tfe_project.this.id

  vcs_repo {
    identifier     = "czembower/open5gs-consul-multicloud"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}
