import Foundation

/// App-side harness for deterministic UI tests on macOS.
///
/// Pattern:
/// - UI tests set launch arguments and environment variables on `XCUIApplication`.
/// - The app reads them during startup and configures deterministic behavior:
///   - fixture data
///   - stubbed networking
///   - deterministic clocks/UUIDs (where feasible)
///   - an explicit start screen/window
///
/// Keep this code in the app target (or a small shared module) so that UI tests are short and stable.

enum UITestHarness {
  static var isEnabled: Bool {
    ProcessInfo.processInfo.arguments.contains("--uitest")
  }

  static var startScreen: String? {
    // Example arg: --start-screen Settings
    let args = ProcessInfo.processInfo.arguments
    guard let i = args.firstIndex(of: "--start-screen"), i + 1 < args.count else { return nil }
    return args[i + 1]
  }

  static var fixtureSet: String? {
    ProcessInfo.processInfo.environment["FIXTURE_SET"]
  }

  static var networkMode: String? {
    // Example values: "live" | "stubbed"
    ProcessInfo.processInfo.environment["NETWORK_MODE"]
  }

  static var disableAnimations: Bool {
    ProcessInfo.processInfo.environment["DISABLE_ANIMATIONS"] == "1"
  }
}

/*

// SwiftUI App example:

import SwiftUI

@main
struct MyMacApp: App {
  init() {
    guard UITestHarness.isEnabled else { return }

    // Configure deterministic services here.
    // Example: AppDependencies.shared.network = .stubbed
    // Example: AppDependencies.shared.clock = .immediate

    if UITestHarness.disableAnimations {
      // Prefer disabling animations at the call sites via transactions,
      // or gate animations on `UITestHarness.isEnabled`.
      // (There is no single global switch that reliably disables all SwiftUI/AppKit animations.)
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(\.locale, .init(identifier: "en_US"))
        .transaction { txn in
          if UITestHarness.isEnabled && UITestHarness.disableAnimations {
            txn.disablesAnimations = true
          }
        }
    }
  }
}

*/
