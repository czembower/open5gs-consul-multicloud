#!/bin/bash

apt-get update -y 
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io jq xxd

apt-get autoremove -y

docker pull hashicorp/tfc-agent:latest
docker run -e TFC_AGENT_TOKEN="${TFC_AGENT_TOKEN}" -e TFC_AGENT_NAME="${TFC_AGENT_NAME}" hashicorp/tfc-agent:latest

while pgrep tfc-agent > /dev/null; do sleep 5; done
shutdown -Ph now