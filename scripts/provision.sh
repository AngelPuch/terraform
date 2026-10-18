#!/bin/bash

echo "Instalando dependencias base..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release unzip git nano jq

echo "Configurando repositorios oficiales (Docker y HashiCorp)..."
sudo mkdir -m 0755 -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "Instalando Docker Engine y Terraform..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin terraform

echo "Habilitando servicio y permisos..."
sudo systemctl enable --now docker
sudo usermod -aG docker vagrant

echo "Listo. Versiones instaladas:"
docker --version
docker compose version
terraform --version