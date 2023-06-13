resource "tfe_agent_pool" "aws" {
  name         = "${local.tfc_org}-agent-pool-aws-${random_id.this.hex}"
  organization = local.tfc_org
}

resource "tfe_agent_token" "aws" {
  agent_pool_id = tfe_agent_pool.aws.id
  description   = "${local.tfc_org}-agent-token-aws-${random_id.this.hex}"
}

resource "aws_iam_role" "tfc_agent" {
  name = "tfc-agent-${random_id.this.hex}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "ecs.amazonaws.com",
          "ec2.amazonaws.com"
        ]
    },
    "Effect": "Allow",
    "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "tfc_agent" {
  role       = aws_iam_role.tfc_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


resource "aws_ecs_cluster" "this" {
  name = "${local.tfc_org}-${random_id.this.hex}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_security_group" "tfc_agent" {
  name        = "tfc-agent-${random_id.this.hex}"
  description = "tfc-agent-${random_id.this.hex}"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE_SPOT"]
}

resource "aws_ecs_task_definition" "tfc_agent" {
  family                   = "tfc_agent"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  task_role_arn            = aws_iam_role.tfc_agent.arn
  execution_role_arn       = aws_iam_role.tfc_agent.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": 2048,
    "image": "hashicorp/tfc-agent:latest",
    "memory": 4096,
    "name": "tfc_agent",
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/aws/ecs/tfc_agent",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "tfc_agent",
        "awslogs-create-group": "true"
      }
    },
    "environment": [
      {
        "name": "TFC_AGENT_NAME",
        "value": "tfc-agent-aws-${random_id.this.hex}"
      },
      {
        "name": "TFC_AGENT_TOKEN",
        "value": "${tfe_agent_token.aws.token}"
      }
    ]
  }
]
DEFINITION

}

resource "aws_ecs_service" "tfc_agent" {
  name            = "tfc_agent"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.tfc_agent.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 80
  }

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.tfc_agent.id]
  }
}
