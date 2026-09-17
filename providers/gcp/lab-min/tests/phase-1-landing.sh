#!/usr/bin/env bash
# Fase 1 — landing + VM: APIs, VPC, VM RUNNING, secrets, genesis, schedule.
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need gcloud
require_luure_cli

echo "== Fase 1 — landing + VM (project=$PROJECT) =="
failed=0

for api in compute.googleapis.com run.googleapis.com secretmanager.googleapis.com \
           artifactregistry.googleapis.com monitoring.googleapis.com; do
  if gcloud services list --enabled --filter="config.name:$api" --format='value(config.name)' --project="$PROJECT" 2>/dev/null | grep -q "$api"; then
    pass "API $api"
  else
    fail "API $api not enabled" || failed=1
  fi
done

if gcloud compute networks describe "${NAME}-vpc" --project="$PROJECT" >/dev/null 2>&1; then
  pass "VPC ${NAME}-vpc"
else
  fail "VPC ${NAME}-vpc missing (apply lab-min first)" || failed=1
fi

if gcloud compute instances describe "${NAME}-ledger" --zone="$ZONE" --project="$PROJECT" \
     --format='value(status)' 2>/dev/null | grep -qx RUNNING; then
  pass "VM ${NAME}-ledger RUNNING"
else
  fail "VM ${NAME}-ledger not RUNNING" || failed=1
fi

for secret in db-password database-url acapy-admin-api-key issuer-jwk govbr-jwk dash-token; do
  if gcloud secrets describe "${NAME}-${secret}" --project="$PROJECT" >/dev/null 2>&1; then
    pass "secret ${NAME}-${secret}"
  else
    fail "secret ${NAME}-${secret} missing" || failed=1
  fi
done

EXT="$(gcloud compute addresses describe "${NAME}-ledger-ip" --region="$REGION" --project="$PROJECT" --format='value(address)' 2>/dev/null || true)"
if [[ -z "$EXT" ]]; then
  fail "static IP ${NAME}-ledger-ip missing" || failed=1
else
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "http://${EXT}/genesis" || echo 000)"
  if [[ "$code" == "200" ]]; then
    pass "GET http://${EXT}/genesis → 200"
  else
    fail "GET http://${EXT}/genesis → $code (want 200)" || failed=1
  fi
fi

if gcloud compute resource-policies describe "${NAME}-weekday-hours" --region="$REGION" --project="$PROJECT" >/dev/null 2>&1; then
  pass "idle schedule ${NAME}-weekday-hours"
else
  echo "  WARN  idle schedule missing (enable_idle_schedule=false?)"
fi

if [[ "$failed" -ne 0 ]]; then
  echo "Fase 1 FAILED"
  exit 1
fi
echo "Fase 1 OK"
