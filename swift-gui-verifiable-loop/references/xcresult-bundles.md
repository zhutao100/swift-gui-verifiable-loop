# `.xcresult` evidence + xcresulttool extraction

## Why `.xcresult` matters

Your `xcodebuild` run should always write a **result bundle**. Treat it as immutable evidence:
- build logs
- test results
- screenshots and attachments
- diagnostics

## xcodebuild flags (key ones)

- `-resultBundlePath <path>`: writes the `.xcresult` bundle (treat each run as a unique path and keep it immutable).
- `-testPlan <name>`: selects a test plan attached to the scheme.
- `-only-test-configuration <name>` / `-skip-test-configuration <name>`: selects test plan configurations.
- `-parallel-testing-enabled YES|NO`: overrides scheme setting for parallel test execution.
- `-maximum-parallel-testing-workers <n>` / `-parallel-testing-worker-count <n>`: controls the number of spawned test runners when parallel is enabled.

## Recommended command shape

```bash
xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -parallel-testing-enabled NO \
  -resultBundlePath ./artifacts/TestResults.xcresult \
  test

Tip: for maximum repeatability, prefer a simulator UDID in `-destination` rather than a device name.

## Faster deterministic reruns (recommended)

When iterating quickly, prefer `build-for-testing` + `test-without-building`:

```bash
# 1) Build once
xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath ./artifacts/DerivedData \
  -parallel-testing-enabled NO \
  build-for-testing

# 2) Run tests repeatedly using the generated .xctestrun
XCTESTRUN="$(find ./artifacts/DerivedData -name '*.xctestrun' -print | head -n 1)"
xcodebuild \
  -xctestrun "$XCTESTRUN" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -parallel-testing-enabled NO \
  -resultBundlePath ./artifacts/TestResults.xcresult \
  test-without-building
```
```

## xcresulttool commands used by this skill

- Summary JSON:

```bash
xcrun xcresulttool get test-results summary --path results.xcresult --compact > summary.json
```

- Export attachments / diagnostics:

```bash
xcrun xcresulttool export attachments --path results.xcresult --output-path attachments/
xcrun xcresulttool export diagnostics --path results.xcresult --output-path diagnostics/

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
```

Scripts:
- `scripts/xcresult_summary.sh`
- `scripts/xcresult_export.sh`
