#!/usr/bin/env bash
# Prove the lab-min migration in three gated phases. Stops on first failure.
# Exit 2 = apply gate (Predix / missing project). Exit 1 = a phase failed.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"

echo "lab-min migration tests — ${NAME} / ${REGION}"
require_luure_cli

"$DIR/phase-1-landing.sh"
"$DIR/phase-2-ledger.sh"
"$DIR/phase-3-apps.sh"
echo "All 3 phases passed."
