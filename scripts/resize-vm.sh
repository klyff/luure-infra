#!/usr/bin/env bash
# resize-vm.sh — Downsize voce-br-vm after Luure frontends move to Vercel.
#
# Run from a workstation with GCP IAM (compute.instances.stop/start/setMachineType):
#   GCP_PROJECT_ID=sp-identity-trust ZONE=southamerica-east1-b \
#     ./scripts/resize-vm.sh
#
# Prerequisite: run scripts/dehydrate-vm.sh on the VM first (nginx + portal containers stopped).
#
# Options:
#   DRY_RUN=1              — print gcloud commands only
#   VM_NAME                — default voce-br-vm
#   TARGET_MACHINE_TYPE    — default e2-small
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
PROJECT="${GCP_PROJECT_ID:-sp-identity-trust}"
ZONE="${ZONE:-southamerica-east1-b}"
VM_NAME="${VM_NAME:-voce-br-vm}"
TARGET_MACHINE_TYPE="${TARGET_MACHINE_TYPE:-e2-small}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] $*"
  else
    echo "+ $*"
    "$@"
  fi
}

echo "=== Resize ${VM_NAME} → ${TARGET_MACHINE_TYPE} (${ZONE}, ${PROJECT}) ==="
echo ""

echo "=== 1. Stop VM ==="
run gcloud compute instances stop "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT"

echo ""
echo "=== 2. Set machine type ==="
run gcloud compute instances set-machine-type "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT" \
  --machine-type="$TARGET_MACHINE_TYPE"

echo ""
echo "=== 3. Start VM ==="
run gcloud compute instances start "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT"

echo ""
echo "=== 4. Confirm external IP (static: voce-br-static-ip) ==="
if [[ "$DRY_RUN" == "1" ]]; then
  echo "[dry-run] gcloud compute instances describe ${VM_NAME} --format='get(networkInterfaces[0].accessConfigs[0].natIP)'"
else
  ip=$(gcloud compute instances describe "$VM_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
  echo "  natIP=${ip}"
fi

echo ""
echo "=== 5. Post-resize checks ==="
cat <<'EOF'
# Ledger genesis via IP + Host header:
curl -skI -H 'Host: ledger.smartecm.io' https://34.39.174.212/genesis

# API health:
curl -sk -H 'Host: api.smartecm.io' https://34.39.174.212/health

# Full migration validation (sovereignID.io repo):
./scripts/validate-luure-migration.sh
EOF

echo ""
echo "=== Resize finished ==="
