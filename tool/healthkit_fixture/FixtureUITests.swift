import XCTest

final class FixtureUITests: XCTestCase {
  func testSyntheticHealthKitRoundTrip() throws {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["fixture-run"].waitForExistence(timeout: 30))
    app.buttons["fixture-run"].tap()
    // HealthKit permission is requested only after the test taps the fixture UI.
    // On this iOS version the sheet's "Turn On All" control is a table Cell, not
    // a Button, and its "Allow" confirm Button (identifier
    // UIA.Health.AuthSheet.DoneButton) starts Disabled until a category is
    // toggled on. Tapping a disabled Done button is a silent no-op that leaves
    // the sheet open and requestAuthorization's completion handler never fires,
    // so both real elements must be addressed by identifier, in order.
    let allCategories = app.cells["UIA.Health.AuthSheet.AllCategoryButton"]
    XCTAssertTrue(allCategories.waitForExistence(timeout: 15))
    allCategories.tap()
    let done = app.buttons["UIA.Health.AuthSheet.DoneButton"]
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    XCTAssertTrue(done.isEnabled)
    done.tap()
    // A single store.save() call with 505 synthetic objects has been observed
    // to take well over 120s on Simulator's HealthKit backing store; this is
    // simulator-only slowness, not evidence of a production hang.
    let finished = NSPredicate(format: "label BEGINSWITH %@ OR label == %@", "Failed", "Passed")
    expectation(for: finished, evaluatedWith: app.staticTexts["fixture-status"])
    waitForExpectations(timeout: 180)
    XCTAssertEqual(app.staticTexts["fixture-status"].label, "Passed")
  }
}
