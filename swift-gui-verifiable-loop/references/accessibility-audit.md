# Accessibility audits in UI tests

Apple provides a first-party accessibility audit API for UI tests. Audits run the same class of checks as Accessibility Inspector, but can be executed deterministically in CI.

## Minimal example

```swift
import XCTest

final class AccessibilityAuditSmokeTests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testAccessibilityAudit() throws {
    let app = XCUIApplication()
    app.launch()

    // Run an audit on the current screen.
    try app.performAccessibilityAudit()
  }
}
```

## Filtering known false-positives (issue handler)

If you have a known, intentional exception, provide an issue handler to filter it:

```swift
try app.performAccessibilityAudit(for: [.all]) { issue in
  // Return true to continue (do not treat as a failure),
  // return false to fail the test.
  if issue.auditType == .contrast && issue.compactDescription.contains("BrandColor") {
    return true
  }
  return false
}
```

Keep the allowlist **tight** and linked to a specific product decision (otherwise audits will silently rot).

## Notes

- Run at least one audit per major screen family (or per “navigation root”).
- Consider `continueAfterFailure = true` only if you’re intentionally collecting multiple issues in a single run.
- Combine audits with stable accessibility identifiers to reduce flaky UI tests.

Template: `assets/templates/AccessibilityAuditUITestTemplate.swift`

## Sources

- Apple docs: “Performing accessibility audits for your app” and `XCUIApplication.performAccessibilityAudit(for:_:)`
  https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app
  https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit%28for%3A_%3A%29
