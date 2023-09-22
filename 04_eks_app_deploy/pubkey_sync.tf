resource "kubernetes_config_map_v1" "pubkey_sync" {
  metadata {
    name = "pubkey-sync"
  }

  data = {
    "pubkey-sync.go" = "${file("${path.module}/resources/pubkey-sync/main.go")}"
  }
}

resource "kubernetes_service_account_v1" "pubkey_sync" {
  metadata {
    name = "pubkey-sync-sa"
  }
}

resource "kubernetes_cluster_role_v1" "pubkey_sync" {
  metadata {
    name = " pubkey-sync-role"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding_v1" "pubkey_sync" {
  metadata {
    name = "pubkey-sync-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_cluster_role_v1.pubkey_sync.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.pubkey_sync.metadata[0].name
    api_group = ""
  }
}

resource "kubernetes_pod_v1" "pubkey_sync" {
  metadata {
    name = "pubkey-sync"

    labels = {
      app = "pubkey-sync"
    }
  }

  spec {
    service_account_name = kubernetes_service_account_v1.pubkey_sync.metadata[0].name
    restart_policy       = "Always"

    container {
      image             = "golang:latest"
      name              = "golang"
      image_pull_policy = "IfNotPresent"
      command           = ["/bin/bash", "-c"]
      args              = ["mkdir -p /tmp/code && cp /code/pubkey-sync.go /tmp/code/main.go && cd /tmp/code && go mod init pubkey-sync && go mod tidy && go run main.go"]
      volume_mount {
        name       = "code-volume"
        mount_path = "/code"
      }
    }

    volume {
      name = "code-volume"
      config_map {
        name = kubernetes_config_map_v1.pubkey_sync.metadata[0].name
      }
    }
  }
}
