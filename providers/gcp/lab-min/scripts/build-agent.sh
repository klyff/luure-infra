#!/usr/bin/env bash
# Build + push luure-agent-server to Artifact Registry. Run after apply has
# created the repository, from a machine with gcloud on the Luure project.
set -euo pipefail
INFRA="$(cd "$(dirname "$0")/../../../.." && pwd)"
UMBRELLA="$(cd "$INFRA/../.." && pwd)"
AGENT="${LUURE_AGENT_SERVER:-$UMBRELLA/mvp/luure-agent-server}"
PROJECT="${PROJECT:?set PROJECT (luure-lab)}"
REGION="${REGION:-southamerica-east1}"
TAG="${TAG:-lab}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/luure/luure-agent:${TAG}"

if [[ ! -f "$AGENT/Dockerfile" ]]; then
  echo "Dockerfile missing: $AGENT" >&2
  exit 1
fi

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
gcloud builds submit "$AGENT" --project "$PROJECT" --region "$REGION" --tag "$IMAGE"
echo "Pushed $IMAGE"
echo "Then: terraform apply -var=agent_image=$IMAGE -var=agent_base_url=\$(terraform output -raw agent_url)"
