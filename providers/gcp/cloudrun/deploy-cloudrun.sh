#!/usr/bin/env bash
# =============================================================================
# LEGADO — FastAPI / portais Vite (MOCK_ACAPY). Não use para lab novo.
# Stack vigente: providers/gcp/lab-min/ + mvp/luure-agent-server Dockerfile.
# =============================================================================
# Luure — public Google Cloud Run deploy
# =============================================================================
# Deploys the demoable parts of the Hyperledger Indy SSI MVP to Cloud Run as
# PUBLIC services (scale-to-zero) in southamerica-east1:
#
#   backend-api      FastAPI (MOCK_ACAPY=true; ledger/ACA-Py not deployed)
#   frontend-efolha  Vite SPA portal (e-Folha)
#   frontend-gestao  Vite SPA portal (Gestão)
#   frontend-wallet  Vite SPA portal (Carteira)
#   webhook-handler  ACA-Py webhook → PostgreSQL/PgBouncer + SSE bridge
#
# Secrets live ONLY in Secret Manager (never committed):
#   jwt-secret, cpf-hash-salt, app-data-db-url
#
# Re-runnable: builds images via Cloud Build, (re)deploys, re-applies the public
# IAM binding, and rewires CORS. Requires: gcloud authenticated with access to
# the project, billing enabled.
#
# Usage:  ./infra/cloudrun/deploy-cloudrun.sh
# =============================================================================
set -euo pipefail

PROJECT="${PROJECT:-sp-identity-trust}"
REGION="${REGION:-southamerica-east1}"
REPO_HOST="${REGION}-docker.pkg.dev"
REPO="${REPO_HOST}/${PROJECT}/luure"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "==> Project ${PROJECT} / region ${REGION}"
gcloud config set project "${PROJECT}" >/dev/null

# --- 1. APIs --------------------------------------------------------------
gcloud services enable \
  run.googleapis.com artifactregistry.googleapis.com \
  cloudbuild.googleapis.com secretmanager.googleapis.com \
  orgpolicy.googleapis.com

# --- 2. Artifact Registry -------------------------------------------------
gcloud artifacts repositories describe luure --location="${REGION}" >/dev/null 2>&1 || \
  gcloud artifacts repositories create luure \
    --repository-format=docker --location="${REGION}" \
    --description="Luure images"

# --- 3. Secrets (Secret Manager) ------------------------------------------
# jwt-secret / cpf-hash-salt are generated; app-data-db-url is read from the
# local gitignored .env (DATABASE_URL_APP=...). For Cloud Run demos this must
# point to a reachable PostgreSQL/PgBouncer endpoint provisioned outside Cloud Run.
# NEVER hardcode the value here.
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT}" --format='value(projectNumber)')"
RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

ensure_secret() { # name value
  local name="$1" val="$2"
  if gcloud secrets describe "${name}" >/dev/null 2>&1; then
    printf '%s' "${val}" | gcloud secrets versions add "${name}" --data-file=- >/dev/null
  else
    printf '%s' "${val}" | gcloud secrets create "${name}" --data-file=- --replication-policy=automatic >/dev/null
  fi
  gcloud secrets add-iam-policy-binding "${name}" \
    --member="serviceAccount:${RUNTIME_SA}" \
    --role="roles/secretmanager.secretAccessor" --quiet >/dev/null
}

if ! gcloud secrets describe jwt-secret >/dev/null 2>&1; then
  ensure_secret jwt-secret "$(openssl rand -base64 48 | tr -d '\n')"
fi
if ! gcloud secrets describe cpf-hash-salt >/dev/null 2>&1; then
  ensure_secret cpf-hash-salt "$(openssl rand -base64 32 | tr -d '\n')"
fi
if [[ -f "${ROOT}/.env" ]]; then
  DB_APP="$(grep '^DATABASE_URL_APP=' "${ROOT}/.env" | cut -d= -f2-)"
  [[ -n "${DB_APP}" ]] && ensure_secret app-data-db-url "${DB_APP}"
fi

# --- 4. Cloud Build permissions for the runtime/build SA ------------------
for role in roles/cloudbuild.builds.builder roles/artifactregistry.writer \
            roles/storage.objectAdmin roles/logging.logWriter; do
  gcloud projects add-iam-policy-binding "${PROJECT}" \
    --member="serviceAccount:${RUNTIME_SA}" --role="${role}" \
    --condition=None --quiet >/dev/null
done

# --- 5. Allow public (allUsers) IAM bindings ------------------------------
# The org enforces Domain Restricted Sharing (iam.allowedPolicyMemberDomains),
# which blocks allUsers. Override it at project scope so Cloud Run can be public.
TMP_POLICY="$(mktemp)"
cat > "${TMP_POLICY}" <<EOF
name: projects/${PROJECT}/policies/iam.allowedPolicyMemberDomains
spec:
  rules:
  - allowAll: true
EOF
gcloud org-policies set-policy "${TMP_POLICY}" >/dev/null || \
  echo "WARN: could not override DRS org policy (need roles/orgpolicy.policyAdmin)"
rm -f "${TMP_POLICY}"

make_public() { # service
  for _ in 1 2 3 4 5; do
    gcloud run services add-iam-policy-binding "$1" \
      --region="${REGION}" --member=allUsers --role=roles/run.invoker --quiet >/dev/null 2>&1 \
      && return 0
    sleep 20  # wait for org-policy propagation
  done
  echo "WARN: failed to make $1 public"; return 1
}

# --- 6. backend-api -------------------------------------------------------
gcloud builds submit --tag "${REPO}/backend-api:latest" "${ROOT}/backend/api"
gcloud run deploy backend-api \
  --image "${REPO}/backend-api:latest" --region "${REGION}" --allow-unauthenticated \
  --min-instances=0 --max-instances=3 --cpu=1 --memory=512Mi --port=8080 \
  --set-env-vars ENVIRONMENT=production,MOCK_ACAPY=true \
  --set-secrets JWT_SECRET=jwt-secret:latest,CPF_HASH_SALT=cpf-hash-salt:latest --quiet
make_public backend-api
BACKEND_URL="$(gcloud run services describe backend-api --region "${REGION}" --format='value(status.url)')"
echo "==> backend-api: ${BACKEND_URL}"

# --- 7. frontends (build all three portals, then deploy) ------------------
gcloud builds submit --config "${ROOT}/frontend/cloudbuild.yaml" \
  --substitutions "_VITE_API_BASE=${BACKEND_URL}" "${ROOT}/frontend"

declare -a FRONTEND_URLS=()
for portal in efolha gestao wallet; do
  gcloud run deploy "frontend-${portal}" \
    --image "${REPO}/frontend-${portal}:latest" --region "${REGION}" --allow-unauthenticated \
    --min-instances=0 --max-instances=3 --cpu=1 --memory=512Mi --port=8080 --quiet
  make_public "frontend-${portal}"
  url="$(gcloud run services describe "frontend-${portal}" --region "${REGION}" --format='value(status.url)')"
  FRONTEND_URLS+=("${url}")
  echo "==> frontend-${portal}: ${url}"
done

# --- 8. CORS: backend allows the three frontend origins -------------------
CORS="$(IFS=,; echo "${FRONTEND_URLS[*]}")"
gcloud run services update backend-api --region "${REGION}" \
  --update-env-vars "^##^CORS_ORIGINS=${CORS}" --quiet

# --- 9. webhook-handler ---------------------------------------------------
gcloud builds submit --tag "${REPO}/webhook-handler:latest" "${ROOT}/backend/webhook-handler"
gcloud run deploy webhook-handler \
  --image "${REPO}/webhook-handler:latest" --region "${REGION}" --allow-unauthenticated \
  --min-instances=0 --max-instances=3 --cpu=1 --memory=512Mi --port=8080 \
  --set-secrets DATABASE_URL=app-data-db-url:latest --quiet
make_public webhook-handler
WEBHOOK_URL="$(gcloud run services describe webhook-handler --region "${REGION}" --format='value(status.url)')"
echo "==> webhook-handler: ${WEBHOOK_URL}"

# --- 10. Optional custom domains (best-effort; requires verified domain) ---
# Verify the parent domain first (gcloud domains verify sp.preidx.global), then:
#   gcloud beta run domain-mappings create --service frontend-efolha  --domain e-folha.sp.preidx.global  --region "${REGION}"
#   gcloud beta run domain-mappings create --service frontend-gestao  --domain gestao.sp.preidx.global   --region "${REGION}"
#   gcloud beta run domain-mappings create --service frontend-wallet  --domain wallet.sp.preidx.global   --region "${REGION}"
#   gcloud beta run domain-mappings create --service backend-api      --domain servidor.sp.preidx.global --region "${REGION}"
# Then add the CNAME records each mapping prints (typically -> ghs.googlehosted.com).

echo
echo "================= PUBLIC URLS ================="
echo "backend-api      ${BACKEND_URL}"
echo "frontend-efolha  ${FRONTEND_URLS[0]}"
echo "frontend-gestao  ${FRONTEND_URLS[1]}"
echo "frontend-wallet  ${FRONTEND_URLS[2]}"
echo "webhook-handler  ${WEBHOOK_URL}"
