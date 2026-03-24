# Deterministic UI entry harnesses (launch args, env, deep links)

UI smoke tests become reliable only if they can **jump directly** into a known state without long navigation paths.

This doc gives copy/paste patterns for both **app code** and **XCUITest code**.

## XCUITest-side patterns

### Launch arguments and environment

```swift
let app = XCUIApplication()
app.launchArguments += ["--ui-testing", "--start-screen", "settings"]
app.launchEnvironment["FIXTURE_SET"] = "smoke"
app.launchEnvironment["NETWORK_MODE"] = "stubbed"
app.launch()
```

### Deep links / custom URLs

```swift
let app = XCUIApplication()
app.launchArguments += ["--ui-testing"]
app.launchEnvironment["DEEPLINK_URL"] = "myapp://open/settings?tab=general"
app.launch()
```

## App-side routing pattern

### Centralize test-mode handling

On iOS, this is typically in `App` / `SceneDelegate` / early app startup.
On macOS, this is typically around `NSApplicationDelegate` / early window creation.

Example (SwiftUI app):

```swift
import SwiftUI

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      RootView(entry: EntryPoint.fromProcessEnvironment())
    }
  }
}

enum EntryPoint: Equatable {
  case normal
  case startScreen(String)
  case deepLink(URL)

  static func fromProcessEnvironment() -> Self {
    let args = ProcessInfo.processInfo.arguments
    let env = ProcessInfo.processInfo.environment

    if env["DEEPLINK_URL"].flatMap(URL.init(string:)) != nil, let url = env["DEEPLINK_URL"].flatMap(URL.init(string:)) {
      return .deepLink(url)
    }
    if let idx = args.firstIndex(of: "--start-screen"), idx + 1 < args.count {
      return .startScreen(args[idx + 1])
    }
    return .normal
  }
}
```

Then in your root view, route deterministically:

```swift
struct RootView: View {
  let entry: EntryPoint

  var body: some View {
    switch entry {
    case .normal:
      HomeView()
    case .startScreen(let name):
      RoutedView(name: name)
    case .deepLink(let url):
      DeepLinkRouter(url: url)
    }
  }
}
```

## Disable animations in test mode (stability)

- iOS: set `UIView.setAnimationsEnabled(false)` or use `UIWindow` animation overrides when `--ui-testing` is present.
- SwiftUI: prefer semantics over animation assertions; for tests, gate animation-heavy code paths behind a flag in your view model/dependencies.

## Sources / inspiration

- Apple video: “Record, replay, and review: UI automation with Xcode” (XCUIAutomation best practices):
  https://developer.apple.com/videos/play/wwdc2025/344/
