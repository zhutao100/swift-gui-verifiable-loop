# `.xcresult` evidence + xcresulttool extraction

## Why `.xcresult` matters

Your `xcodebuild` run should always write a **result bundle**. Treat it as immutable evidence:
- build logs
- test results
- screenshots and attachments
- diagnostics

## xcodebuild flags (key ones)

- `-resultBundlePath <path>`: writes the `.xcresult` bundle (must not already exist).
- `-testPlan <name>`: selects a test plan attached to the scheme.
- `-only-test-configuration <name>` / `-skip-test-configuration <name>`: selects test plan configurations.

## Recommended command shape

```bash
xcodebuild   -workspace App.xcworkspace   -scheme App   -testPlan Smoke   -destination 'platform=iOS Simulator,name=iPhone 16'   -resultBundlePath ./artifacts/TestResults.xcresult   test
```

## xcresulttool commands used by this skill

- Summary JSON:

```bash
xcrun xcresulttool get test-results summary --path results.xcresult --format json > summary.json
```

- Export attachments / diagnostics:

```bash
xcrun xcresulttool export attachments --path results.xcresult --output-path attachments/
xcrun xcresulttool export diagnostics --path results.xcresult --output-path diagnostics/
```

Scripts:
- `scripts/xcresult_summary.sh`
- `scripts/xcresult_export.sh`
