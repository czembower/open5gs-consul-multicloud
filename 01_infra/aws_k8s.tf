module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = "eks-cluster-${random_id.this.hex}"

  cluster_endpoint_public_access = false

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
      })
    }
  }

  vpc_id                                = module.vpc.vpc_id
  subnet_ids                            = module.vpc.private_subnets
  control_plane_subnet_ids              = module.vpc.private_subnets
  cluster_additional_security_group_ids = [aws_security_group.eks_additional.id]

  eks_managed_node_groups = {
    blue = {
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
    green = {
      min_size     = 2
      max_size     = 10
      desired_size = 3

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }

  # fargate_profiles = {
  #   default = {
  #     name = "default"
  #     selectors = [
  #       {
  #         namespace = "*"
  #       }
  #     ]
  #   }
  # }
}

resource "aws_security_group" "eks_additional" {
  name        = "eks-addtl-${random_id.this.hex}"
  description = "eks-addtl-${random_id.this.hex}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_jump.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.tfc_agent.id]
  }
}
