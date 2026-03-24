# SnapshotTesting (Point-Free) quick reference (macOS + iOS)

Upstream:

- Repository: `pointfreeco/swift-snapshot-testing`
- Releases: check the upstream releases page for the current version. (At the time this skill was last refreshed, the latest tagged release was `1.19.1`.)

## SwiftPM setup (from upstream README)

Add a package dependency:

```swift
dependencies: [
  .package(
    url: "https://github.com/pointfreeco/swift-snapshot-testing",
    from: "1.19.1" // use the latest compatible version for your project
  ),
]
```

Add the product to your *test* target:

```swift
.testTarget(
  name: "MyAppTests",
  dependencies: [
    "MyApp",
    .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
  ]
)
```

## Snapshot strategies you will use most

- `.image` (visual regression)
- `.recursiveDescription` / `.dump` (text, view hierarchy)
- `.json` / `.plist` (text, stable and agent-readable)

## Platform guidance

### macOS

Prefer explicit layouts (fixed sizes) over device presets.

- Use `.image(layout: .fixed(width:height:))` for stable, deterministic baselines.
- Use `.image(layout: .sizeThatFits)` for small views that have well-defined intrinsic content sizes.

### iOS (simulator)

Device presets are convenient, but they only become deterministic when you **pin the simulator runtime + device model**.

- Use `.image(layout: .device(config: ...))`.
- In CI and agentic workflows, prefer an explicit `-destination` (often including `OS=`) and consider using a simulator UDID for repeatability.

## Recording / updating snapshots (policy)

SnapshotTesting deprecated the global `isRecording` flag in favor of scoped configuration.

- **CI should be strict**: use `record: .never` so missing snapshots fail deterministically.
- **Local baseline work should be explicit**: set `SNAPSHOT_RECORD=1` and run tests to re-record.

Typical XCTest pattern (wrap `invokeTest`):

```swift
import SnapshotTesting
import XCTest

@MainActor
final class FeatureSnapshots: XCTestCase {
  override func invokeTest() {
    let env = ProcessInfo.processInfo.environment

    let record: SnapshotTestingConfiguration.Record =
      env["SNAPSHOT_RECORD"] == "1" ? .all :
      (env["CI"] == "true" ? .never : .missing)

    withSnapshotTesting(record: record, diffTool: .ksdiff) {
      super.invokeTest()
    }
  }

  func testSettingsView_lightMode() {
    let view = SettingsView(model: .fixture())
      .environment(\.colorScheme, .light)

    // Prefer text-based strategies for stability when possible.
    // assertSnapshot(of: view, as: .dump)

    // macOS: prefer fixed sizes for deterministic image baselines.
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 800, height: 600)))
  }
}

private struct SettingsView: SwiftUI.View {
  let model: Model
  var body: some SwiftUI.View { SwiftUI.Text("Settings") }

  struct Model {
    static func fixture() -> Self { .init() }
  }
}

## iOS example

For iOS snapshots, a device preset is often the most ergonomic baseline:

```swift
assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
```
```

Swift Testing pattern (suite trait):

```swift
import SnapshotTesting
import Testing

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct FeatureSnapshots {
  // ...
}
```
