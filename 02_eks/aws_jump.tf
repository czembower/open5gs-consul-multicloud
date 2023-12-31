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
  name        = "jump-${data.terraform_remote_state.base.outputs.random_id}"
  description = "jump-${data.terraform_remote_state.base.outputs.random_id}"
  vpc_id      = data.terraform_remote_state.base.outputs.aws_vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "template_cloudinit_config" "jump" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud_init.txt"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/resources/aws_jump_userdata.sh", {
      region           = var.aws_region
      eks_cluster_name = module.eks.cluster_name
    })
  }
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
  instance_type          = "t3.nano"
  subnet_id              = data.terraform_remote_state.base.outputs.aws_vpc.private_subnets[0]
  user_data              = data.template_cloudinit_config.jump.rendered
  iam_instance_profile   = aws_iam_instance_profile.jump.id
  vpc_security_group_ids = [aws_security_group.aws_jump.id]

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_iam_role" "jump" {
  name = "jump-${data.terraform_remote_state.base.outputs.random_id}-iamrole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "jump" {
  name = "jump-${data.terraform_remote_state.base.outputs.random_id}-instance-profile"
  role = aws_iam_role.jump.id
}

resource "aws_iam_role_policy" "jump" {
  name   = "jump-${data.terraform_remote_state.base.outputs.random_id}-iampolicy"
  role   = aws_iam_role.jump.id
  policy = <<EOF
{
  "Version": "2012-10-17",	
  "Statement": [	
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetInstanceProfile",
        "iam:GetUser",
        "iam:GetRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
        "ssm:UpdateInstanceInformation",
        "ssm:UpdateInstanceAssociationStatus",
        "ssm:ListInstanceAssociations",
        "ec2messages:GetMessages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
