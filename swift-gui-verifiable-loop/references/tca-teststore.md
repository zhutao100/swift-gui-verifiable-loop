# TCA TestStore quick reference

If you adopt the Composable Architecture, `TestStore` provides exhaustive, deterministic tests for state/action/effect flows.

## Example (excerpted pattern)

```swift
let store = TestStore(initialState: App.State()) {
  App()
}

// Optionally override dependencies to make effects deterministic.
// (For example: UUID, Date, Clock, and any API clients.)
//
// let store = TestStore(initialState: App.State()) {
//   App()
// } withDependencies: {
//   $0.uuid = .incrementing
// }

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
