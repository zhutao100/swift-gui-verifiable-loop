#!/bin/bash
# Export attachments + diagnostics from a .xcresult bundle.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: scripts/xcresult_export.sh <results.xcresult> <out_dir> [--only-failures]" >&2
  exit 2
fi

BUNDLE="$1"
OUT_DIR="$2"
shift 2

ONLY_FAILURES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --only-failures) ONLY_FAILURES=1; shift 1;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

ATT_DIR="$OUT_DIR/attachments"
DIAG_DIR="$OUT_DIR/diagnostics"
META_JSON="$OUT_DIR/xcresult_metadata.json"
TESTS_JSON="$OUT_DIR/tests.json"

mkdir -p "$ATT_DIR" "$DIAG_DIR"

xcrun xcresulttool metadata get --path "$BUNDLE" --format json > "$META_JSON" || true
xcrun xcresulttool get test-results tests --path "$BUNDLE" --format json > "$TESTS_JSON" || true

if [[ "$ONLY_FAILURES" -eq 1 ]]; then
  xcrun xcresulttool export attachments --path "$BUNDLE" --output-path "$ATT_DIR" --only-failures || true
else
  xcrun xcresulttool export attachments --path "$BUNDLE" --output-path "$ATT_DIR" || true
fi

xcrun xcresulttool export diagnostics --path "$BUNDLE" --output-path "$DIAG_DIR" || true
