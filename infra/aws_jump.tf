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

resource "aws_security_group" "aws_jump" {
  name        = "jump-${random_id.this.hex}"
  description = "jump-${random_id.this.hex}"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.jump_allowed_cidr]
  }
}

resource "aws_key_pair" "jump" {
  key_name   = "jump-${random_id.this.hex}"
  public_key = tls_private_key.jump.public_key_openssh
}

resource "aws_instance" "this" {
  ami = data.aws_ami.ubuntu.id
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }
  instance_type   = "t3.nano"
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.aws_jump.id]
  key_name        = aws_key_pair.jump.key_name
}
