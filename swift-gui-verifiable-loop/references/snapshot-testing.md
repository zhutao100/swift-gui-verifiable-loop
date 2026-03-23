# SnapshotTesting (Point-Free) quick reference

Upstream docs: `pointfreeco/swift-snapshot-testing`

## SwiftPM setup (from upstream README)

Add package dependency:

```swift
dependencies: [
  .package(
    url: "https://github.com/pointfreeco/swift-snapshot-testing",
    from: "1.12.0"
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

## Basic usage

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

## Recording / updating snapshots (policy)

- Recording is a deliberate action. Typical pattern:

```swift
import SnapshotTesting

final class MySnapshots: XCTestCase {
  override func setUp() {
    super.setUp()
    // Set this to true only while intentionally updating snapshots.
    isRecording = false
  }
}
```

Recommended: gate recording behind an env var (e.g., `SNAPSHOT_RECORD=1`) so agents cannot accidentally update baselines in CI.

Template: `assets/templates/SnapshotTestTemplate.swift`
