# TCA TestStore quick reference

If you adopt the Composable Architecture, `TestStore` provides exhaustive, deterministic tests for state/action/effect flows.

## Example (excerpted pattern)

```swift
let store = TestStore(initialState: App.State()) {
  App()
}

await store.send(\.login.submitButtonTapped) {
  $0.login?.isLoading = true
  // ...
}

await store.receive(\.login.loginResponse.success) {
  $0.login?.isLoading = false
  // ...
}

await store.receive(\.login.delegate.didLogin) {
  $0.selectedTab = .activity
  // ...
}
```

Install via Xcode: add package dependency
`https://github.com/pointfreeco/swift-composable-architecture`.

Template: `assets/templates/TcaTestStoreTemplate.swift`
