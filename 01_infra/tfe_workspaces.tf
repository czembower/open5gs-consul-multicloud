data "tfe_oauth_client" "client" {
  organization = local.tfc_org
  name         = "czembower"
}

data "tfe_project" "this" {
  name         = var.TFC_PROJECT_NAME
  organization = local.tfc_org
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
