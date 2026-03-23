import XCTest
import SnapshotTesting
import SwiftUI

// Example: snapshot a SwiftUI view in stable states.
// Policy: gate recording behind an env var so CI cannot mutate baselines.

final class ExampleSnapshotTests: XCTestCase {

  override func setUp() {
    super.setUp()

    // Record mode: export SNAPSHOT_RECORD=1 when intentionally updating snapshots.
    isRecording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

    // Optional: pick your diff tool (e.g., Kaleidoscope)
    // SnapshotTesting.diffToolCommand = { "ksdiff \($0) \($1)" }
  }

  func testSettingsView_lightMode() {
    let view = SettingsView(model: .fixture())
      .environment(\.colorScheme, .light)

    // Prefer text/hierarchy strategies for stability when possible.
    // assertSnapshot(of: view, as: .dump) // text-based
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
