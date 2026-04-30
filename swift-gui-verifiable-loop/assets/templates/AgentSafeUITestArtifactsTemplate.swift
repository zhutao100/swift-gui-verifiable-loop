import XCTest

// Copy this helper into UI test targets that need agent-safe evidence.
// It intentionally avoids XCUIScreen.main.screenshot(); on macOS prefer window
// or root-element screenshots because XCUIApplication.screenshot() can be
// display-sized on some runners.

extension XCTestCase {
  func attachAgentSafeScreenshot(
    of element: XCUIScreenshotProviding,
    named name: String,
    lifetime: XCTAttachment.Lifetime = .keepAlways
  ) {
    let attachment = XCTAttachment(screenshot: element.screenshot())
    attachment.name = name
    attachment.lifetime = lifetime
    add(attachment)
  }

  func attachAccessibilityTree(
    of app: XCUIApplication,
    named name: String = "accessibility-tree",
    lifetime: XCTAttachment.Lifetime = .keepAlways
  ) {
    let attachment = XCTAttachment(string: app.debugDescription)
    attachment.name = name
    attachment.lifetime = lifetime
    add(attachment)
  }
}
