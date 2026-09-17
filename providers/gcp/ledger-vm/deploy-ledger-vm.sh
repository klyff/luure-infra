#!/usr/bin/env bash
# =============================================================================
# LEGADO — e2-medium sem Postgres. Lab novo: providers/gcp/lab-min/
# =============================================================================
# Luure — REAL Hyperledger Indy ledger on a low-cost GCE VM
# =============================================================================
# Provisions a single small Compute Engine VM (Ubuntu 22.04 + Docker) that runs
# the von-network Indy ledger + two ACA-Py agents (issuer/verifier), bootstraps
# the ledger (schema + cred-def + revocation registry), and prints the on-ledger
# IDs. Then point the Cloud Run `backend-api` at it with MOCK_ACAPY=false.
#
# Cost posture: e2-medium, scale-to-zero is NOT possible for a VM, so STOP it
# when idle:  gcloud compute instances stop indy-ledger --zone ZONE
#
# Security posture (MVP):
#   * 9000 (genesis/UI), 8000 + 8010 (DIDComm inbound) are PUBLIC (0.0.0.0/0).
#   * 8001 + 8011 (admin) are protected by a strong ACAPY_ADMIN_API_KEY. Cloud
#     Run egress IPs are dynamic, so without a Serverless VPC connector + Cloud
#     NAT static egress we cannot pin the firewall source to Cloud Run. The
#     admin ports are therefore reachable but require the API key. Tighten with
#     a VPC connector for production (see ADR-005).
#
# Usage:  ./infra/ledger-vm/deploy-ledger-vm.sh
# Re-runnable. Requires gcloud authenticated with project access + billing.
# =============================================================================
set -euo pipefail

PROJECT="${PROJECT:-sp-identity-trust}"
REGION="${REGION:-southamerica-east1}"
ZONE="${ZONE:-southamerica-east1-a}"
VM="${VM:-indy-ledger}"
MACHINE="${MACHINE:-e2-medium}"          # 2 vCPU / 4GB — von 4 nodes + 2 ACA-Py
DISK_GB="${DISK_GB:-30}"
SA="indy-ledger-vm@${PROJECT}.iam.gserviceaccount.com"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"

echo "==> Project ${PROJECT} / zone ${ZONE} / machine ${MACHINE}"
gcloud config set project "${PROJECT}" >/dev/null

# --- 1. APIs + dedicated minimal service account --------------------------
gcloud services enable compute.googleapis.com secretmanager.googleapis.com

gcloud iam service-accounts describe "${SA}" >/dev/null 2>&1 || \
  gcloud iam service-accounts create indy-ledger-vm \
    --display-name "Indy Ledger VM (minimal scope)"

# --- 2. Firewall ----------------------------------------------------------
# Public: von-network genesis/UI (9000) + DIDComm inbound (8000, 8010).
gcloud compute firewall-rules describe indy-ledger-public >/dev/null 2>&1 || \
  gcloud compute firewall-rules create indy-ledger-public \
    --network=default --direction=INGRESS --action=ALLOW \
    --rules=tcp:9000,tcp:8000,tcp:8010 \
    --source-ranges=0.0.0.0/0 --target-tags=indy-ledger

# Admin: 8001/8011 — API-key protected. Source range as tight as feasible
# (Cloud Run egress is dynamic ⇒ 0.0.0.0/0 for the MVP). Override ADMIN_SRC to
# tighten once a static egress IP exists.
ADMIN_SRC="${ADMIN_SRC:-0.0.0.0/0}"
gcloud compute firewall-rules describe indy-ledger-admin >/dev/null 2>&1 || \
  gcloud compute firewall-rules create indy-ledger-admin \
    --network=default --direction=INGRESS --action=ALLOW \
    --rules=tcp:8001,tcp:8011 \
    --source-ranges="${ADMIN_SRC}" --target-tags=indy-ledger

# --- 3. VM ----------------------------------------------------------------
if ! gcloud compute instances describe "${VM}" --zone "${ZONE}" >/dev/null 2>&1; then
  gcloud compute instances create "${VM}" \
    --zone="${ZONE}" \
    --machine-type="${MACHINE}" \
    --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud \
    --boot-disk-size="${DISK_GB}GB" --boot-disk-type=pd-balanced \
    --service-account="${SA}" \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only \
    --tags=indy-ledger \
    --metadata-from-file=startup-script="${HERE}/startup-script.sh"
fi

EXTERNAL_IP="$(gcloud compute instances describe "${VM}" --zone "${ZONE}" \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "==> VM external IP: ${EXTERNAL_IP}"

# --- 4. Wait for Docker (startup-script) ----------------------------------
echo "==> Waiting for Docker to be installed by the startup script ..."
for _ in $(seq 1 40); do
  if gcloud compute ssh "${VM}" --zone "${ZONE}" --command "docker compose version" >/dev/null 2>&1; then
    echo "==> Docker ready."; break
  fi
  sleep 15
done

# --- 5. Ship the ledger stack + generate VM-local .env --------------------
gcloud compute ssh "${VM}" --zone "${ZONE}" --command "mkdir -p ~/ledger-vm/ledger"
gcloud compute scp --zone "${ZONE}" --recurse "${ROOT}/ledger/." "${VM}:~/ledger-vm/ledger/"
gcloud compute scp --zone "${ZONE}" "${HERE}/docker-compose.ledger.yml" "${VM}:~/ledger-vm/docker-compose.ledger.yml"

# Generate strong secrets and write the VM-local .env (never leaves the VM).
ADMIN_KEY="$(openssl rand -hex 32)"
ISSUER_KEY="$(openssl rand -hex 32)"
VERIFIER_KEY="$(openssl rand -hex 32)"
gcloud compute ssh "${VM}" --zone "${ZONE}" --command "cat > ~/ledger-vm/.env <<EOF
ISSUER_WALLET_KEY=${ISSUER_KEY}
VERIFIER_WALLET_KEY=${VERIFIER_KEY}
ACAPY_ADMIN_API_KEY=${ADMIN_KEY}
ISSUER_ENDPOINT=http://${EXTERNAL_IP}:8000
VERIFIER_ENDPOINT=http://${EXTERNAL_IP}:8010
ISSUER_SEED=000000000000000000000000Steward1
EOF
chmod 600 ~/ledger-vm/.env"

# --- 6. Bring the stack up + bootstrap the ledger -------------------------
gcloud compute ssh "${VM}" --zone "${ZONE}" --command "cd ~/ledger-vm && \
  sudo docker compose --env-file .env -f docker-compose.ledger.yml up -d && \
  echo 'waiting for von-network + ACA-Py healthchecks ...' && sleep 60 && \
  sudo docker compose -f docker-compose.ledger.yml ps"

gcloud compute ssh "${VM}" --zone "${ZONE}" --command "cd ~/ledger-vm && \
  python3 -m venv .venv && . .venv/bin/activate && \
  pip install -q -r ledger/requirements.txt && \
  set -a && . ./.env && set +a && \
  ACAPY_ISSUER_ADMIN_URL=http://localhost:8001 \
  VON_WEBSERVER_URL=http://localhost:9000 \
  python ledger/setup.py && cat ledger/bootstrap-output.json"

echo
echo "================= LEDGER READY ================="
echo "genesis      http://${EXTERNAL_IP}:9000/genesis"
echo "von UI       http://${EXTERNAL_IP}:9000"
echo "issuer admin http://${EXTERNAL_IP}:8001  (X-API-KEY required)"
echo "verifier adm http://${EXTERNAL_IP}:8011  (X-API-KEY required)"
echo
echo "Store the admin API key in Secret Manager and wire Cloud Run:"
echo "  printf '%s' '<ADMIN_KEY>' | gcloud secrets create acapy-admin-api-key --data-file=-"
echo "  gcloud run services update backend-api --region ${REGION} \\"
echo "    --update-env-vars MOCK_ACAPY=false,ACAPY_ISSUER_ADMIN_URL=http://${EXTERNAL_IP}:8001,ACAPY_VERIFIER_ADMIN_URL=http://${EXTERNAL_IP}:8011 \\"
echo "    --set-secrets ACAPY_ADMIN_API_KEY=acapy-admin-api-key:latest"
echo
echo "STOP the VM when idle to pause cost:"
echo "  gcloud compute instances stop ${VM} --zone ${ZONE}"
