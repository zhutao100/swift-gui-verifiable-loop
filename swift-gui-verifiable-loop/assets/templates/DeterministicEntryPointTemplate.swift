import Foundation
import SwiftUI

/// Drop-in pattern for deterministic UI entry points.
///
/// Use this to make XCUITests stable:
/// - tests set args/env/DEEPLINK_URL
/// - app routes directly into the desired state
///
/// Prefer routing into *semantic* screens/states rather than re-playing long UI navigation flows.

enum UITestEntryPoint: Equatable {
  case normal
  case startScreen(String)
  case deepLink(URL)

  static func fromProcess() -> Self {
    let args = ProcessInfo.processInfo.arguments
    let env = ProcessInfo.processInfo.environment

    if let s = env["DEEPLINK_URL"], let url = URL(string: s) {
      return .deepLink(url)
    }
    if let idx = args.firstIndex(of: "--start-screen"), idx + 1 < args.count {
      return .startScreen(args[idx + 1])
    }
    return .normal
  }
}

struct UITestEntryRouter<Normal: View>: View {
  let entry: UITestEntryPoint
  @ViewBuilder let normal: () -> Normal

  var body: some View {
    switch entry {
    case .normal:
      normal()
    case .startScreen(let name):
      RoutedView(name: name)
    case .deepLink(let url):
      DeepLinkRouter(url: url)
    }
  }
}

/// Replace these with your real routing implementation.
private struct RoutedView: View {
  let name: String
  var body: some View { Text("Routed: \(name)") }
}

private struct DeepLinkRouter: View {
  let url: URL
  var body: some View { Text("Deep link: \(url.absoluteString)") }
}
