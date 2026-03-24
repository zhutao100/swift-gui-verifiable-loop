#!/bin/bash
# Minimal wrapper for `xcrun simctl privacy` to make iOS simulator permission state repeatable.
#
# Examples:
#   scripts/ios/simctl_privacy.sh --udid <UDID> reset all
#   scripts/ios/simctl_privacy.sh --udid <UDID> grant location-always com.example.MyApp
#   scripts/ios/simctl_privacy.sh --udid booted revoke camera com.example.MyApp
#
# Notes:
# - Not all permission types are supported by simctl on all iOS versions.
# - Some prompts (e.g. tracking/ATT) may still require UI-interruption handling in tests.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/ios/simctl_privacy.sh --udid <udid|booted> <grant|revoke|reset> <service|all> [bundle_id]

Examples:
  scripts/ios/simctl_privacy.sh --udid booted reset all
  scripts/ios/simctl_privacy.sh --udid <UDID> grant location-always com.example.MyApp
  scripts/ios/simctl_privacy.sh --udid <UDID> grant camera com.example.MyApp
  scripts/ios/simctl_privacy.sh --udid <UDID> revoke microphone com.example.MyApp

Tip:
  Run `xcrun simctl privacy --help` to see the full supported service list for your toolchain.
USAGE
}

UDID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --udid) UDID="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) break;;
  esac
done

if [[ -z "$UDID" ]]; then
  echo "Missing --udid" >&2
  usage
  exit 2
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

ACTION="$1"; SERVICE="$2"; BUNDLE_ID="${3:-}"

case "$ACTION" in
  grant|revoke)
    if [[ -z "$BUNDLE_ID" ]]; then
      echo "Missing bundle_id for $ACTION" >&2
      usage
      exit 2
    fi
    ;;
  reset)
    # `reset all` is valid without bundle id.
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    usage
    exit 2
    ;;
esac

cmd=(xcrun simctl privacy "$UDID" "$ACTION" "$SERVICE")
if [[ -n "$BUNDLE_ID" ]]; then
  cmd+=("$BUNDLE_ID")
fi

echo "==> Running: ${cmd[*]}" >&2
"${cmd[@]}"
