# SnapshotTesting (Point-Free) quick reference

Upstream: `pointfreeco/swift-snapshot-testing` (latest release is frequently updated; as of March 2026 it is 1.19.1).

## SwiftPM setup (from upstream README)

Add package dependency:

```swift
dependencies: [
  .package(
    url: "https://github.com/pointfreeco/swift-snapshot-testing",
    from: "1.12.0" // use the latest compatible version for your project
  ),
]
```

Add the SnapshotTesting product to your *test* target:

```swift
.testTarget(
  name: "MyAppTests",
  dependencies: [
    "MyApp",
    .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
  ]
)
```

## Basic usage (Swift Testing)

```swift
import SnapshotTesting
import Testing

@MainActor
struct MySnapshots {
  @Test func user_json() {
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(of: user, as: .json)
  }
}
```

## Basic usage (XCTest)

```swift
import SnapshotTesting
import XCTest

final class UserSnapshotTests: XCTestCase {
  func testUser_json() {
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(of: user, as: .json)
  }
}
```

## Snapshot strategies you will use most

- `.image` (visual regression)
- `.recursiveDescription` (text, view hierarchy)
- `.dump` / `.json` / `.plist` (text, stable and agent-readable)

## Recording / updating snapshots (policy)

SnapshotTesting deprecated the global `isRecording` flag in favor of scoped configuration.

- **CI should be strict**: use `record: .never` so missing snapshots fail (rather than being generated during a retry).
- **Local baseline work should be explicit**: set `SNAPSHOT_RECORD=1` and run tests to re-record.

Typical XCTest pattern (wrap `invokeTest`):

```swift
import SnapshotTesting
import XCTest

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
}
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

Template: `assets/templates/SnapshotTestTemplate.swift`
