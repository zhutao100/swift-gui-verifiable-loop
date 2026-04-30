#!/usr/bin/env bash
# Refresh vendored swift-gui-verifiable-loop scripts in a target Swift GUI repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

MODE="dry-run"
PLATFORM="macos"
TARGET_ROOT=""

usage() {
  cat <<'USAGE'
Usage:
  update_ui_loop_tools.sh [--dry-run|--check|--apply] [--platform macos|ios|both] <target-repo-root>

Copies the canonical scripts from this skill into an existing target project.
Use this when a project was set up by an older skill version and needs the
current ui_loop, xcresult extraction, attachment privacy, and TCC/simulator
helpers.

Modes:
  --dry-run   Print files that would change (default)
  --check     Print drift and exit 1 if any managed file differs or is missing
  --apply     Copy managed files into the target repo

Platforms:
  macos       Copy scripts/ui plus scripts/macos helpers (default)
  ios         Copy scripts/ui plus scripts/ios helpers
  both        Copy scripts/ui, scripts/macos, and scripts/ios helpers
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift 1 ;;
    --check) MODE="check"; shift 1 ;;
    --apply) MODE="apply"; shift 1 ;;
    --platform)
      [[ $# -ge 2 ]] || fail "missing value for --platform"
      PLATFORM="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    --*) fail "unknown argument: $1" ;;
    *)
      if [[ -n "$TARGET_ROOT" ]]; then
        fail "multiple target roots provided: $TARGET_ROOT and $1"
      fi
      TARGET_ROOT="$1"
      shift 1
      ;;
  esac
done

case "$MODE" in
  dry-run|check|apply) ;;
  *) fail "invalid mode: $MODE" ;;
esac

case "$PLATFORM" in
  macos|ios|both) ;;
  *) fail "--platform must be macos, ios, or both (got: $PLATFORM)" ;;
esac

[[ -n "$TARGET_ROOT" ]] || fail "missing target repo root"
[[ -d "$TARGET_ROOT" ]] || fail "target repo root does not exist: $TARGET_ROOT"

TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd -P)"

managed_files=(
  scripts/ui/ui_loop.sh
  scripts/ui/xcresult_export.sh
  scripts/ui/xcresult_summary.sh
  scripts/ui/toolchain_fingerprint.sh
  scripts/ui/patch_xctestrun_attachment_policy.py
  scripts/ui/patch_xcscheme_attachment_policy.py
  scripts/ui/xcresult_sanitize_attachments.py
)

if [[ "$PLATFORM" == "macos" || "$PLATFORM" == "both" ]]; then
  managed_files+=(
    scripts/macos/tcc_attribution_tail.sh
    scripts/macos/collect_tcc_identities.sh
  )
fi

if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "both" ]]; then
  managed_files+=(
    scripts/ios/simctl_prepare.sh
    scripts/ios/simctl_privacy.sh
  )
fi

changed=0

for rel in "${managed_files[@]}"; do
  src="$SKILL_DIR/$rel"
  dst="$TARGET_ROOT/$rel"

  [[ -f "$src" ]] || fail "missing source file in skill: $rel"

  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    printf 'ok       %s\n' "$rel"
    continue
  fi

  changed=1
  if [[ -e "$dst" ]]; then
    printf 'update   %s\n' "$rel"
  else
    printf 'create   %s\n' "$rel"
  fi

  if [[ "$MODE" == "apply" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
  fi
done

case "$MODE" in
  apply)
    if [[ "$changed" -eq 0 ]]; then
      echo "No managed script changes needed."
    else
      echo "Updated managed swift-gui-verifiable-loop scripts."
    fi
    ;;
  check)
    if [[ "$changed" -ne 0 ]]; then
      echo "Managed swift-gui-verifiable-loop scripts are out of date." >&2
      exit 1
    fi
    ;;
  dry-run)
    if [[ "$changed" -eq 0 ]]; then
      echo "No managed script changes needed."
    else
      echo "Dry run only. Re-run with --apply to copy these files."
    fi
    ;;
esac
