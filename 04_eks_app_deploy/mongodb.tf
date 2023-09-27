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

//consul.hashicorp.com/connect-inject: true

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
  statefulSet:
    metadata:
      annotations:
        consul.hashicorp.com/connect-inject: "true"
      labels:
        statefulSetLabelTest: testValue
    spec:
      selector:
        matchLabels:
          podTemplateLabelTest: testValue
      template:
        spec:
          containers:
            - name: mongodb-agent
              readinessProbe:
                exec:
                  command:
                    - curl
                    - http://localhost:27017
        metadata:
          annotations:
            consul.hashicorp.com/connect-inject: "true"
            consul.hashicorp.com/transparent-proxy-exclude-outbound-cidrs: "172.20.0.1/20"
          labels:
            podTemplateLabelTest: testValue
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
