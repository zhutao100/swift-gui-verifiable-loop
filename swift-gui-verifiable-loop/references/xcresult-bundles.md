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

- `-resultBundlePath <path>`: writes the `.xcresult` bundle (keep each run’s bundle path unique and immutable).
- `-testPlan <name>`: selects a test plan attached to the scheme.
- `-only-test-configuration <name>` / `-skip-test-configuration <name>`: selects test plan configurations.
- `-only-testing <id>` / `-skip-testing <id>`: narrows to a specific target/class/method.
- `-parallel-testing-enabled YES|NO`: overrides scheme parallelization.

## Recommended command shapes

### macOS

```bash
xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  -resultBundlePath ./artifacts/TestResults.xcresult \
  test
```

### iOS (simulator)

```bash
xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -parallel-testing-enabled NO \
  -resultBundlePath ./artifacts/TestResults.xcresult \
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
# 1) Build once
xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -testPlan Smoke \
  -destination 'platform=macOS' \
  -derivedDataPath ./artifacts/DerivedData \
  -parallel-testing-enabled NO \
  build-for-testing

# 2) Run tests repeatedly using the generated .xctestrun
XCTESTRUN="$(find ./artifacts/DerivedData -name '*.xctestrun' -print | head -n 1)"

xcodebuild \
  -xctestrun "$XCTESTRUN" \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  -resultBundlePath ./artifacts/TestResults.xcresult \
  test-without-building
```

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

- `scripts/xcresult_summary.sh`
- `scripts/xcresult_export.sh`

iOS simulator helpers:

- `scripts/ios/simctl_prepare.sh`
- `scripts/ios/simctl_privacy.sh`
