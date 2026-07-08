#!/bin/bash
# infra/terraform-vm/scripts/startup.sh
# Executado pelo GCP na primeira inicialização da VM voce-br-vm.
set -euxo pipefail

GCP_PROJECT="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/GCP_PROJECT || echo '')"
REPO_URL="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/REPO_URL || echo 'https://github.com/klyff/luure-ledger')"
VM_EXTERNAL_IP="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip || echo '')"

# ── Montar disco de dados (idempotente) ────────────────────────────────────
DATA_DEV=/dev/disk/by-id/google-data-disk
if ! blkid "$DATA_DEV"; then
  mkfs.ext4 -F "$DATA_DEV"
fi
mkdir -p /data
grep -q "$DATA_DEV" /etc/fstab || echo "$DATA_DEV /data ext4 defaults 0 2" >> /etc/fstab
mount -a
mkdir -p /data/{ledger,postgres,redis,tails,certs}

# ── Docker + Compose plugin ────────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release git

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io \
                   docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# ── Nginx + Certbot ────────────────────────────────────────────────────────
apt-get install -y nginx certbot python3-certbot-nginx

# Diretório destino do código (enviado por scripts/deploy.sh via scp/IAP).
mkdir -p /opt/voce-br

echo "=== Luure VM provisionada (Docker+Nginx+disco). IP=${VM_EXTERNAL_IP}. ==="
echo "=== Rode scripts/deploy.sh na sua máquina para enviar o código e subir. ==="
