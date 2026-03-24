import XCTest

/// Minimal macOS UI smoke test that asserts a menu item is enabled and triggers it.
///
/// Notes:
/// - Prefer accessibility identifiers for windows and controls.
/// - Menu titles are often localized; if you must use them, keep them stable (e.g. non-localized in test mode).
final class MacOSMenuSmokeTests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testFileNewMenuItemEnabled() throws {
    let app = XCUIApplication()
    app.launchArguments += ["--uitest"]
    app.launch()

    // Anchor on a window (identifier recommended).
    XCTAssertTrue(app.windows["main.window"].waitForExistence(timeout: 5))

    // Open File > New.
    let fileMenu = app.menuBars.menuBarItems["File"]
    XCTAssertTrue(fileMenu.waitForExistence(timeout: 5))
    fileMenu.click()

    let newItem = app.menuItems["New"]
    XCTAssertTrue(newItem.waitForExistence(timeout: 5))
    XCTAssertTrue(newItem.isEnabled)
    newItem.click()

    // Assert the expected result (prefer an identifier).
    XCTAssertTrue(app.windows["document.window"].waitForExistence(timeout: 5))
  }
}
