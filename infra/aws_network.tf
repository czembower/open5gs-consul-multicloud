module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "vpc-${random_id.this.hex}"
  cidr   = var.vpc_cidr
  azs    = local.azs

  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_dhcp_options  = false
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    },
    ssm = {
      service = "ssm"
      tags    = { Name = "ssm" }
    },
    ssmmessages = {
      service = "ssmmessages"
      tags    = { Name = "ssmmessages" }
    },
    ec2messages = {
      service = "ec2messages"
      tags    = { Name = "ec2messages" }
    }
  }
}
