# Accessibility audits in UI tests

Apple provides a first-party accessibility audit API for UI tests:

```swift
let app = XCUIApplication()
app.launch()
try app.performAccessibilityAudit()
```

Notes:

- Run at least one audit per major screen family.
- Consider `continueAfterFailure = true` if you want to collect multiple issues in one pass.
- Combine audits with stable accessibility identifiers to reduce flaky UI tests.

Template: `assets/templates/AccessibilityAuditUITestTemplate.swift`
