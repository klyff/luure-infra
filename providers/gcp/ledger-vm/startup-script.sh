#!/usr/bin/env bash
# =============================================================================
# Indy Ledger VM — startup script (Ubuntu 22.04 LTS)
# =============================================================================
# Installs Docker Engine + the docker compose plugin so the ledger stack
# (von-network + 2x ACA-Py) can run via `docker compose`. Idempotent: safe to
# re-run. Logs to /var/log/startup-script.log.
# =============================================================================
set -euo pipefail
exec > >(tee -a /var/log/startup-script.log) 2>&1
echo "==> startup-script begin $(date -u)"

export DEBIAN_FRONTEND=noninteractive

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "==> Docker + compose already present; nothing to do."
  exit 0
fi

apt-get update -y
apt-get install -y ca-certificates curl gnupg git

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# Allow the default login user to run docker without sudo (best-effort).
for u in ubuntu klyff; do
  id "$u" >/dev/null 2>&1 && usermod -aG docker "$u" || true
done

echo "==> startup-script done $(date -u)"
