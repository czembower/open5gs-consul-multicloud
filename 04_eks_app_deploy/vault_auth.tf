## Auth Methods ###

data "tls_certificate" "eks_ca" {
  content = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_data.ca_data)
}

data "external" "pubkey_conversion" {
  program = ["jq", "-n", "--arg", "pubkey", "$(echo ${chomp(data.tls_certificate.eks_ca.certificates[0].cert_pem)}", "|", "base64", "-d", "|", "openssl", "x509", "-noout", "-pubkey", "|", "awk", "'{printf \"%s\n\", $0}')\"", "'{\"public_key_pem\":$pubkey}'"]
}

//${chomp(data.tls_certificate.eks_ca.certificates[0].cert_pem)}
//jq -n --arg pubkey "$(echo LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJYWlkREJtOHpzRXd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TXpBNU1qQXhOekk1TXpGYUZ3MHpNekE1TVRjeE56STVNekZhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURobkZ2SzkxRnZ4bWVSVUJOVWp2TS9IZ0kycWNHVHpWdm9DV1ljcVdDUXVjb2orT3Q2MTJ0U0Vnd1UKbU5OdjRGbTN1aXdrYXNaQyt3dVdvZUZKVmNoY2xiUWYyOU1QUHAvMlhaSFBJQ21FYjdPdzBiTFRZNndpVytYcgpjU1p5cU8xUFdkZkk2bDc3Z3QvSlBaYXRwbVJSUmpqNUMyQ0xGVElZdlVyS28xbHh6cytnOFVrbnJpcXVROUxlCnFCSUxtcC9ieXVsYzNJVnRJbGlnMTBqNmwvZ2ZIQVJIcEFOQ2NhcHl1QzZTeWNVVEl3cGh5NFZISlNLTHc4YmsKU0ZaS3cxc1FnQWl0c2I4RnJyQXk4dEdLWVlOcVNkSWxiWEtqN1Z6VlpvbVFiYUt4dkVUWE9mQXI3Z05VSStCOQpRczRQcTRPMjVNWGZVWERlcWFsR1Q0WlYzbWx2QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSVGVoNjk3Zy9xYk9HN3hpSkFxMlZ6b0w5T0N6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ3hBaUc0dnl4VQpzM0pnUEQxTGVraDhkL2tnOURGQ1VGTXg4VWpkTHgzOE8xTzZNMzJ3M1UyZ0xycnByajN5VE53RDRGaFVZaWpaCjJoUGJPdEJpRis2T0V2WnB3MUdMSFh4MHJXeFFjSnJJQklPakJyL1ZOeTE4M3oxaXh5OVNmdm5BVmZRYS9JclEKZTFsNjAzRzlqU3V5WS82bHU0YTBMTG10UlVCek9NUWE1Zm5ZSW1TUWk2VHF0cGxyQVVDaWxtVW1Ga3g5NERxVAp3Q0xzc3htdDZaNEZCaFFZWFFkdUhtYzRhY2hFVmR0Ynp0TlZzY0NTWnFsOEoxTm5uZUtud0xQNklDMlI0RFJlCkJHL3VoQUtSM1lGdGYrdDJQaTJYaTNkWndjWXh0cFFlVzJoTk53d2FVVFVBa05TNnVuYTAxSk9SRW5TbGhPQVkKZzdxRFdzNnEyQ0xECi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K | base64 -d | awk '{printf "%s\n", $0}')" '{"public_key_pem":$pubkey}'
//jq -n --arg pubkey "$(echo  | base64 -d | openssl x509 -noout -pubkey | awk '{printf "%s\n", $0}')" '{"public_key_pem":$pubkey}'

resource "vault_jwt_auth_backend" "this" {
  namespace              = "consul"
  description            = "JWT Auth Backend for Kubernetes"
  path                   = "kubernetes"
  jwt_validation_pubkeys = [data.external.pubkey_conversion.result]
}

resource "vault_jwt_auth_backend_role" "consul" {
  namespace       = "consul"
  backend         = vault_jwt_auth_backend.this.path
  role_name       = "consul"
  bound_audiences = ["https://kubernetes.default.svc"]
  user_claim      = "sub"
  role_type       = "jwt"
  token_ttl       = 3600
  token_type      = "default"
  token_policies  = ["consul"]
}
