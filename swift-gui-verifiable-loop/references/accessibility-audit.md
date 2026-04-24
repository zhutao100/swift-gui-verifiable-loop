# Accessibility audits in UI tests (macOS + iOS)

Xcode provides a first-party accessibility audit API (introduced in Xcode 15) that you can run from UI tests:

```swift
let app = XCUIApplication()
app.launch()
try app.performAccessibilityAudit()
```

## Practical guidance

- Run at least one audit per major screen family.
- If you want to collect multiple issues in one pass, set `continueAfterFailure = true` in `setUpWithError()`.
- Combine audits with stable accessibility identifiers. This improves both test robustness and audit interpretability.

## Targeted audits

You can scope the audit to a subset of checks:

```swift
try app.performAccessibilityAudit(for: .dynamicType)
```

You can also exclude checks:

```swift
try app.performAccessibilityAudit(for: .all.subtracting(.sufficientElementDescription))
```

## Ignoring known issues (with an explicit policy)

When you must temporarily ignore known issues, pass a closure and document why:

```swift
try app.performAccessibilityAudit(for: [.dynamicType, .contrast]) { issue in
  // Return true to ignore this issue.
  return false
}
```

On macOS, keep the ignore policy narrow. Good examples are:

- synthetic SwiftUI container groups emitted by a hosting bridge, when the actionable descendants are already labeled
- host/system controls outside your app surface (for example, Touch Bar items) that still appear in the audit tree

Avoid broad rules such as "ignore all missing descriptions" unless you can tie them to a specific host-generated element class or reproducible framework issue.

Template: `assets/templates/AccessibilityAuditUITestTemplate.swift`
