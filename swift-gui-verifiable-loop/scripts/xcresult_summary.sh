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

# Prefer the structured subcommand for stability (Xcode 16+; still present in Xcode 26).
# Fall back to legacy "root object" JSON when running on older Xcodes.
if xcrun xcresulttool get test-results summary --help >/dev/null 2>&1; then
  xcrun xcresulttool get test-results summary --path "$BUNDLE" --compact > "$OUT"
else
  # Legacy mode: retrieve the root object as JSON.
  # Newer Xcodes require `get object --legacy` for the root object.
  if xcrun xcresulttool get object --help >/dev/null 2>&1; then
    if xcrun xcresulttool get object --help 2>/dev/null | grep -q -- '--legacy'; then
      xcrun xcresulttool get object --legacy --path "$BUNDLE" --format json > "$OUT"
    else
      xcrun xcresulttool get object --path "$BUNDLE" --format json > "$OUT"
    fi
  else
    xcrun xcresulttool get --path "$BUNDLE" --format json > "$OUT"
  fi
fi
