#!/bin/bash
# Minimal simulator prep helpers for repeatable runs.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/ios/simctl_prepare.sh --udid <udid> [--erase] [--boot] [--shutdown]

  # Find devices:
  xcrun simctl list devices

Examples:
  scripts/ios/simctl_prepare.sh --udid <UDID> --shutdown --erase --boot
EOF
}

UDID=""
DO_ERASE=0
DO_BOOT=0
DO_SHUTDOWN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --udid) UDID="$2"; shift 2;;
    --erase) DO_ERASE=1; shift 1;;
    --boot) DO_BOOT=1; shift 1;;
    --shutdown) DO_SHUTDOWN=1; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

if [[ -z "$UDID" ]]; then
  echo "Missing --udid" >&2
  usage
  exit 2
fi

if [[ "$DO_SHUTDOWN" -eq 1 ]]; then
  xcrun simctl shutdown "$UDID" || true
fi

if [[ "$DO_ERASE" -eq 1 ]]; then
  xcrun simctl erase "$UDID"
fi

if [[ "$DO_BOOT" -eq 1 ]]; then
  xcrun simctl boot "$UDID" || true
fi
