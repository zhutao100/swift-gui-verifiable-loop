import XCTest

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
