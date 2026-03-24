# Picking and pinning destinations (macOS vs iOS Simulator)

Agents must never “guess” destinations. Pin them in the target project’s own docs.

## Get destinations from Xcode (authoritative)

### Show destinations for a scheme

```bash
xcodebuild -workspace App.xcworkspace -scheme App -showdestinations
```

This is the most reliable way to see what Xcode considers a valid destination for the scheme.

### iOS Simulator: prefer UDID

Use `simctl` to list devices and their UDIDs:

```bash
xcrun simctl list devices
```

Then pin:

- `platform=iOS Simulator,id=<UDID>`

Avoid name-based destinations when you care about determinism (device names can be duplicated).

### macOS: current machine

Most macOS app/UI test suites run on the current Mac:

- `platform=macOS`

If you need to be explicit about architecture, you can include `arch=` in `-destination` (see `xcodebuild(1)` man page).

### Mac Catalyst (UIKit for Mac)

For a Catalyst variant:

- `platform=macOS,variant=Mac Catalyst`

(Only use this if your scheme is actually a Catalyst target.)

## Simulator reset loop (deterministic)

If simulator state can influence tests, reset it between runs:

```bash
scripts/simctl_prepare.sh --udid <UDID> --shutdown --erase --boot --wait-boot
```

## Sources

- `xcodebuild(1)` man page destination examples (includes macOS destinations):
  https://leancrew.com/all-this/man/man1/xcodebuild.html
- Xcodebuild destination syntax overview:
  https://mokacoding.com/blog/xcodebuild-destination-options/
