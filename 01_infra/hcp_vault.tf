resource "hcp_hvn" "aws" {
  hvn_id         = "hvn-${random_id.this.hex}"
  cloud_provider = "aws"
  region         = var.aws_region
  cidr_block     = var.aws_hvn_cidr
}

resource "hcp_vault_cluster" "aws" {
  cluster_id = "vault-cluster-aws-${random_id.this.hex}"
  hvn_id     = hcp_hvn.aws.hvn_id
  tier       = "plus_small"

  public_endpoint = false

  major_version_upgrade_config {
    upgrade_type            = "SCHEDULED"
    maintenance_window_day  = "SATURDAY"
    maintenance_window_time = "WINDOW_12AM_4AM"
  }
}

resource "hcp_aws_network_peering" "aws" {
  hvn_id          = hcp_hvn.aws.hvn_id
  peering_id      = "hvn-peering-${random_id.this.hex}"
  peer_vpc_id     = module.vpc.vpc_id
  peer_account_id = module.vpc.vpc_owner_id
  peer_vpc_region = hcp_hvn.aws.region
}

resource "hcp_hvn_route" "aws" {
  hvn_link         = hcp_hvn.aws.self_link
  hvn_route_id     = "hvn-route-${random_id.this.hex}"
  destination_cidr = module.vpc.vpc_cidr_block
  target_link      = hcp_aws_network_peering.aws.self_link
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.aws.provider_peering_id
  auto_accept               = true
}
