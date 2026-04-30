# `.xcresult` evidence + xcresulttool extraction (macOS + iOS)

## Why `.xcresult` matters

Your `xcodebuild` run should always write a **result bundle**. Treat it as immutable evidence:

- build logs
- test results
- screenshots / attachments
- diagnostics

This skill keeps the bundle and derives:

- a machine-readable test summary
- exported attachments and diagnostics

## xcodebuild flags (key ones)

- `-resultBundlePath <path>`: writes the `.xcresult` bundle. Keep each run’s bundle path unique and immutable, and ensure the path does not already exist (otherwise `xcodebuild` errors with “Existing file at -resultBundlePath …”).
- `-testPlan <name>`: selects a test plan attached to the scheme.
- `-only-test-configuration <name>` / `-skip-test-configuration <name>`: selects test plan configurations.
- `-only-testing <id>` / `-skip-testing <id>`: narrows to a specific target/class/method.
- `-parallel-testing-enabled YES|NO`: overrides scheme parallelization.

## Recommended command shapes

Tip: if you have it, prefer `scripts/ui/ui_loop.sh` for an evidence-first run. The script can auto-discover a root `.xcworkspace`/`.xcodeproj` from `--package-root` (or the repo root) and captures `xcodebuild-*.log` files per run unless `VERBOSE=1` is set. The commands below are the underlying primitives.

### macOS

```bash
RUN_ID="$(date -u +"%Y%m%dT%H%M%SZ")"
RUN_DIR="./.artifacts/ui/$RUN_ID"
RESULT_BUNDLE="$RUN_DIR/results.xcresult"
mkdir -p "$RUN_DIR"

xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  -resultBundlePath "$RESULT_BUNDLE" \
  test
```

### iOS (simulator)

```bash
RUN_ID="$(date -u +"%Y%m%dT%H%M%SZ")"
RUN_DIR="./.artifacts/ui/$RUN_ID"
RESULT_BUNDLE="$RUN_DIR/results.xcresult"
mkdir -p "$RUN_DIR"

xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -parallel-testing-enabled NO \
  -resultBundlePath "$RESULT_BUNDLE" \
  test
```

(For iOS 26 environments, use `OS=26.0` in the destination.)

Tips:

- To enumerate valid macOS destinations on the current machine:

  ```bash
  xcodebuild -workspace App.xcworkspace -scheme App -showdestinations
  ```

- If you need to force an architecture slice, include `arch=arm64` or `arch=x86_64` (for example: `-destination 'platform=macOS,arch=arm64'`).

- For repeatable iOS simulator runs, prefer a simulator UDID in `-destination` rather than only a device name.

## Faster deterministic reruns (recommended)

When iterating quickly, prefer `build-for-testing` + `test-without-building`:

```bash
RUN_ID="$(date -u +"%Y%m%dT%H%M%SZ")"
RUN_DIR="./.artifacts/ui/$RUN_ID"
DERIVED_DATA="$RUN_DIR/DerivedData"
RESULT_BUNDLE="$RUN_DIR/results.xcresult"
mkdir -p "$RUN_DIR"

# 1) Build once
xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -parallel-testing-enabled NO \
  build-for-testing

# 2) Run tests repeatedly using the generated .xctestrun
XCTESTRUN="$(
  find "$DERIVED_DATA" -name '*.xctestrun' -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null \
    | head -n 1
)"

xcodebuild \
  -xctestrun "$XCTESTRUN" \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  -resultBundlePath "$RESULT_BUNDLE" \
  test-without-building
```


## Attachment retention and agent-safe export

Xcode UI testing can keep automatic system screenshots in the result bundle. For agent workflows, prefer suppressing automatic screenshots before the `.xcresult` is written:

```bash
scripts/ui/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=macOS' \
  --reuse-build \
  --system-attachment-lifetime keepNever \
  --sanitize-screenshots redact-suspect \
  --delete-raw-attachments
```

The `--system-attachment-lifetime keepNever` option patches the generated `.xctestrun` after `build-for-testing` and before `test-without-building`. This controls automatic XCTest UI screenshots. If tests add explicit `XCTAttachment` instances, control those separately in test code or pass `--user-attachment-lifetime <keepAlways|deleteOnSuccess|keepNever>`.

For one-off manual patching:

```bash
scripts/ui/patch_xctestrun_attachment_policy.py "$XCTESTRUN" \
  --system-attachment-lifetime keepNever
```

For shared scheme defaults:

```bash
scripts/ui/patch_xcscheme_attachment_policy.py \
  App.xcodeproj/xcshareddata/xcschemes/App.xcscheme \
  --system-attachment-lifetime keepNever
```

For post-export artifact hygiene:

```bash
scripts/ui/xcresult_export.sh results.xcresult .artifacts/ui/run \
  --sanitize-screenshots redact-suspect \
  --delete-raw-attachments
```

See `references/artifact-privacy.md` for the privacy policy and screenshot strategy comparison.

## xcresulttool commands used by this skill

This skill prefers newer structured subcommands when available, and falls back to legacy JSON extraction on older toolchains.

Note: In Xcode 16, Apple introduced structured `xcresulttool` commands under `get test-results ...` and related subcommands. Some older subcommands (for example `get object`) are deprecated.

- Summary JSON:

  ```bash
  xcrun xcresulttool get test-results summary --path results.xcresult --compact > summary.json
  ```

- Export attachments / diagnostics:

  ```bash
  xcrun xcresulttool export attachments --path results.xcresult --output-path attachments/
  xcrun xcresulttool export diagnostics --path results.xcresult --output-path diagnostics/
  ```

- Export only failing attachments:

  ```bash
  xcrun xcresulttool export attachments --path results.xcresult --output-path attachments/ --only-failures
  ```

- Optional: export structured logs and build results for easier triage:

  ```bash
  xcrun xcresulttool get build-results --path results.xcresult --compact > build_results.json
  xcrun xcresulttool get log --path results.xcresult --type action --compact > log_action.txt
  xcrun xcresulttool get log --path results.xcresult --type console --compact > log_console.txt
  ```

Scripts:

- `scripts/ui/xcresult_summary.sh`
- `scripts/ui/xcresult_export.sh`

iOS simulator helpers:

- `scripts/ios/simctl_prepare.sh`
- `scripts/ios/simctl_privacy.sh`
