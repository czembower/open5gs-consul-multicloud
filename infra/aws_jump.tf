data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["amd64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_instance" "this" {
  ami = data.aws_ami.this.id
  instance_market_options {
    spot_options {
      spot_instance_type = "persistent"
    }
  }
  instance_type = "t4g.nano"
  subnet_id     = module.vpc.public_subnets[0].id
}
