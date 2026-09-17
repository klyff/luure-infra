#!/usr/bin/env bash
# Shared helpers for lab-min migration phase tests.
# Exit 2 = apply gate (no Luure project / Predix CLI). Exit 1 = phase failed.

PREDIX_PROJECT="starlit-torus-492916-d7"
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_MIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
ENVIRONMENT="${ENVIRONMENT:-lab}"
REGION="${REGION:-southamerica-east1}"
ZONE="${ZONE:-southamerica-east1-b}"
NAME="luure-${ENVIRONMENT}"

tfvar() {
  local key="$1"
  local file
  for file in "$LAB_MIN_DIR/terraform.tfvars" "$LAB_MIN_DIR/../../../environments/lab.tfvars"; do
    if [[ -f "$file" ]]; then
      local val
      val="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" | tail -1 | sed -E 's/^[^=]+=[[:space:]]*//; s/[[:space:]]*#.*//; s/^"//; s/"$//')"
      if [[ -n "$val" ]]; then
        printf '%s' "$val"
        return 0
      fi
    fi
  done
  return 1
}

PROJECT="${PROJECT:-${GCP_PROJECT_ID:-$(tfvar gcp_project_id || true)}}"
GCLOUD_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"

require_luure_cli() {
  if [[ "$GCLOUD_PROJECT" == "$PREDIX_PROJECT" ]]; then
    echo "GATE: gcloud is on Predix ($PREDIX_PROJECT). Reauth to the Luure project. No apply." >&2
    exit 2
  fi
  if [[ -z "$PROJECT" || "$PROJECT" == '""' ]]; then
    echo "GATE: gcp_project_id empty. Set PROJECT=luure-lab or terraform.tfvars. No apply." >&2
    exit 2
  fi
  if [[ "$PROJECT" == "$PREDIX_PROJECT" ]]; then
    echo "GATE: gcp_project_id is Predix. Forbidden." >&2
    exit 2
  fi
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing command: $1" >&2
    exit 1
  }
}

pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*" >&2; return 1; }

gcloud_ok() {
  gcloud "$@" --project="$PROJECT" --quiet >/dev/null 2>&1
}

tf_out() {
  terraform -chdir="$LAB_MIN_DIR" output -raw "$1" 2>/dev/null || true
}
