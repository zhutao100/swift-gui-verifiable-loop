import SnapshotTesting
import SwiftUI
import XCTest

// iOS example: snapshot a SwiftUI view in stable states.
//
// Recommended policy:
// - CI: record: .never
// - Local: record missing by default, and re-record explicitly via SNAPSHOT_RECORD=1

@MainActor
final class ExampleiOSSnapshotTests: XCTestCase {

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

    // iOS: using a device preset provides a familiar baseline.
    // Pin the simulator runtime + device model in your test plan configuration.
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
