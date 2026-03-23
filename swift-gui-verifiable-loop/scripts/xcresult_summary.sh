#!/bin/bash
# Produce a machine-readable JSON summary from a .xcresult bundle.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: scripts/xcresult_summary.sh <results.xcresult> <out.json>" >&2
  exit 2
fi

BUNDLE="$1"
OUT="$2"

if [[ ! -d "$BUNDLE" ]]; then
  echo "Not a directory: $BUNDLE" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT")"

# Prefer the structured subcommand for stability.
xcrun xcresulttool get test-results summary --path "$BUNDLE" --format json > "$OUT"
