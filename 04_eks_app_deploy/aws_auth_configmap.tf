resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      [
        {
          rolearn  = "${data.terraform_remote_state.eks.outputs.jump_iam_role}"
          username = "jump:{{SessionName}}"
          groups = [
            "system:masters"
          ]
        },
        # {
        #   rolearn  = "${data.terraform_remote_state.infra.outputs.fargate_profiles.default.fargate_profile_pod_execution_role_arn}"
        #   username = "system:node:{{SessionName}}"
        #   groups = [
        #     "system:bootstrappers",
        #     "system:nodes",
        #     "system:node-proxier"
        #   ]
        # },
        {
          rolearn  = data.terraform_remote_state.eks.outputs.eks_managed_node_groups.blue.iam_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups = [
            "system:bootstrappers",
            "system:nodes"
          ]
        },
        {
          rolearn  = data.terraform_remote_state.eks.outputs.eks_managed_node_groups.green.iam_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups = [
            "system:bootstrappers",
            "system:nodes"
          ]
        }
      ]
    ))
  }
}
