#!/bin/bash
# First-boot (and reboot-safe) provision for luure-lab ledger VM.
set -euxo pipefail

META=http://metadata.google.internal/computeMetadata/v1
meta() { curl -sf -H "Metadata-Flavor: Google" "$META/$1"; }

PROJECT="$(meta instance/attributes/project-id)"
ENV_NAME="$(meta instance/attributes/environment || echo lab)"
DB_USER="$(meta instance/attributes/db-user || echo luure)"
DB_APP="$(meta instance/attributes/db-app-name || echo app_data)"
EXTERNAL_IP="$(meta instance/network-interfaces/0/access-configs/0/external-ip)"
INTERNAL_IP="$(meta instance/network-interfaces/0/ip)"

# ── data disk ──────────────────────────────────────────────────────────────
DATA_DEV=/dev/disk/by-id/google-data-disk
if ! blkid "$DATA_DEV" >/dev/null 2>&1; then
  mkfs.ext4 -F "$DATA_DEV"
fi
mkdir -p /data
grep -q "$DATA_DEV" /etc/fstab || echo "$DATA_DEV /data ext4 defaults 0 2" >> /etc/fstab
mount -a
mkdir -p /data/{ledger,postgres,redis,tails}

# ── Docker ─────────────────────────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
if ! command -v docker >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release python3
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
fi

# ── compose files from instance metadata ───────────────────────────────────
ROOT=/opt/luure
mkdir -p "$ROOT/compose/postgres/initdb" "$ROOT/compose/nginx"
meta instance/attributes/compose-b64 | base64 -d > "$ROOT/compose/docker-compose.yml"
meta instance/attributes/nginx-b64 | base64 -d > "$ROOT/compose/nginx/nginx.conf"
meta instance/attributes/initdb-01-b64 | base64 -d > "$ROOT/compose/postgres/initdb/01-create-logical-databases.sh"
meta instance/attributes/initdb-02-b64 | base64 -d > "$ROOT/compose/postgres/initdb/02-app-schema.sql"
meta instance/attributes/initdb-03-b64 | base64 -d > "$ROOT/compose/postgres/initdb/03-app-seed.sql"
chmod 0755 "$ROOT/compose/postgres/initdb/01-create-logical-databases.sh"

# ── secrets from Secret Manager (access token, no gcloud) ──────────────────
TOKEN="$(meta instance/service-accounts/default/token | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')"
sm_get() {
  local name="$1"
  curl -sf -H "Authorization: Bearer ${TOKEN}" \
    "https://secretmanager.googleapis.com/v1/projects/${PROJECT}/secrets/luure-${ENV_NAME}-${name}/versions/latest:access" \
    | python3 -c 'import sys,json,base64; print(base64.b64decode(json.load(sys.stdin)["payload"]["data"]).decode())'
}

DB_PASSWORD="$(sm_get db-password)"
ACAPY_ADMIN_API_KEY="$(sm_get acapy-admin-api-key)"
ISSUER_WALLET_KEY="$(sm_get issuer-wallet-key)"
VERIFIER_WALLET_KEY="$(sm_get verifier-wallet-key)"

umask 077
cat > "$ROOT/compose/.env" <<EOF
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_APP_NAME=${DB_APP}
DB_ISSUER_WALLET_NAME=issuer_wallet
DB_VERIFIER_WALLET_NAME=verifier_wallet
ISSUER_WALLET_KEY=${ISSUER_WALLET_KEY}
VERIFIER_WALLET_KEY=${VERIFIER_WALLET_KEY}
ACAPY_ADMIN_API_KEY=${ACAPY_ADMIN_API_KEY}
ISSUER_ENDPOINT=http://${EXTERNAL_IP}:8000
VERIFIER_ENDPOINT=http://${EXTERNAL_IP}:8010
TAILS_BASE_URL=http://${EXTERNAL_IP}:6543
DOCKERHOST=host-gateway
EOF
chmod 600 "$ROOT/compose/.env"

# ── stack ──────────────────────────────────────────────────────────────────
cd "$ROOT/compose"
docker compose --env-file .env -f docker-compose.yml pull || true
docker compose --env-file .env -f docker-compose.yml up -d

echo "=== luure lab-min ready  ext=${EXTERNAL_IP}  int=${INTERNAL_IP} ==="
echo "=== genesis http://${EXTERNAL_IP}/genesis ==="
echo "=== stop when idle: gcloud compute instances stop luure-${ENV_NAME}-ledger ==="
