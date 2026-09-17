#!/usr/bin/env bash
# Build + push luure-dashday to Artifact Registry.
set -euo pipefail
INFRA="$(cd "$(dirname "$0")/../../../.." && pwd)"
UMBRELLA="$(cd "$INFRA/../.." && pwd)"
DASH="${LUURE_DASHDAY:-$UMBRELLA/mvp/luure-dashday}"
PROJECT="${PROJECT:?set PROJECT (luure-lab)}"
REGION="${REGION:-southamerica-east1}"
TAG="${TAG:-lab}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/luure/luure-dashday:${TAG}"

if [[ ! -f "$DASH/Dockerfile" ]]; then
  echo "Dockerfile missing: $DASH" >&2
  exit 1
fi

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
gcloud builds submit "$DASH" --project "$PROJECT" --region "$REGION" --tag "$IMAGE"
echo "Pushed $IMAGE"
echo "Then: terraform apply -var=dash_image=$IMAGE"
