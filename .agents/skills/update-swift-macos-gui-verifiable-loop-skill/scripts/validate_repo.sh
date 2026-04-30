#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
SKILL_DIR="$ROOT_DIR/swift-gui-verifiable-loop"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -d "$SKILL_DIR" ]] || fail "Missing skill dir: $SKILL_DIR"

for p in "$SKILL_DIR/SKILL.md" "$SKILL_DIR/agents/openai.yaml" "$SKILL_DIR/scripts" "$SKILL_DIR/references" "$SKILL_DIR/assets"; do
  [[ -e "$p" ]] || fail "Missing required path: $p"
done

# Platform clarity checks (heuristic)
if ! grep -q "macOS" "$SKILL_DIR/SKILL.md"; then
  fail "swift-gui-verifiable-loop/SKILL.md must mention macOS"
fi
if ! grep -q "iOS" "$SKILL_DIR/SKILL.md"; then
  fail "swift-gui-verifiable-loop/SKILL.md must mention iOS"
fi

if ! grep -q "macOS 15" "$SKILL_DIR/SKILL.md"; then
  fail "swift-gui-verifiable-loop/SKILL.md must explicitly mention macOS 15"
fi
if ! grep -q "macOS 26" "$SKILL_DIR/SKILL.md"; then
  fail "swift-gui-verifiable-loop/SKILL.md must explicitly mention macOS 26"
fi
if ! grep -q "iOS 18" "$SKILL_DIR/SKILL.md"; then
  fail "swift-gui-verifiable-loop/SKILL.md must explicitly mention iOS 18"
fi
if ! grep -q "iOS 26" "$SKILL_DIR/SKILL.md"; then
  fail "swift-gui-verifiable-loop/SKILL.md must explicitly mention iOS 26"
fi

for p in \
  "$SKILL_DIR/scripts/ui/patch_xctestrun_attachment_policy.py" \
  "$SKILL_DIR/scripts/ui/patch_xcscheme_attachment_policy.py" \
  "$SKILL_DIR/scripts/ui/xcresult_sanitize_attachments.py" \
  "$SKILL_DIR/scripts/project/update_ui_loop_tools.sh" \
  "$SKILL_DIR/scripts/macos/tcc_attribution_tail.sh" \
  "$SKILL_DIR/scripts/macos/collect_tcc_identities.sh" \
  "$SKILL_DIR/references/artifact-privacy.md" \
  "$SKILL_DIR/assets/templates/AgentSafeUITestArtifactsTemplate.swift" \
  "$SKILL_DIR/assets/templates/PPPC-UI-Testing.mobileconfig.template"; do
  [[ -e "$p" ]] || fail "Missing agent-safe privacy path: $p"
done

if ! grep -q -- "--system-attachment-lifetime" "$SKILL_DIR/scripts/ui/ui_loop.sh"; then
  fail "ui_loop.sh must expose --system-attachment-lifetime"
fi
if ! grep -q -- "--sanitize-screenshots" "$SKILL_DIR/scripts/ui/ui_loop.sh"; then
  fail "ui_loop.sh must expose --sanitize-screenshots"
fi
if ! grep -q "SEATBELT_SANDBOX_WORKSPACE_ROOT" "$SKILL_DIR/scripts/ui/ui_loop.sh"; then
  fail "ui_loop.sh must seed SEATBELT_SANDBOX_WORKSPACE_ROOT for sandbox-aware projects"
fi
if ! grep -q -- "--platform macos|ios|both" "$SKILL_DIR/scripts/project/update_ui_loop_tools.sh"; then
  fail "update_ui_loop_tools.sh must document platform-scoped refreshes"
fi
if ! grep -q "XCUIScreen.main.screenshot" "$SKILL_DIR/references/artifact-privacy.md"; then
  fail "artifact privacy reference must document XCUIScreen.main.screenshot risk"
fi
# Template naming conventions
if [[ ! -f "$SKILL_DIR/assets/templates/iOSXCUITestLaunchHarnessTemplate.swift" ]]; then
  fail "Missing iOS UI test harness template"
fi
if [[ ! -f "$SKILL_DIR/assets/templates/iOSSnapshotTestTemplate.swift" ]]; then
  fail "Missing iOS snapshot template"
fi

echo "OK: repo checks passed"
