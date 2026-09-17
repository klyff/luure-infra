#!/usr/bin/env bash
# Fase 3 — agent + dashday: /health, Monitoring TPC, /api/validations.
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need gcloud
need curl
require_luure_cli

echo "== Fase 3 — agent + dashday (project=$PROJECT) =="
failed=0

agent_url="$(gcloud run services describe "${NAME}-agent" --region="$REGION" --project="$PROJECT" --format='value(status.url)' 2>/dev/null || true)"
dash_url="$(gcloud run services describe "${NAME}-dashday" --region="$REGION" --project="$PROJECT" --format='value(status.url)' 2>/dev/null || true)"

if [[ -z "$agent_url" ]]; then
  fail "Cloud Run ${NAME}-agent missing" || failed=1
else
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 "${agent_url}/health" || echo 000)"
  if [[ "$code" == "200" ]]; then
    pass "GET ${agent_url}/health → 200"
  else
    fail "GET ${agent_url}/health → $code" || failed=1
  fi
fi

if [[ -z "$dash_url" ]]; then
  fail "Cloud Run ${NAME}-dashday missing" || failed=1
else
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 "${dash_url}/api/health" || echo 000)"
  if [[ "$code" == "200" ]]; then
    pass "GET ${dash_url}/api/health → 200"
  else
    fail "GET ${dash_url}/api/health → $code" || failed=1
  fi

  TOKEN="$(gcloud secrets versions access latest --secret="${NAME}-dash-token" --project="$PROJECT" 2>/dev/null || true)"
  val_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 \
    -H "Authorization: Bearer ${TOKEN}" "${dash_url}/api/validations" || echo 000)"
  if [[ "$val_code" == "200" ]]; then
    pass "GET /api/validations → 200 (empty table is ok)"
  else
    fail "GET /api/validations → $val_code" || failed=1
  fi
fi

if gcloud monitoring time-series list \
     --project="$PROJECT" \
     --filter='metric.type="run.googleapis.com/request_count"' \
     --format='value(metric.type)' 2>/dev/null | head -1 | grep -q request_count; then
  pass "Monitoring TPC (run.googleapis.com/request_count) queryable"
else
  # Fresh projects may have the API on but no series yet — API enabled is enough.
  if gcloud services list --enabled --filter='config.name:monitoring.googleapis.com' \
       --format='value(config.name)' --project="$PROJECT" 2>/dev/null | grep -q monitoring; then
    echo "  WARN  Monitoring API on; no request_count series yet (cold start / no traffic)"
    pass "Monitoring API enabled"
  else
    fail "Monitoring API / TPC query failed" || failed=1
  fi
fi

if [[ "$failed" -ne 0 ]]; then
  echo "Fase 3 FAILED"
  exit 1
fi
echo "Fase 3 OK — migração lab-min verificada"
