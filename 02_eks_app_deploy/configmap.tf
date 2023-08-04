resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name = "auth-auth"
  }
  data = {
    "mapRoles" : "- groups:\n  - system:masters\n  rolearn: ${aws_iam_role.jump.arn}\n  username: jump\n"
  }
}
