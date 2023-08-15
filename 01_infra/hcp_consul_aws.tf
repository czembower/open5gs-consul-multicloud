resource "hcp_consul_cluster" "aws_consul" {
  cluster_id      = "consul-cluster-aws-${random_id.this.hex}"
  hvn_id          = hcp_hvn.aws_vault.hvn_id
  tier            = "development"
  connect_enabled = true
  datacenter      = "aws-${random_id.this.hex}"
  public_endpoint = false
  size            = "x_small"
}
