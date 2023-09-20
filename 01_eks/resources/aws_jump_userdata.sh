#!/bin/bash

apt-get update -y
apt-get install -y unzip jq
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && ./aws/install
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
snap install kubectl --classic
/usr/local/bin/aws eks update-kubeconfig --region ${region} --name ${eks_cluster_name}