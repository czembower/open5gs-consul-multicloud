resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      [
        {
          rolearn  = "${data.terraform_remote_state.infra.outputs.jump_iam_role}"
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
        [for group in data.terraform_remote_state.infra.outputs.eks_managed_node_groups : {
          rolearn  = group.iam_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups = [
            "system:bootstrappers",
            "system:nodes"
          ]
          }
        ]
      ]
    )
  }
}
