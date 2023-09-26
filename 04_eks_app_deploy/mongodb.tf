resource "kubernetes_namespace" "mongodb" {
  metadata {
    annotations = {
      name = "mongodb"
    }
    name = "mongodb"
  }
}

resource "helm_release" "mongodb_operator" {
  name       = "mongodb-operator"
  namespace  = kubernetes_namespace.mongodb.metadata[0].name
  repository = "https://mongodb.github.io/helm-charts"
  chart      = "community-operator"

  depends_on = [
    helm_release.consul
  ]



}


resource "kubernetes_manifest" "mongodb" {
  manifest = yamldecode(<<YAML
apiVersion: mongodbcommunity.mongodb.com/v1
kind: MongoDBCommunity
metadata:
  name: mongodb
  namespace: mongodb
spec:
  members: 3
  type: ReplicaSet
  version: "6.0.5"
  security:
    authentication:
      modes: ["SCRAM"]
  users:
    - name: my-user
      db: admin
      passwordSecretRef:
        name: my-user-password
      roles:
        - name: clusterAdmin
          db: admin
        - name: userAdminAnyDatabase
          db: admin
      scramCredentialsSecretName: my-scram
  additionalMongodConfig:
    storage.wiredTiger.engineConfig.journalCompressor: zlib
YAML
  )

  wait {
    rollout = true
  }

  depends_on = [
    helm_release.mongodb_operator,
    kubernetes_manifest.mongodb_user_secret
  ]
}

resource "kubernetes_manifest" "mongodb_user_secret" {
  computed_fields = ["stringData"]

  manifest = yamldecode(<<YAML
apiVersion: v1
kind: Secret
metadata:
  name: my-user-password
  namespace: mongodb
type: Opaque
stringData:
  password: <your-password-here>
YAML
  )

  depends_on = [
    helm_release.mongodb_operator
  ]
}
