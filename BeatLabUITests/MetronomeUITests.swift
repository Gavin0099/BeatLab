import XCTest

final class MetronomeUITests: XCTestCase {
    @MainActor
    func testStartStopAndControlBounds() async {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings"]
        app.launch()
        app.tabBars.buttons["節拍器"].tap()
        let transport = app.buttons["transportButton"]
        XCTAssertTrue(transport.waitForExistence(timeout: 5))
        transport.tap()
        XCTAssertTrue(transport.label.contains("停止"))
        transport.tap()
        XCTAssertTrue(transport.label.contains("開始"))
        let increase = app.buttons["tempoPlusFive"]
        for _ in 0..<6 where !increase.isHittable { app.swipeUp() }
        increase.tap()
        XCTAssertTrue(app.staticTexts["tempoValue"].label.contains("85 BPM"))
        app.buttons["tempoMinusFive"].tap()
        XCTAssertTrue(app.staticTexts["tempoValue"].label.contains("80 BPM"))
    }
}
