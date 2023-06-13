module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = "eks-cluster"

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

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "*"
        }
      ]
    }
  }
}
