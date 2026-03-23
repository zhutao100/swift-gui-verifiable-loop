#!/bin/bash
# swift-gui-verifiable-loop: end-to-end deterministic GUI verification run
# Compatible with macOS / bash 3.2+
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/ui_loop.sh (--workspace <path> | --project <path>) --scheme <name> [options]

Required:
  --scheme <name>                 Xcode scheme name

One of:
  --workspace <path>              Path to .xcworkspace
  --project <path>                Path to .xcodeproj

Recommended:
  --test-plan <name>              .xctestplan name (without extension)
  --destination <string>          xcodebuild -destination string
  --artifacts-dir <dir>           Output root (default: ./artifacts)

Optional:
  --derived-data <dir>            DerivedData path (default: artifacts/<run-id>/DerivedData when --reuse-build)
  --configuration <name>          e.g. Debug / Release
  --only-testing <id>             Repeatable. TestTarget[/TestClass[/TestMethod]]
  --skip-testing <id>             Repeatable.
  --only-test-configuration <name> Repeatable. Test plan configuration name
  --skip-test-configuration <name> Repeatable.
  --reuse-build                   Run build-for-testing then test-without-building (faster reruns)
  --xctestrun <path>              Use existing .xctestrun (implies test-without-building; cannot use --workspace/--project)
  --only-failures-attachments     Export only failing attachments
  --run-id <id>                   Override run id

Examples:
  scripts/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
    --destination 'platform=iOS Simulator,name=iPhone 16'

  scripts/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
    --destination 'platform=iOS Simulator,name=iPhone 16' --reuse-build
EOF
}

WORKSPACE=""
PROJECT=""
SCHEME=""
TEST_PLAN=""
DESTINATION=""
ARTIFACTS_DIR="./artifacts"
DERIVED_DATA=""
CONFIGURATION=""
REUSE_BUILD=0
XCTESTRUN=""
ONLY_FAIL_ATTACH=0
RUN_ID=""

ONLY_TESTING=()
SKIP_TESTING=()
ONLY_TEST_CONFIG=()
SKIP_TEST_CONFIG=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) WORKSPACE="$2"; shift 2;;
    --project) PROJECT="$2"; shift 2;;
    --scheme) SCHEME="$2"; shift 2;;
    --test-plan) TEST_PLAN="$2"; shift 2;;
    --destination) DESTINATION="$2"; shift 2;;
    --artifacts-dir) ARTIFACTS_DIR="$2"; shift 2;;
    --derived-data) DERIVED_DATA="$2"; shift 2;;
    --configuration) CONFIGURATION="$2"; shift 2;;
    --only-testing) ONLY_TESTING+=("$2"); shift 2;;
    --skip-testing) SKIP_TESTING+=("$2"); shift 2;;
    --only-test-configuration) ONLY_TEST_CONFIG+=("$2"); shift 2;;
    --skip-test-configuration) SKIP_TEST_CONFIG+=("$2"); shift 2;;
    --reuse-build) REUSE_BUILD=1; shift 1;;
    --xctestrun) XCTESTRUN="$2"; shift 2;;
    --only-failures-attachments) ONLY_FAIL_ATTACH=1; shift 1;;
    --run-id) RUN_ID="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2;;
  esac
done

if [[ -z "$SCHEME" ]]; then
  echo "Missing --scheme" >&2
  usage
  exit 2
fi

if [[ -n "$XCTESTRUN" ]]; then
  if [[ -n "$WORKSPACE" || -n "$PROJECT" ]]; then
    echo "--xctestrun cannot be used with --workspace/--project (xcodebuild restriction)" >&2
    exit 2
  fi
else
  if [[ -z "$WORKSPACE" && -z "$PROJECT" ]]; then
    echo "Must provide --workspace or --project" >&2
    usage
    exit 2
  fi
  if [[ -n "$WORKSPACE" && -n "$PROJECT" ]]; then
    echo "Provide only one of --workspace/--project" >&2
    exit 2
  fi
fi

if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(date -u +"%Y%m%dT%H%M%SZ")"
fi

RUN_DIR="$ARTIFACTS_DIR/$RUN_ID"
mkdir -p "$RUN_DIR"

RESULT_BUNDLE="$RUN_DIR/results.xcresult"
SUMMARY_JSON="$RUN_DIR/summary.json"
TOOLCHAIN_TXT="$RUN_DIR/toolchain.txt"

scripts/toolchain_fingerprint.sh > "$TOOLCHAIN_TXT"

# Helper to append repeatable args:
append_repeatable() {
  local flag="$1"; shift
  local -a arr=("$@")
  local -a out=()
  local item
  for item in "${arr[@]}"; do
    out+=("$flag" "$item")
  done
  printf '%s\0' "${out[@]}"
}

run_xcodebuild_test() {
  local action="$1"; shift
  local -a cmd=("xcodebuild")

  if [[ -n "$WORKSPACE" ]]; then cmd+=("-workspace" "$WORKSPACE"); fi
  if [[ -n "$PROJECT" ]]; then cmd+=("-project" "$PROJECT"); fi

  cmd+=("-scheme" "$SCHEME")

  if [[ -n "$CONFIGURATION" ]]; then cmd+=("-configuration" "$CONFIGURATION"); fi
  if [[ -n "$TEST_PLAN" ]]; then cmd+=("-testPlan" "$TEST_PLAN"); fi
  if [[ -n "$DESTINATION" ]]; then cmd+=("-destination" "$DESTINATION"); fi
  if [[ -n "$DERIVED_DATA" ]]; then cmd+=("-derivedDataPath" "$DERIVED_DATA"); fi

  # Test selection:
  local item
  for item in "${ONLY_TESTING[@]}"; do cmd+=("-only-testing" "$item"); done
  for item in "${SKIP_TESTING[@]}"; do cmd+=("-skip-testing" "$item"); done
  for item in "${ONLY_TEST_CONFIG[@]}"; do cmd+=("-only-test-configuration" "$item"); done
  for item in "${SKIP_TEST_CONFIG[@]}"; do cmd+=("-skip-test-configuration" "$item"); done

  cmd+=("-resultBundlePath" "$RESULT_BUNDLE")
  cmd+=("$action")

  echo "==> Running: ${cmd[*]}" >&2
  "${cmd[@]}"
}

run_test_without_building() {
  local -a cmd=("xcodebuild" "-xctestrun" "$XCTESTRUN")

  if [[ -n "$DESTINATION" ]]; then cmd+=("-destination" "$DESTINATION"); fi
  cmd+=("-resultBundlePath" "$RESULT_BUNDLE" "test-without-building")

  echo "==> Running: ${cmd[*]}" >&2
  "${cmd[@]}"
}

if [[ -n "$XCTESTRUN" ]]; then
  run_test_without_building
elif [[ "$REUSE_BUILD" -eq 1 ]]; then
  if [[ -z "$DERIVED_DATA" ]]; then
    DERIVED_DATA="$RUN_DIR/DerivedData"
  fi

  # build-for-testing embeds test-plan/test-config into the generated .xctestrun.
  # (Do not rely on -testPlan being honored by test-without-building.)
  run_xcodebuild_test "build-for-testing"

  # Find newest xctestrun under derived data
  XCTESTRUN="$(find "$DERIVED_DATA" -name '*.xctestrun' -print0 | xargs -0 ls -t 2>/dev/null | head -n 1 || true)"
  if [[ -z "$XCTESTRUN" ]]; then
    echo "Could not locate .xctestrun under derived data: $DERIVED_DATA" >&2
    exit 3
  fi

  run_test_without_building
else
  run_xcodebuild_test "test"
fi

scripts/xcresult_summary.sh "$RESULT_BUNDLE" "$SUMMARY_JSON"

EXPORT_ARGS=()
if [[ "$ONLY_FAIL_ATTACH" -eq 1 ]]; then
  EXPORT_ARGS+=("--only-failures")
fi
scripts/xcresult_export.sh "$RESULT_BUNDLE" "$RUN_DIR" "${EXPORT_ARGS[@]}"

echo "==> Done."
echo "Run dir: $RUN_DIR"
echo "Result bundle: $RESULT_BUNDLE"
echo "Summary: $SUMMARY_JSON"
