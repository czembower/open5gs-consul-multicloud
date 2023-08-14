resource "hcp_hvn" "aws" {
  hvn_id         = "hvn-${random_id.this.hex}"
  cloud_provider = "aws"
  region         = var.aws_region
  cidr_block     = "172.25.16.0/20"
}

resource "hcp_vault_cluster" "aws" {
  cluster_id = "vault-cluster-aws"
  hvn_id     = hcp_hvn.aws.hvn_id
  tier       = "plus_small"

  public_endpoint = false

  major_version_upgrade_config {
    upgrade_type            = "SCHEDULED"
    maintenance_window_day  = "SATURDAY"
    maintenance_window_time = "WINDOW_12AM_4AM"
  }
}
