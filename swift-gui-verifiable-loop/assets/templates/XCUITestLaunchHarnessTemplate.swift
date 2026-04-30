import XCTest

// macOS example: keep UI smoke tests short and anchor on stable accessibility identifiers.

final class SmokeFlowTests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLaunchIntoDeterministicState() throws {
    let app = XCUIApplication()

    // Deterministic entry harness:
    app.launchArguments += ["--uitest", "--seed-fixtures", "--start-screen", "Settings"]
    app.launchEnvironment["FIXTURE_SET"] = "smoke"
    app.launchEnvironment["NETWORK_MODE"] = "stubbed"

    app.launch()

    // macOS: anchor on a stable root element early.
    // Prefer explicit accessibility identifiers on your main window/content root.
    let mainWindow = app.windows["main.window"]
    XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))

    // Prefer accessibility identifiers over localized text.
    let saveButton = app.buttons["settings.save"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
    saveButton.click()

    // Example: validating a menu action (common in macOS apps).
    // (Use menu titles only if you control them and they are stable; identifiers are preferred when available.)
    let fileMenu = app.menuBars.menuBarItems["File"]
    if fileMenu.exists {
      fileMenu.click()
      let newItem = app.menuItems["New"]
      if newItem.exists { newItem.click() }
    }

    // Evidence enrichment on failure:
    // Prefer element/window screenshots over XCUIScreen.main.screenshot(), which can
    // capture the full desktop on macOS.
    if !app.staticTexts["settings.savedBanner"].waitForExistence(timeout: 5) {
      let att = XCTAttachment(screenshot: mainWindow.screenshot())
      att.name = "main-window-after-save"
      att.lifetime = .keepAlways
      add(att)

      let debug = XCTAttachment(string: app.debugDescription)
      debug.name = "accessibility-tree-after-save"
      debug.lifetime = .keepAlways
      add(debug)

      XCTFail("Expected saved banner")
    }
  }
}
