import XCTest

final class AccessibilityAuditSmokeTests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testAccessibilityAudit() throws {
    let app = XCUIApplication()
    app.launch()

    // Run audit on the current screen.
    try app.performAccessibilityAudit()
  }
}
