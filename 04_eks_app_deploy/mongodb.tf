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
---
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
      passwordSecretRef: # a reference to the secret that will be used to generate the user's password
        name: my-user-password
      roles:
        - name: clusterAdmin
          db: admin
        - name: userAdminAnyDatabase
          db: admin
      scramCredentialsSecretName: my-scram
  additionalMongodConfig:
    storage.wiredTiger.engineConfig.journalCompressor: zlib

# the user credentials will be generated from this secret
# once the credentials are generated, this secret is no longer required
---
apiVersion: v1
kind: Secret
metadata:
  name: my-user-password
type: Opaque
stringData:
  password: <your-password-here>
YAML
  )

  depends_on = [
    helm_release.mongodb_operator
  ]
}
