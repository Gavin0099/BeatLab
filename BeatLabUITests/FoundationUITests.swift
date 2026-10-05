import XCTest

final class FoundationUITests: XCTestCase {
    @MainActor
    private func launchFreshApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    @MainActor
    func testLaunchAndHomeMetronomePracticeNavigation() async {
        let app = launchFreshApp()
        XCTAssertTrue(app.navigationBars["拍拍冒險"].waitForExistence(timeout: 5))
        openMetronome(app)
        XCTAssertTrue(app.navigationBars["節拍器"].waitForExistence(timeout: 5))
        let practice = app.buttons["openPractice"]
        for _ in 0..<6 where !practice.isHittable { app.swipeUp() }
        practice.tap()
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        revealPracticeSettings(app)
        XCTAssertEqual(app.staticTexts["configurationSummary"].label, "80 BPM · 4/4")
    }

    @MainActor
    func testConfigurationIsSharedAndAllFourFieldsSurviveRelaunch() async {
        let app = launchFreshApp()
        openMetronome(app)
        let increase = app.buttons["tempoPlusOne"]
        for _ in 0..<6 where !increase.isHittable { app.swipeUp() }
        increase.tap()
        let settings = app.buttons["rhythmSettings"]
        for _ in 0..<6 where !settings.isHittable { app.swipeUp() }
        settings.tap()
        app.buttons["signaturePicker"].tap()
        app.buttons["3/4"].tap()
        app.buttons["subdivisionPicker"].tap()
        app.buttons["八分音符"].tap()
        app.switches["accentToggle"].tap()
        let practice = app.buttons["openPractice"]
        for _ in 0..<6 where !practice.isHittable { app.swipeUp() }
        practice.tap()
        revealPracticeSettings(app)
        XCTAssertEqual(app.staticTexts["configurationSummary"].label, "81 BPM · 3/4")
        XCTAssertEqual(app.staticTexts["subdivisionSummary"].label, "八分音符")
        XCTAssertEqual(app.staticTexts["accentSummary"].label, "第一拍重音：關閉")

        // Let an event loop turn occur through the screen assertion, then relaunch
        // the actual process without resetting the test suite.
        app.terminate()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.navigationBars["拍拍冒險"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["configurationSummary"].label, "81 BPM · 3/4")
        XCTAssertEqual(app.staticTexts["subdivisionSummary"].label, "八分音符")
        XCTAssertEqual(app.staticTexts["accentSummary"].label, "第一拍重音：關閉")
        openMetronome(app)
        let restoredSettings = app.buttons["rhythmSettings"]
        for _ in 0..<6 where !restoredSettings.isHittable { app.swipeUp() }
        restoredSettings.tap()
        for _ in 0..<6 where !app.switches["accentToggle"].isHittable { app.swipeUp() }
        XCTAssertEqual(app.switches["accentToggle"].value as? String, "0")
    }
    @MainActor
    func testHomepageAdventureOpensRecommendedLessonWithoutStartingAudio() async {
        let app = launchFreshApp()
        XCTAssertTrue(app.staticTexts["homeRecommendedLesson"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["homeRecommendedLesson"].label, "找到大拍")
        let start = app.buttons["dailyPractice"]
        for _ in 0..<6 where !start.isHittable || start.frame.maxY > app.tabBars.firstMatch.frame.minY { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        XCTAssertLessThanOrEqual(start.frame.maxY, app.tabBars.firstMatch.frame.minY)
        saveScreenshot(app, name: "home-light")
        start.tap()
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["startLesson"].exists)
        XCTAssertFalse(app.buttons["stopPractice"].exists)
    }

    @MainActor
    func testHomepageLargestTextKeepsBothEntryPointsReachable() async {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.navigationBars["拍拍冒險"].waitForExistence(timeout: 5))
        saveScreenshot(app, name: "home-largest-top")
        let start = app.buttons["dailyPractice"]
        for _ in 0..<12 where !start.isHittable || start.frame.maxY > app.tabBars.firstMatch.frame.minY { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        XCTAssertLessThanOrEqual(start.frame.maxY, app.tabBars.firstMatch.frame.minY)
        saveScreenshot(app, name: "home-largest-start")
        start.tap()
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        app.tabBars.buttons["首頁"].tap()
        let metronome = app.buttons["openMetronome"]
        for _ in 0..<14 where !metronome.isHittable || metronome.frame.maxY > app.tabBars.firstMatch.frame.minY { app.swipeUp() }
        XCTAssertTrue(metronome.isHittable)
        XCTAssertLessThanOrEqual(metronome.frame.maxY, app.tabBars.firstMatch.frame.minY)
        saveScreenshot(app, name: "home-largest-metronome")
        metronome.tap()
        XCTAssertTrue(app.navigationBars["節拍器"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func saveScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func openMetronome(_ app: XCUIApplication) {
        let button = app.buttons["openMetronome"]
        for _ in 0..<6 where !button.isHittable { app.swipeUp() }
        button.tap()
    }
    @MainActor
    private func revealPracticeSettings(_ app: XCUIApplication) {
        app.buttons["practiceSettings"].tap()
        XCTAssertTrue(app.navigationBars["練習設定"].waitForExistence(timeout: 5))
        let settings = app.buttons["目前自由節拍器設定"]
        for _ in 0..<8 where !settings.isHittable { app.swipeUp() }
        settings.tap()
        for _ in 0..<3 where !app.staticTexts["configurationSummary"].isHittable { app.swipeUp() }
    }
}
