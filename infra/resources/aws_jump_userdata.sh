#!/bin/bash

apt-get update -y 
apt-get install -y awscli jq
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
/usr/bin/aws eks update-kubeconfig --region ${region} --name ${eks_cluster_name}