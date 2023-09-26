// cowboysysop https://cowboysysop.github.io/charts/

resource "helm_release" "vpa" {
  name       = "vpa"
  namespace  = "kube-system"
  repository = "https://cowboysysop.github.io/charts/"
  chart      = "vertical-pod-autoscaler"

  depends_on = [
    helm_release.metrics_server
  ]
}

resource "kubernetes_manifest" "vault_vpa" {
  manifest = yamldecode(<<YAML
apiVersion: "autoscaling.k8s.io/v1"
kind: VerticalPodAutoscaler
metadata:
  name: vault-vpa
  namespace: vault
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: vault-agent-injector
  resourcePolicy:
    containerPolicies:
      - containerName: '*'
        minAllowed:
          cpu: 100m
          memory: 50Mi
        maxAllowed:
          cpu: 1
          memory: 500Mi
        controlledResources: ["cpu", "memory"]
YAML
  )

  depends_on = [
    helm_release.vault
  ]
}

resource "kubernetes_manifest" "consul_server_vpa" {
  manifest = yamldecode(<<YAML
apiVersion: "autoscaling.k8s.io/v1"
kind: VerticalPodAutoscaler
metadata:
  name: consul-vpa
  namespace: consul
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: StatefulSet
    name: consul-consul-server
  resourcePolicy:
    containerPolicies:
      - containerName: '*'
        minAllowed:
          cpu: 100m
          memory: 200Mi
        maxAllowed:
          cpu: 1
          memory: 500Mi
        controlledResources: ["cpu", "memory"]
YAML
  )

  depends_on = [
    helm_release.consul
  ]
}
