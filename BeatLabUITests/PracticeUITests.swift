import XCTest

final class PracticeUITests: XCTestCase {
    @MainActor
    func testDailyLessonOpensLaneAndCanStopWithoutUnlockingNextLesson() async {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings"]
        app.launch()
        let daily = app.buttons["dailyPractice"]
        XCTAssertTrue(daily.waitForExistence(timeout: 5)); daily.tap()
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        let start = app.buttons["startLesson"]
        for _ in 0..<4 where !start.isHittable { app.swipeUp() }
        start.tap()
        let pad = app.buttons["practiceTapPad"]
        XCTAssertTrue(pad.waitForExistence(timeout: 5))
        for _ in 0..<4 where !pad.isHittable { app.swipeUp() }
        pad.tap()
        let stop = app.buttons["stopPractice"]
        for _ in 0..<4 where !stop.isHittable { app.swipeUp() }
        stop.tap()
        let browse = app.buttons["browseLessons"]
        for _ in 0..<6 where !browse.isHittable { app.swipeUp() }
        browse.tap()
        let second = app.buttons["lesson.quarter-hands"]
        for _ in 0..<6 where !second.isHittable { app.swipeUp() }
        XCTAssertFalse(second.isEnabled)
        XCTAssertFalse(app.otherElements["practiceSummary"].exists)
    }
}
