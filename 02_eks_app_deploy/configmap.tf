resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    "mapRoles" : "- groups:\n  - system:masters\n  rolearn: ${data.terraform_remote_state.infra.outputs.jump_iam_role}\n  username: jump\n"
  }

  force = true
}
