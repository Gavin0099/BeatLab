import XCTest

final class InterfaceUITests: XCTestCase {
    @MainActor
    private func freshApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings"]
        app.launch()
        return app
    }
    @MainActor
    func testMetronomeTransportRemainsReachableAfterScrollingSettings() async {
        let app = freshApp()
        app.tabBars.buttons["節拍器"].tap()
        let transport = app.buttons["transportButton"]
        XCTAssertTrue(transport.waitForExistence(timeout: 5))
        for _ in 0..<5 { app.swipeUp() }
        XCTAssertTrue(transport.isHittable, "Transport must stay available below the scrolling controls")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Metronome controls and persistent transport"
        attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor
    func testCourseBrowserExplainsLocksAndReturnsToSelectedLesson() async {
        let app = freshApp()
        app.buttons["dailyPractice"].tap()
        let browse = app.buttons["browseLessons"]
        for _ in 0..<6 where !browse.isHittable { app.swipeUp() }
        browse.tap()
        XCTAssertTrue(app.navigationBars["節奏挑戰"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["lesson.first-beat"].isEnabled)
        XCTAssertFalse(app.buttons["lesson.quarter-hands"].isEnabled)
        XCTAssertTrue(app.buttons["lesson.quarter-hands"].value as? String == "完成第 1 關後解鎖")
        app.buttons["lesson.first-beat"].tap()
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["startLesson"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Lesson preparation and rhythm legend"
        attachment.lifetime = .keepAlways; add(attachment)
    }
}
