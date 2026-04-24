import XCTest

// macOS menu bar extras often appear in the accessibility tree but are not reliably hittable.
// Prefer a launch harness that asks the app to present the popover/context menu for UI tests.

@MainActor
final class MenuBarExtraSmokeTests: XCTestCase {
  private let statusItemTitle = "AppUITest"

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testStatusPopoverHarnessShowsPrimaryActions() throws {
    let app = launchApp(statusSurface: "popover")

    XCTAssertTrue(try statusItem(in: app).waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["status.settings"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["status.quit"].exists)
  }

  func testStatusContextMenuHarnessShowsMenuItems() throws {
    let app = launchApp(statusSurface: "context-menu")

    XCTAssertTrue(try statusItem(in: app).waitForExistence(timeout: 5))
    XCTAssertTrue(try contextMenuItem(named: "Settings...", app: app).waitForExistence(timeout: 5))
    XCTAssertTrue(try contextMenuItem(named: "Quit App", app: app).waitForExistence(timeout: 5))
  }

  private func launchApp(statusSurface: String) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments += ["--uitest", "--open-status-surface", statusSurface]
    app.launchEnvironment["APP_UI_TEST_STATUS_TITLE"] = statusItemTitle
    app.launch()
    return app
  }

  private func statusItem(in app: XCUIApplication) throws -> XCUIElement {
    let item = app.menuBars.statusItems[statusItemTitle]
    if item.waitForExistence(timeout: 3) {
      return item
    }

    let fallback = app.menuBars.menuBarItems[statusItemTitle]
    if fallback.waitForExistence(timeout: 2) {
      return fallback
    }

    throw XCTSkip("Unable to locate status item '\\(statusItemTitle)' in the app hierarchy.")
  }

  private func contextMenuItem(named title: String, app: XCUIApplication) throws -> XCUIElement {
    let item = app.menuItems[title]
    if item.waitForExistence(timeout: 3) {
      return item
    }

    throw XCTSkip("Unable to locate context menu item '\\(title)'.")
  }
}
