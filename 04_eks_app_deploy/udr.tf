resource "kubernetes_namespace" "free5gc_udr" {
  metadata {
    annotations = {
      name = "free5gc-udr"
    }
    name = "free5gc-udr"
  }
}

resource "helm_release" "free5gc_udr" {
  name       = "udr"
  namespace  = kubernetes_namespace.free5gc_udr.metadata[0].name
  repository = "https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/"
  chart      = "free5gc-udr"
  wait       = false

  depends_on = [
    helm_release.consul,
    helm_release.free5gc_nrf
  ]

  set {
    name  = "udr.image.tag"
    value = "latest"
  }

  set {
    name  = "udr.replicaCount"
    value = 2
  }

  set {
    name  = "global.nrf.service.name"
    value = "nrf-nnrf.${kubernetes_namespace.free5gc_nrf.metadata[0].name}.svc.cluster.local"
  }

  set {
    name  = "udr.podAnnotations.consul\\.hashicorp\\.com/connect-inject"
    value = "true"
    type  = "string"
  }
}

resource "null_resource" "k8s_patcher" {
  triggers = {
    endpoint = data.aws_eks_cluster.this.endpoint
    ca_crt   = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    release  = helm_release.free5gc_udr.metadata[0].values
  }

  depends_on = [
    helm_release.free5gc_udr
  ]

  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca.crt <<EOF
${base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)}
EOF
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x ./kubectl && \
./kubectl \
  --server="${data.aws_eks_cluster.this.endpoint}" \
  --certificate_authority=/tmp/ca.crt \
  --token="${data.aws_eks_cluster_auth.this.token}" \
  patch deployment udr-free5gc-udr-udr \
  -n free5gc-udr \
  --patch '{"spec": {"template": {"spec": {"initContainers": null }}}}'
EOH
  }
}

// kubectl patch deployment -n free5gc-udr udr-free5gc-udr-udr --patch '{"spec": {"template": {"spec": {"initContainers": null }}}}'
