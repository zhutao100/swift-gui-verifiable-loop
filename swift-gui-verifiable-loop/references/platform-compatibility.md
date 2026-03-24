# Platform compatibility (macOS vs iOS) and versioning notes

This skill is designed to be explicit about **host vs target** platforms:

- **Host (where scripts run):** macOS with Xcode command-line tools installed (`xcodebuild`, `xcrun`, `xcresulttool`, `simctl`).
- **Targets (what you test):**
  - macOS apps (AppKit / SwiftUI): macOS **15** and macOS **26**.
  - iOS apps (UIKit / SwiftUI): iOS **18** and iOS **26**.

## About the “26” OS versions

Apple adopted **year-based OS version numbers** starting with “26” releases across Apple platforms (iOS 26, iPadOS 26, macOS 26, etc). In Apple’s developer tooling, you’ll see this in:

- Xcode **26** SDK lists (iOS 26, macOS Tahoe 26, etc)
- OS release notes / update pages

Practical implication: **pin Xcode to match the SDK behavior you’re validating**.

- Validating iOS 26 / macOS 26 behavior → Xcode 26.x
- Validating iOS 18-era SDK behavior → the matching older Xcode (typically Xcode 16.x)

## What changes between macOS and iOS verification loops?

### Destination model

- **macOS:** tests run on the current machine (no simulator).
  - Destination: `platform=macOS`
- **iOS:** tests typically run in iOS Simulator.
  - Destination: `platform=iOS Simulator,id=<UDID>` (recommended)
  - Use `scripts/simctl_prepare.sh` to erase/boot deterministically between runs.

### UI determinism gotchas

- **macOS (AppKit):**
  - windowing is “real” and shared with the desktop session; keep smoke tests short
  - tests can be influenced by global state (permissions, keychain prompts, login items)
  - prefer deterministic entry harnesses that avoid modal dialogs and external dependencies
- **iOS (Simulator):**
  - simulator state is easy to reset (erase)
  - simulator runtime + device model must be pinned for stable snapshots
  - OS-level rendering changes (fonts, material effects) can cause snapshot churn across major releases

### Snapshot testing across major OS versions

- Prefer text/hierarchy strategies (`.dump`, `.recursiveDescription`) for cross-version stability.
- If you must use image snapshots, pin:
  - device model, OS runtime, scale
  - locale, dynamic type, appearance (light/dark)
- iOS 26 introduced new “Liquid Glass” material effects across the system UI; when snapshotting, isolate or override material backgrounds to avoid transparency artifacts (see Point-Free issue discussions).

## Sources (starting points)

- Xcode 26 release notes (SDK list includes iOS 26 and macOS Tahoe 26):
  https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes
- iOS & iPadOS 26 release notes index:
  https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes
- macOS 26 release notes:
  https://developer.apple.com/documentation/macos-release-notes/macos-26-release-notes
- Apple iOS 26 overview page (design + feature overview):
  https://www.apple.com/os/ios/
- SnapshotTesting repo + iOS 26 “glass effect” discussion thread:
  https://github.com/pointfreeco/swift-snapshot-testing
