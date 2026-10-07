import XCTest

final class PracticeUITests: XCTestCase {
    @MainActor
    private func openFirstCompanionLesson(in app: XCUIApplication) throws {
        let lesson = app.buttons["journeyLesson.first-beat"]
        // Observe the visible, hittable frame, then prove the actual touch and
        // exact transition without a launch route or score substitution.
        try reveal(lesson, in: app)
        XCTAssertTrue(lesson.isEnabled)
        lesson.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["preparedLessonNumber"].label.hasPrefix("第 1 關 ·"))
    }
    @MainActor
    private func openCompanion(_ key: String, in app: XCUIApplication) throws {
        app.tabBars.buttons["練習"].tap()
        try reveal(app.buttons["chooseCompanion"], in: app); app.buttons["chooseCompanion"].tap()
        XCTAssertTrue(app.navigationBars["選擇夥伴"].waitForExistence(timeout: 5))
        try reveal(app.buttons["companion.\(key)"], in: app); app.buttons["companion.\(key)"].tap()
        try openFirstCompanionLesson(in: app)
    }
    @MainActor
    private func companionTouchRetry(_ key: String, title: String, mission: String) throws {
        let app = freshApp(); try openCompanion(key, in: app)
        XCTAssertTrue(app.staticTexts[mission].exists); capture(app, "\(key) themed preparation")
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        XCTAssertTrue(app.buttons["practiceTapPad"].waitForExistence(timeout: 5))
        let scene = app.otherElements["eggMissionScene"], pad = app.buttons["practiceTapPad"], stop = app.buttons["stopPractice"]
        // Resolve the geometry once, then send a genuine multitap gesture.
        // Repeated AX queries plus a4s sleep used up the actual20s lesson.
        XCTAssertTrue(scene.exists); XCTAssertLessThan(scene.frame.maxY, pad.frame.minY)
        XCTAssertTrue(pad.isHittable)
        pad.tap(withNumberOfTaps: 10, numberOfTouches: 1)
        XCTAssertFalse(app.staticTexts["jumpMatches"].label.hasPrefix("抵達 0 "), "Actual UIKit touches must produce a real accepted hit")
        capture(app, "\(key) actual live runner"); stop.tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
        try openFirstCompanionLesson(in: app)
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        XCTAssertTrue(app.staticTexts["jumpMatches"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["jumpMatches"].label, "抵達 0 / 16 座小島")
        app.buttons["stopPractice"].tap()
    }
    @MainActor
    func testCatCloudActualTouchCancelAndRestart() throws {
        try companionTouchRetry("cat", title: "貓咪", mission: "把魚送回雲端小屋")
    }
    @MainActor
    func testRobotCircuitActualTouchCancelAndRestart() throws {
        try companionTouchRetry("robot", title: "機器人", mission: "把能源送回充電站")
    }
    @MainActor
    func testBothCompanionsNoInputReallyFailsAndRetryKeepsProgressLocked() throws {
        for key in ["cat", "robot"] {
            let app = freshApp(); try openCompanion(key, in: app)
            try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
            XCTAssertTrue(app.staticTexts["practiceSummary"].waitForExistence(timeout: 30))
            XCTAssertEqual(app.staticTexts["practiceSummary"].label, key == "cat" ? "魚包裹接住了，再試一次！" : "能源接住了，再試一次！")
            XCTAssertEqual(app.otherElements["practiceStars"].label, "這次得到 0 顆星")
            XCTAssertFalse(app.buttons["nextLesson"].exists); capture(app, "\(key) actual failure")
            try reveal(app.buttons["retryLesson"], in: app); app.buttons["retryLesson"].tap()
            XCTAssertTrue(app.staticTexts["jumpMatches"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["jumpMatches"].label, "抵達 0 / 16 座小島")
            app.buttons["stopPractice"].tap()
            XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["journeyLesson.quarter-hands"].isEnabled)
        }
    }
    @MainActor
    func testBothCompanionLargestTextControlsCanBeReached() throws {
        for key in ["cat", "robot"] {
            let app = freshApp(largestText: true); try openCompanion(key, in: app)
            capture(app, "\(key) accessibility preparation")
            try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
            XCTAssertTrue(app.buttons["practiceTapPad"].waitForExistence(timeout: 5))
            try reveal(app.buttons["stopPractice"], in: app); capture(app, "\(key) accessibility stop")
            app.buttons["stopPractice"].tap()
            try openFirstCompanionLesson(in: app)
            try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
            try reveal(app.buttons["practiceTapPad"], in: app); XCTAssertTrue(app.buttons["practiceTapPad"].isHittable)
            capture(app, "\(key) accessibility pad")
            app.terminate()
        }
    }
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
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, requiresHit: Bool = true) throws {
        let window = app.windows.firstMatch
        XCTAssertGreaterThan(window.frame.width, 300, "A real primary window is required for scrolling")
        let course = app.navigationBars["節奏挑戰"]
        if course.exists {
            let scroll = app.scrollViews.firstMatch
            let top = course.frame.maxY
            let bottom = window.frame.maxY - 30
            for _ in 0..<24 {
                XCTAssertTrue(course.exists, "Course sheet must remain presented while scrolling")
                let frame = element.exists ? element.frame : .zero
                if element.exists && frame.minY >= top && frame.maxY <= bottom && (!requiresHit || element.isHittable) { return }
                // A held drag of only a few points can activate a lesson row.
                // Use a scroll gesture and verify the sheet and exact selection.
                if element.exists && frame.midY < (top + bottom) / 2 { scroll.swipeDown(velocity: .slow) }
                else { scroll.swipeUp(velocity: .slow) }
            }
            throw NSError(domain: "PracticeUIVisibility", code: 2, userInfo: [NSLocalizedDescriptionKey: "Course row not visible: \(element.identifier)"])
        }
        let picker = app.navigationBars["選擇夥伴"]
        let inPicker = picker.exists
        let top = inPicker ? picker.frame.maxY : app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY : app.statusBars.firstMatch.frame.maxY
        // A presented sheet covers the underlying tab bar; use its own viewport.
        // The SE has no bottom home-indicator inset. Do not invent a 30pt
        // exclusion zone: use the observed tab bar or actual app viewport.
        let bottom = !inPicker && app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame.minY : window.frame.maxY
        // At XXXL, selecting a companion leaves the first lesson more than
        // eight capped drags away. Recheck after reaching it instead of failing
        // immediately after the last gesture made the frame fully visible.
        for _ in 0..<24 {
            guard element.exists else { throw NSError(domain: "PracticeUIVisibility", code: 3, userInfo: [NSLocalizedDescriptionKey: "Control disappeared before scrolling: \(element.identifier)"]) }
            let frame = element.exists ? element.frame : .zero
            // Offscreen UIKit accessibility pads can throw when asked for an
            // activation point. Observe the viewport before querying the hit
            // point; retain both conditions once the control is on screen.
            if element.exists && frame.minY >= top && frame.maxY <= bottom && (!requiresHit || element.isHittable) { return }
            // Use the observed primary window and explicit center pixels.
            // The application accessibility root may have no geometry.
            let origin = window.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: window.frame.width / 2, dy: 0))
            let middle = (top + bottom) / 2
            // Center the observed element with a slow, held drag. A fixed fling
            // can jump over the fully visible range of a tall Dynamic Type row.
            let shift = element.exists ? min(220, max(-220, middle - frame.midY)) : -180
            origin.withOffset(CGVector(dx: 0, dy: middle - shift / 2)).press(forDuration: 0.05,
                thenDragTo: origin.withOffset(CGVector(dx: 0, dy: middle + shift / 2)),
                withVelocity: .slow, thenHoldForDuration: 0.15)
        }
        capture(app, "Visibility failure \(element.identifier)")
        print("GAME13_VISIBILITY_FAILURE \(element.debugDescription)")
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
        XCTAssertTrue(app.staticTexts["把恐龍蛋帶回家"].exists)
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        XCTAssertTrue(app.staticTexts["practiceSummary"].waitForExistence(timeout: 30))
        XCTAssertEqual(app.staticTexts["practiceSummary"].label, "蛋接住了，再試一次！")
        XCTAssertEqual(app.otherElements["practiceStars"].label, "這次得到 0 顆星")
        XCTAssertFalse(app.buttons["nextLesson"].exists)
        XCTAssertTrue(app.staticTexts["漏拍 16 下 · 多打 0 下"].exists)
        capture(app, "Native actual no-input result")
        try reveal(app.buttons["retryLesson"], in: app); app.buttons["retryLesson"].tap()
        let counter = app.staticTexts["jumpMatches"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5)); XCTAssertEqual(counter.label, "抵達 0 / 16 座小島")
        app.buttons["stopPractice"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        // Reopen the preparation; failed/retried/cancelled runs keep next locked.
        let first = app.buttons["journeyLesson.first-beat"]
        try reveal(first, in: app); first.tap()
        try reveal(app.buttons["backToJourney"], in: app); app.buttons["backToJourney"].tap()
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
        let appFrame = app.windows.firstMatch.frame
        let navigationBottom = app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY : app.statusBars.firstMatch.frame.maxY
        let viewport = CGRect(x: 0, y: navigationBottom, width: appFrame.width, height: appFrame.maxY - navigationBottom)
        let cueFrame = cue.frame, padFrame = pad.frame, stopFrame = stop.frame
        for (name, frame) in [("cue", cueFrame), ("pad", padFrame), ("stop", stopFrame)] {
            XCTAssertGreaterThan(frame.height, 0)
            XCTAssertTrue(viewport.contains(frame), "Clipped \(name): \(frame)")
        }
        // SwiftUI can expose both a container and inherited child IDs. Measure
        // the union of all lane frames rather than silently picking a child.
        let laneElements = app.descendants(matching: .any).matching(identifier: "rhythmLane").allElementsBoundByIndex
        XCTAssertFalse(laneElements.isEmpty)
        let laneFrame = laneElements.reduce(CGRect.null) { $0.union($1.frame) }
        XCTAssertTrue(viewport.contains(laneFrame), "Clipped rhythm lane: \(laneFrame)")
        XCTAssertLessThanOrEqual(laneFrame.maxY, padFrame.minY, "Rhythm cannot be hidden beneath jump pad")
        XCTAssertLessThanOrEqual(padFrame.maxY, stopFrame.minY)
        capture(app, "Runner complete viewport")
        // Keep a viewport test inside the real twenty-second lesson. Actual
        // matched touch/restart is a separate runtime test; duplicate/extra is
        // covered through the real matcher and browser clock-cued inputs.
        stop.tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label, "0 / 10 關完成")
    }

    @MainActor
    func testRunnerLargeTextCanReachSceneRhythmJumpAndStop() async throws {
        // Independent actual runs: fixed footer must be reachable immediately.
        // Avoid generic preparation scroll queries consuming the live20s course.
        for region in ["stop", "jump", "scene", "rhythm"] {
            let app = freshApp(largestText: true)
            app.buttons["dailyPractice"].tap()
            try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
            if region == "stop" {
                let stop = app.buttons["stopPractice"]
                XCTAssertTrue(stop.waitForExistence(timeout: 5)); stop.tap()
                XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
            } else if region == "jump" {
                let pad = app.buttons["practiceTapPad"]
                XCTAssertTrue(pad.waitForExistence(timeout: 5)); XCTAssertTrue(pad.isHittable)
                pad.tap(); capture(app, "Cross-island large-text jump footer")
            } else {
                let control = app.otherElements[region == "scene" ? "eggMissionScene" : "rhythmLane"].firstMatch
                XCTAssertTrue(control.waitForExistence(timeout: 5))
                let scroll = app.scrollViews.firstMatch
                for _ in 0..<2 where !scroll.frame.contains(control.frame) { scroll.swipeUp(velocity: .slow) }
                XCTAssertTrue(scroll.frame.contains(control.frame), "Entire region must be scrollable above fixed controls")
                capture(app, "Cross-island large-text \(region)")
            }
            app.terminate()
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
            if counter.exists && !counter.label.hasPrefix("抵達 0 ") { break }
            pad.tap()
        }
        XCTAssertTrue(counter.exists)
        XCTAssertFalse(counter.label.hasPrefix("抵達 0 "), "Actual matched touches must clear an obstacle")
        capture(app, "Runner actual matched touch clearance")
        app.buttons["stopPractice"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout: 5))
        let first = app.buttons["journeyLesson.first-beat"]
        try reveal(first, in: app); first.tap()
        try reveal(app.buttons["startLesson"], in: app); app.buttons["startLesson"].tap()
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        XCTAssertEqual(counter.label, "抵達 0 / 16 座小島")
        app.buttons["stopPractice"].tap()
    }

}
