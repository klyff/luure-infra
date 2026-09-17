#!/usr/bin/env bash
# Fase 2 — ledger: Postgres via IAP, ACA-Py admin com API key, tails.
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need gcloud
require_luure_cli

echo "== Fase 2 — ledger (project=$PROJECT) =="
failed=0
VM="${NAME}-ledger"

if ! gcloud compute instances describe "$VM" --zone="$ZONE" --project="$PROJECT" >/dev/null 2>&1; then
  echo "Fase 2: VM missing. Run Fase 1 / terraform apply first." >&2
  exit 1
fi

ssh_cmd() {
  gcloud compute ssh "$VM" --zone="$ZONE" --project="$PROJECT" --tunnel-through-iap --command="$1"
}

if ssh_cmd "docker compose -f /opt/luure/compose/docker-compose.yml ps --format json" >/dev/null 2>&1; then
  pass "compose reachable over IAP"
else
  fail "cannot ssh/IAP to compose on $VM" || failed=1
fi

if ssh_cmd "pg_isready -h 127.0.0.1 -p 5432 || docker exec \$(docker ps -qf name=postgres) pg_isready" >/dev/null 2>&1; then
  pass "Postgres :5432 accepting"
else
  fail "Postgres :5432 not ready" || failed=1
fi

# Admin must require the API key (R1). Open swagger without key is a fail.
admin_code="$(ssh_cmd "curl -sS -o /dev/null -w '%{http_code}' --max-time 10 http://127.0.0.1:8001/status" || echo 000)"
if [[ "$admin_code" == "401" || "$admin_code" == "403" ]]; then
  pass "ACA-Py issuer admin rejects unauthenticated ($admin_code)"
elif [[ "$admin_code" == "200" ]]; then
  fail "ACA-Py issuer admin is open without API key (R1)" || failed=1
else
  fail "ACA-Py issuer admin unexpected HTTP $admin_code" || failed=1
fi

KEY="$(gcloud secrets versions access latest --secret="${NAME}-acapy-admin-api-key" --project="$PROJECT" 2>/dev/null || true)"
if [[ -n "$KEY" ]]; then
  keyed="$(ssh_cmd "curl -sS -o /dev/null -w '%{http_code}' --max-time 10 -H 'X-API-KEY: ${KEY}' http://127.0.0.1:8001/status" || echo 000)"
  if [[ "$keyed" == "200" ]]; then
    pass "ACA-Py issuer admin 200 with X-API-KEY"
  else
    fail "ACA-Py issuer admin with key → $keyed" || failed=1
  fi
else
  fail "cannot read ${NAME}-acapy-admin-api-key" || failed=1
fi

EXT="$(gcloud compute addresses describe "${NAME}-ledger-ip" --region="$REGION" --project="$PROJECT" --format='value(address)' 2>/dev/null || true)"
tails="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "http://${EXT}:6543/" || echo 000)"
if [[ "$tails" == "200" || "$tails" == "404" || "$tails" == "405" ]]; then
  pass "tails :6543 reachable (HTTP $tails)"
else
  fail "tails :6543 → $tails" || failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  echo "Fase 2 FAILED"
  exit 1
fi
echo "Fase 2 OK"
