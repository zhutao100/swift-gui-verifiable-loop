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

# Template naming conventions
if [[ ! -f "$SKILL_DIR/assets/templates/iOSXCUITestLaunchHarnessTemplate.swift" ]]; then
  fail "Missing iOS UI test harness template"
fi
if [[ ! -f "$SKILL_DIR/assets/templates/iOSSnapshotTestTemplate.swift" ]]; then
  fail "Missing iOS snapshot template"
fi

echo "OK: repo checks passed"
