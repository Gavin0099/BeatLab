import XCTest

final class PracticeUITests: XCTestCase {
    @MainActor
    func testSeededTenLessonsPreparationStartCancelSmoke() async throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        // The QA runner seeds only this isolated DEBUG suite, with reviewed v1
        // progress. No production bypass and no owner progress are modified.
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.TenLessonSmoke"
        app.launch()
        guard app.staticTexts["10 / 10 關"].waitForExistence(timeout: 5) else {
            throw XCTSkip("Requires explicit isolated TenLessonSmoke fixture; unseeded run is not walkthrough evidence")
        }
        let fixtures = ["first-beat", "quarter-hands", "eighth", "eighth-hands", "quarter-rest", "eighth-rest", "sixteenth", "sixteenth-hands", "offbeat", "mixed"]
        try reveal(app.buttons["dailyPractice"], in: app)
        app.buttons["dailyPractice"].tap()
        for (index, id) in fixtures.enumerated() {
            let browse = app.buttons["browseLessons"]
            try reveal(browse, in: app); browse.tap()
            XCTAssertTrue(app.navigationBars["節奏挑戰"].waitForExistence(timeout: 5))
            let lesson = app.buttons["lesson.\(id)"]
            try reveal(lesson, in: app)
            XCTAssertTrue(lesson.isEnabled)
            lesson.tap()
            XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["preparedLessonNumber"].label.hasPrefix("第 \(index + 1) 關 ·"), "Preparation must match selected catalog ID \(id)")
            capture(app, "Lesson \(index + 1) preparation")
            let start = app.buttons["startLesson"]
            try reveal(start, in: app); start.tap()
            XCTAssertTrue(app.buttons["practiceTapPad"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["activeLessonNumber"].label, "第 \(index + 1) 關 · 節奏跑酷")
            capture(app, "Lesson \(index + 1) count-in smoke")
            let stop = app.buttons["stopPractice"]
            try reveal(stop, in: app); stop.tap()
            XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["journeyProgress"].label, "10 / 10 關完成")
            let prepare = app.buttons["prepareRecommended"]
            try reveal(prepare, in: app); prepare.tap()
        }
    }
    @MainActor
    private func freshApp(largestText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings"]
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch(); return app
    }
    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) throws {
        let course = app.navigationBars["節奏挑戰"]
        if course.exists {
            let scroll = app.scrollViews.firstMatch
            let top = course.frame.maxY
            let bottom = app.frame.maxY - 30
            for _ in 0..<24 {
                XCTAssertTrue(course.exists, "Course sheet must remain presented while scrolling")
                let frame = element.exists ? element.frame : .zero
                if element.exists && element.isHittable && frame.minY >= top && frame.maxY <= bottom { return }
                // A held drag of only a few points can activate a lesson row.
                // Use a scroll gesture and verify the sheet and exact selection.
                if element.exists && frame.midY < (top + bottom) / 2 { scroll.swipeDown(velocity: .slow) }
                else { scroll.swipeUp(velocity: .slow) }
            }
            throw NSError(domain: "PracticeUIVisibility", code: 2, userInfo: [NSLocalizedDescriptionKey: "Course row not visible: \(element.identifier)"])
        }
        let picker = app.navigationBars["選擇夥伴"]
        let inPicker = picker.exists
        let top = inPicker ? picker.frame.maxY : app.navigationBars.firstMatch.frame.maxY
        // A presented sheet covers the underlying tab bar; use its own viewport.
        // The SE has no bottom home-indicator inset. Do not invent a 30pt
        // exclusion zone: use the observed tab bar or actual app viewport.
        let bottom = !inPicker && app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame.minY : app.frame.maxY
        for _ in 0..<24 {
            let frame = element.exists ? element.frame : .zero
            if element.exists && element.isHittable && frame.minY >= top && frame.maxY <= bottom { return }
            let origin = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            let middle = (top + bottom) / 2
            // Center the observed element with a slow, held drag. A fixed fling
            // can jump over the fully visible range of a tall Dynamic Type row.
            let shift = element.exists ? min(220, max(-220, middle - frame.midY)) : -180
            origin.withOffset(CGVector(dx: 0, dy: middle - shift / 2)).press(forDuration: 0.05,
                thenDragTo: origin.withOffset(CGVector(dx: 0, dy: middle + shift / 2)),
                withVelocity: .slow, thenHoldForDuration: 0.15)
        }
        throw NSError(domain: "PracticeUIVisibility", code: 1, userInfo: [NSLocalizedDescriptionKey:
            "Control not visible: \(element.identifier), frame \(element.exists ? element.frame : .zero), viewport \(top)...\(bottom)"])
    }
    @MainActor
    func testDailyLessonOpensLaneAndCanStopWithoutUnlockingNextLesson() async throws {
        let app = freshApp()
        let daily = app.buttons["dailyPractice"]
        XCTAssertTrue(daily.waitForExistence(timeout: 5)); daily.tap()
        XCTAssertTrue(app.navigationBars["練習"].waitForExistence(timeout: 5))
        let start = app.buttons["startLesson"]
        try reveal(start, in: app)
        capture(app, "Journey lesson preparation")
        start.tap()
        let pad = app.buttons["practiceTapPad"]
        XCTAssertTrue(pad.waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["節拍器"].isHittable, "Challenge must not expose tab navigation")
        capture(app, "Journey live drum pad and count-in")
        XCTAssertTrue(app.staticTexts["jumpMatches"].exists)
        XCTAssertTrue(app.staticTexts["jumpCue"].exists)
        pad.tap()
        let stop = app.buttons["stopPractice"]
        try reveal(stop, in: app)
        stop.tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
        let browse = app.buttons["browseLessons"]
        try reveal(browse, in: app)
        browse.tap()
        let second = app.buttons["lesson.quarter-hands"]
        for _ in 0..<6 where !second.isHittable { app.swipeUp() }
        XCTAssertFalse(second.isEnabled)
        XCTAssertFalse(app.staticTexts["practiceSummary"].exists)
    }
    @MainActor
    func testJourneyChaptersLocksSettingsAndHomePreparation() async throws {
        let app = freshApp()
        app.tabBars.buttons["練習"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
        capture(app, "Native rhythm journey map")
        XCTAssertEqual(app.staticTexts["adventureCompanion"].label, "恐龍準備好了！")
        for (key, title) in [("robot", "機器人"), ("dinosaur", "恐龍")] {
            try reveal(app.buttons["chooseCompanion"], in: app); app.buttons["chooseCompanion"].tap()
            XCTAssertTrue(app.navigationBars["選擇夥伴"].waitForExistence(timeout: 5))
            try reveal(app.buttons["companion.\(key)"], in: app); capture(app, "Companion picker \(key)"); app.buttons["companion.\(key)"].tap()
            XCTAssertTrue(app.staticTexts["adventureCompanion"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["adventureCompanion"].label, "\(title)準備好了！")
            XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
            capture(app, "Selected \(key) adventure companion")
        }
        XCTAssertEqual(app.staticTexts["adventureDestination"].label, "起拍小島")
        XCTAssertEqual(app.otherElements["adventureSticker.0"].value as? String, "完成篇章後獲得")
        XCTAssertFalse(app.buttons["journeyLesson.quarter-hands"].isEnabled)
        XCTAssertEqual(app.buttons["journeyLesson.quarter-hands"].value as? String, "完成第 1 關後解鎖")
        try reveal(app.buttons["journeyChapter.1"], in: app); app.buttons["journeyChapter.1"].tap()
        XCTAssertEqual(app.staticTexts["adventureDestination"].label, "回聲森林")
        try reveal(app.staticTexts["adventureDestination"], in: app)
        capture(app, "Adventure echo forest")
        XCTAssertFalse(app.buttons["journeyLesson.eighth"].isEnabled)
        XCTAssertEqual(app.buttons["journeyLesson.eighth"].value as? String, "完成第 2 關後解鎖")
        try reveal(app.buttons["journeyChapter.2"], in: app); app.buttons["journeyChapter.2"].tap()
        XCTAssertEqual(app.staticTexts["adventureDestination"].label, "星光舞台")
        try reveal(app.staticTexts["adventureDestination"], in: app)
        capture(app, "Adventure starlight stage")
        try reveal(app.buttons["journeyChapter.0"], in: app); app.buttons["journeyChapter.0"].tap()
        try reveal(app.buttons["journeyLesson.first-beat"], in: app); app.buttons["journeyLesson.first-beat"].tap()
        XCTAssertTrue(app.buttons["startLesson"].waitForExistence(timeout: 5))
        app.buttons["practiceSettings"].tap()
        XCTAssertTrue(app.navigationBars["練習設定"].waitForExistence(timeout: 5))
        app.segmentedControls["interfaceMode"].buttons["標準"].tap()
        app.navigationBars.buttons["完成"].tap()
        XCTAssertTrue(app.steppers.firstMatch.exists, "Standard mode retains adjustable challenge BPM")
        try reveal(app.buttons["backToJourney"], in: app); app.buttons["backToJourney"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].exists)
        app.tabBars.buttons["首頁"].tap()
        try reveal(app.buttons["dailyPractice"], in: app); app.buttons["dailyPractice"].tap()
        XCTAssertTrue(app.buttons["startLesson"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["journeyProgress"].exists, "Home must open selected preparation rather than remain on the map")
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        XCTAssertTrue(app.staticTexts["activeCompanion"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["activeCompanion"].label, "恐龍陪你跟拍")
        XCTAssertTrue(app.staticTexts["jumpMatches"].exists)
        try reveal(app.staticTexts["jumpMatches"], in: app)
        capture(app, "Selected dinosaur rhythm jump challenge")
        try reveal(app.buttons["stopPractice"], in: app); app.buttons["stopPractice"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
    }
    @MainActor
    func testNoTapChallengeShowsRealFailureAndKeepsNextLocked() async throws {
        let app = freshApp()
        app.buttons["dailyPractice"].tap()
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        XCTAssertTrue(app.staticTexts["practiceSummary"].waitForExistence(timeout: 30))
        XCTAssertEqual(app.otherElements["practiceStars"].label, "這次得到 0 顆星")
        XCTAssertFalse(app.buttons["nextLesson"].exists)
        XCTAssertTrue(app.staticTexts["漏拍 16 下 · 多打 0 下"].exists)
        capture(app, "Native actual no-input result")
        try reveal(app.buttons["returnToJourney"], in: app); app.buttons["returnToJourney"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
        XCTAssertFalse(app.buttons["journeyLesson.quarter-hands"].isEnabled)
        XCTAssertEqual(app.otherElements["adventureSticker.0"].value as? String, "完成篇章後獲得", "A failed run must not award a chapter sticker")
    }
    @MainActor
    func testRunnerCuesAndJumpControlNeverCoverEachOther() async throws {
        let app = freshApp()
        app.buttons["dailyPractice"].tap()
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        let pad = app.buttons["practiceTapPad"]
        XCTAssertTrue(pad.waitForExistence(timeout: 5))
        let cue = app.staticTexts["jumpCue"]
        let stop = app.buttons["stopPractice"]
        let viewport = CGRect(x: 0, y: app.navigationBars.firstMatch.frame.maxY,
                              width: app.frame.width, height: app.frame.maxY - app.navigationBars.firstMatch.frame.maxY)
        for element in [cue, pad, stop] {
            XCTAssertTrue(element.exists)
            XCTAssertGreaterThan(element.frame.height, 0)
            XCTAssertTrue(viewport.contains(element.frame), "Clipped \(element.identifier): \(element.frame)")
        }
        // SwiftUI can expose both a container and inherited child IDs. Measure
        // the union of all lane frames rather than silently picking a child.
        let laneElements = app.descendants(matching: .any).matching(identifier: "rhythmLane").allElementsBoundByIndex
        XCTAssertFalse(laneElements.isEmpty)
        let laneFrame = laneElements.reduce(CGRect.null) { $0.union($1.frame) }
        XCTAssertTrue(viewport.contains(laneFrame), "Clipped rhythm lane: \(laneFrame)")
        XCTAssertLessThanOrEqual(laneFrame.maxY, pad.frame.minY, "Rhythm cannot be hidden beneath jump pad")
        XCTAssertLessThanOrEqual(pad.frame.maxY, stop.frame.minY)
        capture(app, "Runner complete viewport")
        try await Task.sleep(nanoseconds: 3_000_000_000)
        capture(app, "Runner approaching obstacles mid-run")
        pad.tap(withNumberOfTaps: 2, numberOfTouches: 1)
        XCTAssertTrue(app.staticTexts["多打一下，再跟上"].waitForExistence(timeout: 3))
        stop.tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
    }

    @MainActor
    func testRunnerLargeTextCanReachSceneRhythmJumpAndStop() async throws {
        // Capturing all four regions can consume the real 20-second lesson.
        // Keep its duration unchanged and verify two independent real runs.
        for inputControls in [true, false] {
            let app = freshApp(largestText: true)
            app.buttons["dailyPractice"].tap()
            try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
            let pad = app.buttons["practiceTapPad"]
            XCTAssertTrue(pad.waitForExistence(timeout: 5))
            if inputControls {
                try reveal(pad, in: app); capture(app, "Runner large-text jump")
                let stop = app.buttons["stopPractice"]
                try reveal(stop, in: app); capture(app, "Runner large-text stop")
                print("Observed largest-text stop frame \(stop.frame), app viewport \(app.frame)")
                stop.tap()
                XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
            } else {
                try reveal(app.staticTexts["jumpCue"], in: app); capture(app, "Runner large-text scene")
                let rhythm = app.descendants(matching: .any).matching(identifier: "rhythmLane").firstMatch
                try reveal(rhythm, in: app); capture(app, "Runner large-text rhythm")
                app.terminate()
            }
        }
    }

    @MainActor
    func testRealTouchesClearObstaclesAndNewRunStartsEmpty() async throws {
        let app = freshApp()
        app.buttons["dailyPractice"].tap()
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        let pad = app.buttons["practiceTapPad"]
        XCTAssertTrue(pad.waitForExistence(timeout: 5))
        let counter = app.staticTexts["jumpMatches"]
        // Real UI touches, no injected TimingHit or fake clock. This proves
        // visual clearance can follow actual matching, not timing precision.
        for _ in 0..<10 {
            if counter.exists && !counter.label.hasPrefix("跨過 0 ") { break }
            pad.tap()
        }
        XCTAssertTrue(counter.exists)
        XCTAssertFalse(counter.label.hasPrefix("跨過 0 "), "Actual matched touches must clear an obstacle")
        capture(app, "Runner actual matched touch clearance")
        app.buttons["stopPractice"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        let first = app.buttons["journeyLesson.first-beat"]
        try reveal(first, in: app); first.tap()
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        XCTAssertEqual(counter.label, "跨過 0 個障礙 · 休止格先等一下")
        app.buttons["stopPractice"].tap()
    }

}
