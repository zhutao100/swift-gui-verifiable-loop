# `.xcresult` evidence + `xcresulttool` extraction

## Why `.xcresult` matters

Your `xcodebuild` run should always write a **result bundle**. Treat it as immutable evidence:

- build logs
- test results
- screenshots and attachments
- diagnostics (crash logs, symbolication artifacts, etc.)

This skill’s scripts keep the `.xcresult` bundle and derive summaries/attachments from it.

## `xcodebuild` flags (key ones)

- `-resultBundlePath <path>`: writes the `.xcresult` bundle
  **Policy:** use a unique path per run and treat it as immutable.
- `-testPlan <name>`: selects a test plan attached to the scheme.
- `-only-test-configuration <name>` / `-skip-test-configuration <name>`: selects test plan configurations.
- `-parallel-testing-enabled YES|NO`: overrides scheme setting for parallel test execution.
- `-maximum-parallel-testing-workers <n>` / `-parallel-testing-worker-count <n>`: controls spawned test runners when parallel is enabled.

## Recommended command shape

### iOS (Simulator)

```bash
xcodebuild   -workspace App.xcworkspace   -scheme App   -testPlan Smoke   -destination 'platform=iOS Simulator,id=<UDID>'   -parallel-testing-enabled NO   -resultBundlePath "./artifacts/Run-$(date -u +%Y%m%dT%H%M%SZ).xcresult"   test
```

### macOS (current Mac)

```bash
xcodebuild   -workspace App.xcworkspace   -scheme App   -testPlan Smoke   -destination 'platform=macOS'   -parallel-testing-enabled NO   -resultBundlePath "./artifacts/Run-$(date -u +%Y%m%dT%H%M%SZ).xcresult"   test
```

Tip: for maximum repeatability on iOS, prefer a simulator **UDID** rather than a device name.

## Faster deterministic reruns (recommended)

When iterating quickly, prefer `build-for-testing` + `test-without-building`:

```bash
# 1) Build once
xcodebuild   -workspace App.xcworkspace   -scheme App   -testPlan Smoke   -destination 'platform=iOS Simulator,id=<UDID>'   -derivedDataPath ./artifacts/DerivedData   -parallel-testing-enabled NO   build-for-testing

# 2) Run tests repeatedly using the generated .xctestrun
XCTESTRUN="$(find ./artifacts/DerivedData -name '*.xctestrun' -print | head -n 1)"
xcodebuild   -xctestrun "$XCTESTRUN"   -destination 'platform=iOS Simulator,id=<UDID>'   -parallel-testing-enabled NO   -resultBundlePath "./artifacts/Run-$(date -u +%Y%m%dT%H%M%SZ).xcresult"   test-without-building
```

## `xcresulttool` commands used by this skill

> Note: `xcresulttool` has been evolving across Xcode releases. This skill prefers the modern `get test-results …` family when available, and uses legacy “root object” JSON only as a fallback.
>
> On Xcode 16+ the legacy root object command is `xcresulttool get object --legacy --path <bundle> --format json`.

### Summary JSON

```bash
xcrun xcresulttool get test-results summary --path results.xcresult --compact > summary.json
```

### Export attachments and diagnostics

```bash
xcrun xcresulttool export attachments --path results.xcresult --output-path attachments/
xcrun xcresulttool export diagnostics --path results.xcresult --output-path diagnostics/
```

Export only failing attachments:

```bash
xcrun xcresulttool export attachments --path results.xcresult --output-path attachments/ --only-failures
```

### Optional: export structured logs and build results

```bash
xcrun xcresulttool get build-results --path results.xcresult --compact > build_results.json
xcrun xcresulttool get log --path results.xcresult --type action --compact > log_action.txt
xcrun xcresulttool get log --path results.xcresult --type console --compact > log_console.txt
```

## Scripts in this repo

- `scripts/ui_loop.sh` — orchestrates an end-to-end run and writes artifacts
- `scripts/xcresult_summary.sh` — produces a machine-readable summary JSON
- `scripts/xcresult_export.sh` — exports attachments/diagnostics/logs (best-effort)
- `scripts/toolchain_fingerprint.sh` — fingerprints the environment used for a run

## Sources

- `xcresulttool` man page (concepts and bundle basics): https://keith.github.io/xcode-man-pages/xcresulttool.1.html
- Xcode tooling churn examples (`--legacy` requirement surfaced in CI tooling): https://github.com/fastlane/fastlane/issues/22132
- Apple Developer Forums (example of Xcode 26 `xcresulttool` behavior discussion): https://developer.apple.com/forums/thread/806401
