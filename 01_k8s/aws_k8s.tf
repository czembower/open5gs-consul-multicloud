data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = "eks-cluster-${data.terraform_remote_state.base.outputs.random_id}"

  cluster_endpoint_public_access = false

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.AmazonEKS_EBS_CSI_Driver.arn
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

  vpc_id                                = data.terraform_remote_state.base.outputs.aws_vpc.vpc_id
  subnet_ids                            = data.terraform_remote_state.base.outputs.aws_vpc.private_subnets
  control_plane_subnet_ids              = data.terraform_remote_state.base.outputs.aws_vpc.private_subnets
  cluster_additional_security_group_ids = [aws_security_group.eks_additional.id]
  # iam_role_additional_policies = {
  #   AmazonEBSCSIDriverPolicy = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  # }

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

resource "aws_iam_role" "AmazonEKS_EBS_CSI_Driver" {
  name = "AmazonEKSEBSCSIDriverRole-${data.terraform_remote_state.base.outputs.random_id}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${module.eks.oidc_provider}:aud": "sts.amazonaws.com",
          "${module.eks.oidc_provider}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_EBS_CSI_Driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.AmazonEKS_EBS_CSI_Driver.name
}

resource "aws_security_group" "eks_additional" {
  name        = "eks-addtl-${data.terraform_remote_state.base.outputs.random_id}"
  description = "eks-addtl-${data.terraform_remote_state.base.outputs.random_id}"
  vpc_id      = data.terraform_remote_state.base.outputs.aws_vpc.vpc_id

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
    security_groups = [data.terraform_remote_state.base.outputs.tfc_agent_sg_id]
  }
}
