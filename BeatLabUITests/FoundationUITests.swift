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
        revealFully(practice, in: app)
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
        revealFully(increase, in: app)
        increase.tap()
        let settings = app.buttons["rhythmSettings"]
        revealFully(settings, in: app)
        settings.tap()
        app.buttons["signaturePicker"].tap()
        app.buttons["3/4"].tap()
        app.buttons["subdivisionPicker"].tap()
        app.buttons["八分音符"].tap()
        app.switches["accentToggle"].tap()
        let practice = app.buttons["openPractice"]
        revealFully(practice, in: app)
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
        revealFully(restoredSettings, in: app)
        restoredSettings.tap()
        revealFully(app.switches["accentToggle"], in: app)
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
    func testSharedBrandSurfacesAndSheets() async {
        verifyBrandSurfaces(largest: false)
    }

    @MainActor
    func testSharedBrandLargestTextSurfacesAndSheets() async {
        verifyBrandSurfaces(largest: true)
    }

    @MainActor
    private func verifyBrandSurfaces(largest: Bool) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.navigationBars["拍拍冒險"].waitForExistence(timeout: 5))
        let suffix = largest ? "largest" : "regular"
        saveScreenshot(app, name: "brand-home-\(suffix)")

        openMetronome(app)
        XCTAssertTrue(app.navigationBars["節拍器"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["tempoValue"].exists)
        let transport = app.buttons["transportButton"]
        assertReachableTarget(transport, in: app)
        XCTAssertTrue(transport.label.contains("開始"))
        saveScreenshot(app, name: "brand-metronome-\(suffix)")

        let practice = app.buttons["openPractice"]
        for _ in 0..<14 where !practice.isHittable || practice.frame.maxY > app.tabBars.firstMatch.frame.minY { app.swipeUp() }
        XCTAssertTrue(practice.isHittable)
        practice.tap()
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        saveScreenshot(app, name: "brand-practice-\(suffix)")
        let settings = app.buttons["practiceSettings"]
        assertReachableTarget(settings, in: app)
        settings.tap()
        XCTAssertTrue(app.navigationBars["練習設定"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls["interfaceMode"].exists)
        saveScreenshot(app, name: "brand-settings-\(suffix)")
        app.buttons["完成"].tap()

        let companions = app.buttons["chooseCompanion"]
        for _ in 0..<14 where !companions.isHittable || companions.frame.maxY > app.tabBars.firstMatch.frame.minY { app.swipeUp() }
        assertReachableTarget(companions, in: app)
        companions.tap()
        XCTAssertTrue(app.navigationBars["選擇夥伴"].waitForExistence(timeout: 5))
        saveScreenshot(app, name: "brand-companions-\(suffix)")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.navigationBars["練習"].exists)
        XCTAssertFalse(app.buttons["stopPractice"].exists)
    }

    @MainActor
    private func assertReachableTarget(_ target: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(target.exists)
        XCTAssertTrue(target.isHittable)
        XCTAssertGreaterThanOrEqual(target.frame.width, 44)
        XCTAssertGreaterThanOrEqual(target.frame.height, 44)
        XCTAssertGreaterThanOrEqual(target.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(target.frame.maxY, app.frame.maxY)
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
        revealFully(button, in: app)
        button.tap()
    }
    @MainActor
    private func revealFully(_ element: XCUIElement, in app: XCUIApplication) {
        let sheet = app.navigationBars["練習設定"]
        let top = sheet.exists ? sheet.frame.maxY : app.navigationBars.firstMatch.frame.maxY
        let bottom = sheet.exists ? app.frame.maxY - 24 : app.buttons["transportButton"].exists ? app.buttons["transportButton"].frame.minY : app.tabBars.firstMatch.frame.minY
        for _ in 0..<24 {
            let frame = element.exists ? element.frame : .zero
            if element.exists && element.isHittable && frame.minY >= top && frame.maxY <= bottom { return }
            let middle = (top + bottom) / 2
            let shift = element.exists ? min(220, max(-220, middle - frame.midY)) : -180
            let origin = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            origin.withOffset(CGVector(dx: 0, dy: middle - shift / 2)).press(forDuration: 0.05,
                thenDragTo: origin.withOffset(CGVector(dx: 0, dy: middle + shift / 2)),
                withVelocity: .slow, thenHoldForDuration: 0.15)
        }
        XCTFail("Control was not fully visible: \(element.identifier), \(element.frame)")
    }
    @MainActor
    private func revealPracticeSettings(_ app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        app.buttons["practiceSettings"].tap()
        XCTAssertTrue(app.navigationBars["練習設定"].waitForExistence(timeout: 5))
        let settings = app.buttons["目前自由節拍器設定"]
        revealFully(settings, in: app)
        settings.tap()
        revealFully(app.staticTexts["configurationSummary"], in: app)
    }
}
