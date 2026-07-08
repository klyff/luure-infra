#!/usr/bin/env bash
# dehydrate-vm.sh — Reduce voce-br-vm public surface after Luure frontends move to Vercel.
#
# Run ON THE VM (or via gcloud compute ssh ... --command 'bash -s' < dehydrate-vm.sh):
#   GCP_PROJECT_ID=sp-identity-trust ZONE=southamerica-east1-b \
#     gcloud compute ssh voce-br-vm --zone="$ZONE" --project="$GCP_PROJECT_ID" \
#     --tunnel-through-iap --command 'sudo bash -s' < scripts/dehydrate-vm.sh
#
# What it does:
#   1. Stops host nginx (no more HTTPS/HTTP reverse proxy for portals)
#   2. Stops frontend Docker services (portal-*)
#   3. Leaves ledger Indy, ACA-Py agents, Postgres/PgBouncer, Redis, API, tails-server running
#   4. Prints gcloud commands to resize the VM to e2-small (manual step; requires project IAM)
#
# Options:
#   DRY_RUN=1     — print actions only
#   COMPOSE_DIR   — default /opt/voce-br
#   COMPOSE_FILE  — default docker-compose.prod.yml
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
COMPOSE_DIR="${COMPOSE_DIR:-/opt/voce-br}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
COMPOSE_PATH="${COMPOSE_DIR}/${COMPOSE_FILE}"

PROJECT="${GCP_PROJECT_ID:-sp-identity-trust}"
ZONE="${ZONE:-southamerica-east1-b}"
VM_NAME="${VM_NAME:-voce-br-vm}"
TARGET_MACHINE_TYPE="${TARGET_MACHINE_TYPE:-e2-small}"

# Matches docker-compose.prod.yml portal services on voce-br-vm (poc-indy-sp layout).
FRONTEND_SERVICES=(
  portal-voce-br
  portal-efolha
  portal-gestao
  portal-wallet
  portal-licencas
  portal-conselhos
  portal-licitacoes
  portal-cidadao
  portal-cras
  portal-esocial
  portal-rh
)

KEEP_SERVICES=(
  von-network
  tails-server
  acapy-issuer-poc1
  acapy-issuer-poc2
  acapy-issuer-poc3
  acapy-issuer-poc4
  acapy-verifier
  api
  postgres
  pgbouncer
  redis
)

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] $*"
  else
    echo "+ $*"
    eval "$@"
  fi
}

echo "=== Luure VM dehydration: ${VM_NAME} (${ZONE}) ==="
echo "Compose: ${COMPOSE_PATH}"
echo "DRY_RUN=${DRY_RUN}"
echo ""

if [[ ! -f "$COMPOSE_PATH" ]]; then
  echo "ERROR: ${COMPOSE_PATH} not found. Adjust COMPOSE_DIR/COMPOSE_FILE." >&2
  exit 1
fi

echo "=== 1. Stop nginx (host) ==="
run "sudo systemctl stop nginx"
run "sudo systemctl disable nginx || true"

echo ""
echo "=== 2. Stop frontend containers ==="
svc_list="${FRONTEND_SERVICES[*]}"
run "cd '${COMPOSE_DIR}' && sudo docker compose -f '${COMPOSE_FILE}' stop ${svc_list}"

echo ""
echo "=== 3. Verify kept services still running ==="
for s in "${KEEP_SERVICES[@]}"; do
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] sudo docker compose ps ${s}"
  else
    if sudo docker compose -f "$COMPOSE_PATH" ps --status running --services 2>/dev/null | grep -qx "$s"; then
      echo "  OK running: ${s}"
    else
      echo "  WARN not running (expected up): ${s}" >&2
    fi
  fi
done

if [[ "$DRY_RUN" != "1" ]]; then
  echo ""
  echo "=== docker compose ps (summary) ==="
  sudo docker compose -f "$COMPOSE_PATH" ps
fi

echo ""
echo "=== 4. Resize VM to ${TARGET_MACHINE_TYPE} (run from workstation with GCP access) ==="
cat <<EOF
# Stop VM before changing machine type:
gcloud compute instances stop ${VM_NAME} \\
  --zone=${ZONE} \\
  --project=${PROJECT}

# Downsize (voce-br-vm doc baseline was e2-standard-2; terraform default e2-standard-4):
gcloud compute instances set-machine-type ${VM_NAME} \\
  --zone=${ZONE} \\
  --project=${PROJECT} \\
  --machine-type=${TARGET_MACHINE_TYPE}

# Start VM (ledger/ACA-Py/Postgres containers should resume via restart policy):
gcloud compute instances start ${VM_NAME} \\
  --zone=${ZONE} \\
  --project=${PROJECT}

# Optional: confirm external IP unchanged (terraform static IP voce-br-static-ip):
gcloud compute instances describe ${VM_NAME} \\
  --zone=${ZONE} \\
  --project=${PROJECT} \\
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
EOF

echo ""
echo "=== 5. Post-dehydration checks (from your laptop) ==="
cat <<'EOF'
# Nginx should be down — direct IP may refuse connection on :443 or show no vhost:
curl -skI --connect-timeout 5 https://34.39.174.212/ || true

# Ledger/API still reachable if you keep DNS or use Host header + IP:
curl -skI -H 'Host: ledger.smartecm.io' https://34.39.174.212/genesis
curl -sk -H 'Host: api.smartecm.io' https://34.39.174.212/health

# Frontends on Vercel — not this VM:
# https://voce.luure.com.br (etc.)
EOF

echo ""
echo "=== Dehydration script finished ==="
