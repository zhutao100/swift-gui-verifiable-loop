import XCTest

// iOS example: keep UI smoke tests short and anchor on stable accessibility identifiers.
//
// Notes:
// - Use deterministic entry harnesses (launch args/env/deep links).
// - Prefer `.tap()` over `.click()`.
// - For simulator determinism, consider pre-granting permissions via `xcrun simctl privacy ...`.

final class iOSSmokeFlowTests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLaunchIntoDeterministicState() throws {
    let app = XCUIApplication()

    // Deterministic entry harness:
    app.launchArguments += ["--uitest", "--seed-fixtures", "--start-screen", "Settings"]
    app.launchEnvironment["FIXTURE_SET"] = "smoke"
    app.launchEnvironment["NETWORK_MODE"] = "stubbed"

    // Handle common permission alerts (location/notifications/etc.) if they appear.
    addUIInterruptionMonitor(withDescription: "System Dialog") { alert in
      for label in ["Allow", "Allow While Using App", "OK", "Don’t Allow"] {
        if alert.buttons[label].exists {
          alert.buttons[label].tap()
          return true
        }
      }
      return false
    }

    app.launch()

    // The interruption monitor requires an interaction to trigger.
    app.tap()

    // Prefer accessibility identifiers over localized text.
    let saveButton = app.buttons["settings.save"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
    saveButton.tap()

    // Evidence enrichment on failure:
    if !app.staticTexts["settings.savedBanner"].waitForExistence(timeout: 5) {
      let shot = XCUIScreen.main.screenshot()
      let att = XCTAttachment(screenshot: shot)
      att.lifetime = .keepAlways
      add(att)
      XCTFail("Expected saved banner")
    }
  }
}
