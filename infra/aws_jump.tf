data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "this" {
  ami = data.aws_ami.ubuntu.id
  instance_market_options {
    spot_options {
      spot_instance_type = "persistent"
    }
  }
  instance_type = "t4g.nano"
  subnet_id     = module.vpc.public_subnets[0]
}
