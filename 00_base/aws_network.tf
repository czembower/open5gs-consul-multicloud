data "aws_availability_zones" "this" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "vpc-${random_id.this.hex}"
  cidr   = var.vpc_cidr
  azs    = local.azs

  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway      = true
  single_nat_gateway      = false
  enable_vpn_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  enable_dhcp_options     = false
  map_public_ip_on_launch = true
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "endpoints-${random_id.this.hex}"
  description = "endpoints-${random_id.this.hex}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
