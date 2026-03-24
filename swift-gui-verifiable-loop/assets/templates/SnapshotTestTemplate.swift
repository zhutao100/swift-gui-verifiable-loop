import SnapshotTesting
import SwiftUI
import XCTest

// Example: snapshot a SwiftUI view in stable states.
//
// Recording policy:
// - Local: allow recording missing snapshots (SnapshotTesting default) and re-record explicitly.
// - CI: never record (missing snapshots should fail deterministically).
//
// To intentionally re-record snapshots locally:
//   SNAPSHOT_RECORD=1 xcodebuild ... test

@MainActor
final class ExampleSnapshotTests: XCTestCase {

  override func invokeTest() {
    let env = ProcessInfo.processInfo.environment

    let record: SnapshotTestingConfiguration.Record =
      env["SNAPSHOT_RECORD"] == "1" ? .all :
      (env["CI"] == "true" ? .never : .missing)

    // Optional: configure a diff tool (Kaleidoscope example).
    // `SnapshotTestingConfiguration.DiffTool.ksdiff` is provided by SnapshotTesting.
    withSnapshotTesting(record: record, diffTool: .ksdiff) {
      super.invokeTest()
    }
  }

  func testSettingsView_lightMode() {
    let view = SettingsView(model: .fixture())
      .environment(\.colorScheme, .light)

    // Prefer text-based strategies for stability when possible.
    // assertSnapshot(of: view, as: .dump)

    // Image snapshots are useful but environment-sensitive.
    // Pin simulator + device config, and keep rendering deterministic.
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
  }
}

private struct SettingsView: View {
  let model: Model
  var body: some View { Text("Settings") }

  struct Model {
    static func fixture() -> Self { .init() }
  }
}
