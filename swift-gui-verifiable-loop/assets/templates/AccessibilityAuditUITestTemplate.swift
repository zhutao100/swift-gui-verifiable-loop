import XCTest

final class AccessibilityAuditSmokeTests: XCTestCase {

  override func setUpWithError() throws {
    // If you want to collect multiple audit issues in a single run, set this to true.
    continueAfterFailure = true
  }

  func testAccessibilityAudit() throws {
    let app = XCUIApplication()
    app.launch()

    // Run an audit on the current screen.
    // You can scope audits to specific checks (e.g. `.dynamicType`, `.contrast`) or use `.all`.
    try app.performAccessibilityAudit(for: .all)

    // Optional: ignore known issues with an explicit policy.
    // Keep ignores narrow and evidence-backed, especially on macOS where system-hosted controls
    // (for example, Touch Bar items) can leak into the audit surface.
    // try app.performAccessibilityAudit(for: .all) { issue in
    //   issue.compactDescription == "Action is missing"
    //     && issue.detailedDescription.contains("click/tap inputs")
    // }
  }
}
