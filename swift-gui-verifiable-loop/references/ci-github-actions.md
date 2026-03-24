# CI recipe (example): GitHub Actions `.xcresult` artifacts

This skill is CI-agnostic. The key requirement is that CI preserves:

- the `.xcresult` bundle(s)
- derived summaries and exported attachments

## Minimal GitHub Actions example (iOS Simulator)

```yaml
name: iOS tests

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_26.app/Contents/Developer

      - name: List simulators
        run: xcrun simctl list devices

      - name: Run tests (verifiable loop)
        run: |
          UDID="<PINNED_UDID>"
          swift-gui-verifiable-loop/scripts/simctl_prepare.sh --udid "$UDID" --shutdown --erase --boot --wait-boot
          swift-gui-verifiable-loop/scripts/ui_loop.sh             --workspace App.xcworkspace             --scheme App             --test-plan Smoke             --destination "platform=iOS Simulator,id=$UDID"             --artifacts-dir ./artifacts

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: xcresult-artifacts
          path: artifacts/
```

## Notes

- Prefer `platform=iOS Simulator,id=<UDID>` to avoid destination ambiguity.
- When CI images change their bundled simulators/Xcode versions, destination names become unstable; UDID pinning plus `-showdestinations` helps debug quickly.
- If you see intermittent “runner fails to launch unit tests” style issues on macOS runners, treat it as an infrastructure problem first, not a product regression.

## Sources

- GitHub Actions runner-images (macOS/Xcode test flakiness discussion):
  https://github.com/actions/runner-images/issues/11874
