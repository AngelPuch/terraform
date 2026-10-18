#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "=== 1. Limpiando rastros previos de repositorios rotos ==="
# Borra cualquier archivo .list que haga referencia a hashicorp sin importar como se llame
grep -rl "hashicorp" /etc/apt/sources.list.d/ 2>/dev/null | xargs -r rm -f
sed -i '/hashicorp/d' /etc/apt/sources.list 2>/dev/null || true
rm -f /etc/apt/keyrings/hashicorp* /usr/share/keyrings/hashicorp*

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release unzip git nano jq

echo "=== 2. Configurando repositorio oficial de Docker ==="
install -m 0755 -d /etc/apt/keyrings
rm -f /etc/apt/keyrings/docker.gpg

curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/docker.asc
rm -f /etc/apt/keyrings/docker.asc
chmod 0644 /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

echo "=== 3. Instalando Docker Engine ==="
apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "=== 4. Instalando Terraform (Binario Oficial) ==="
# Obtiene la última versión estable desde la API de HashiCorp y descarga el binario directo
TERRAFORM_VERSION=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /usr/local/bin/
chmod +x /usr/local/bin/terraform
rm -f /tmp/terraform.zip

echo "=== 5. Configurando permisos de Docker ==="
systemctl enable --now docker
usermod -aG docker vagrant

echo "=== 6. Comprobando instalaciones ==="
docker --version
docker compose version
terraform version

echo "=== Instalación completada con éxito ==="