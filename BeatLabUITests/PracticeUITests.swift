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
        // Observe the actual count-in ending; a fast AX pass must not send the
        // entire gesture before the transport accepts practice input.
        let cue = app.staticTexts["jumpCue"]
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "NOT label BEGINSWITH %@", "先聽"), object: cue)
        guard XCTWaiter.wait(for: [ready], timeout: 8) == .completed else {
            XCTFail("Actual companion count-in did not end")
            return
        }
        pad.tap(withNumberOfTaps: 10, numberOfTouches: 1)
        XCTAssertFalse(app.staticTexts["jumpMatches"].label.hasPrefix("抵達 0 "), "Actual UIKit touches must produce a real accepted hit")
        assertEssentialGameRows(in: app)
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
    private func assertEssentialGameRows(in app: XCUIApplication) {
        let window = app.windows.firstMatch.frame
        let heading = app.staticTexts["activeLessonNumber"].frame
        let count = app.staticTexts["jumpMatches"].frame
        // Independent normal-text legibility bounds, not copied layout values.
        XCTAssertGreaterThanOrEqual(heading.height, 16)
        XCTAssertGreaterThanOrEqual(count.height, 10)
        XCTAssertGreaterThanOrEqual(heading.minY, window.minY)
        XCTAssertLessThanOrEqual(count.maxY, app.buttons["practiceTapPad"].frame.minY)
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
            XCTAssertTrue(app.buttons[[1,3,5,7,8,9].contains(index) ? "practiceTapPad.right" : "practiceTapPad"].waitForExistence(timeout: 5))
            let heading = index == 0 ? "第 1 關 · 節奏跨島" : index == 1 ? "第 2 關 · 左右接力跨島" : index == 2 ? "第 3 關 · 半拍小島" : index == 3 ? "第 4 關 · 半拍左右接力" : index == 4 ? "第 5 關 · 留白小島" : index == 5 ? "第 6 關 · 半拍與休息" : index == 6 ? "第 7 關 · 一拍四格" : index == 7 ? "第 8 關 · 四格左右接力" : index == 8 ? "第 9 關 · 反拍跨島" : "第 10 關 · 節奏小高手"
            XCTAssertEqual(app.staticTexts["activeLessonNumber"].label, heading)
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
    private func assertWholeGameVisible(_ app: XCUIApplication, dual: Bool) {
        let scene=app.otherElements["eggMissionScene"].firstMatch
        let pad=app.buttons[dual ? "practiceTapPad.right" : "practiceTapPad"],stop=app.buttons["stopPractice"]
        XCTAssertTrue(pad.waitForExistence(timeout:5));XCTAssertTrue(scene.exists)
        let window=app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(scene.frame.height,200)
        let top=app.statusBars.firstMatch.exists ? app.statusBars.firstMatch.frame.maxY : window.minY
        XCTAssertGreaterThanOrEqual(scene.frame.minY,top)
        XCTAssertLessThanOrEqual(scene.frame.maxY,pad.frame.minY)
        XCTAssertLessThanOrEqual(stop.frame.maxY,window.maxY)
        XCTAssertGreaterThanOrEqual(pad.frame.height,44);XCTAssertGreaterThanOrEqual(stop.frame.height,44)
        XCTAssertTrue(pad.isHittable);XCTAssertTrue(stop.isHittable)
        if dual {
            let left=app.buttons["practiceTapPad.left"]
            XCTAssertTrue(left.isHittable);XCTAssertGreaterThanOrEqual(left.frame.height,44)
            XCTAssertLessThanOrEqual(pad.frame.maxX,left.frame.minX)
        }
    }
    @MainActor
    func testFirstLargestTextShowsWholeGameSceneAndReachableControls() throws {
        let app=freshApp(largestText:true)
        try reveal(app.buttons["dailyPractice"],in:app);app.buttons["dailyPractice"].tap()
        try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
        assertWholeGameVisible(app,dual:false)
        XCTAssertEqual(app.staticTexts["activeLessonNumber"].label,"第 1 關 · 節奏跨島")
        let initialHeight=app.otherElements["eggMissionScene"].firstMatch.frame.height
        capture(app,"GAME28 largest first full scene and controls")
        let ready=XCTNSPredicateExpectation(predicate:NSPredicate(format:"NOT label BEGINSWITH %@","先聽"),object:app.staticTexts["jumpCue"])
        XCTAssertEqual(XCTWaiter.wait(for:[ready],timeout:8),.completed)
        XCTAssertEqual(app.otherElements["eggMissionScene"].firstMatch.frame.height,initialHeight,accuracy:0.1,"Feedback must not resize the game stage")
        assertWholeGameVisible(app,dual:false);capture(app,"GAME28 largest first active stable stage")
        app.buttons["stopPractice"].tap()
    }
    @MainActor
    func testFourthLargestTextWholeSceneZeroResultStarsClearTabAndRetry() throws {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["BEATLAB_UI_TEST_SUITE"]="BeatLabUITests.LayoutFourth"
        app.launchArguments=["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch();XCTAssertTrue(app.staticTexts["3 / 10 關"].waitForExistence(timeout:5))
        try reveal(app.buttons["dailyPractice"],in:app);app.buttons["dailyPractice"].tap()
        XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout:5))
        XCTAssertTrue(app.staticTexts["preparedLessonNumber"].label.hasPrefix("第 4 關"))
        try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
        assertWholeGameVisible(app,dual:true)
        XCTAssertEqual(app.staticTexts["activeLessonNumber"].label,"第 4 關 · 半拍左右接力")
        capture(app,"GAME28 largest fourth full scene and controls")
        XCTAssertTrue(app.staticTexts["practiceSummary"].waitForExistence(timeout:25))
        let stars=app.otherElements["practiceStars"]
        XCTAssertEqual(stars.label,"這次得到 0 顆星");XCTAssertFalse(app.buttons["nextLesson"].exists)
        try reveal(stars,in:app,requiresHit:false)
        XCTAssertLessThanOrEqual(stars.frame.maxY,app.tabBars.firstMatch.frame.minY)
        capture(app,"GAME28 largest zero result stars clear tab")
        try reveal(app.buttons["retryLesson"],in:app);app.buttons["retryLesson"].tap()
        assertWholeGameVisible(app,dual:true)
        XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / 32 座小島")
        app.buttons["stopPractice"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label,"3 / 10 關完成")
        try reveal(app.buttons["journeyChapter.1"],in:app);app.buttons["journeyChapter.1"].tap()
        try reveal(app.buttons["journeyLesson.quarter-rest"],in:app,requiresHit:false)
        XCTAssertFalse(app.buttons["journeyLesson.quarter-rest"].isEnabled)
    }

    @MainActor
    func testHighDensityActualTouchesCancelAnd64Or40NoteRestart() throws {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["BEATLAB_UI_TEST_SUITE"]="BeatLabUITests.HighLevels"
        app.launch();XCTAssertTrue(app.staticTexts["9 / 10 關"].waitForExistence(timeout:5))
        app.tabBars.buttons["練習"].tap()
        for (level,id,total) in [(7,"sixteenth",64),(8,"sixteenth-hands",64),(10,"mixed",40)] {
            try reveal(app.buttons["journeyChapter.2"],in:app);app.buttons["journeyChapter.2"].tap()
            try reveal(app.buttons["journeyLesson.\(id)"],in:app);app.buttons["journeyLesson.\(id)"].tap()
            XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["preparedLessonNumber"].label.hasPrefix("第 \(level) 關"))
            capture(app,"GAME30 level\(level) grouped preparation")
            try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
            assertWholeGameVisible(app,dual:level != 7)
            let lane=app.otherElements["rhythmLane"].firstMatch,window=app.windows.firstMatch.frame
            XCTAssertGreaterThanOrEqual(lane.frame.minX,window.minX);XCTAssertLessThanOrEqual(lane.frame.maxX,window.maxX)
            XCTAssertEqual(lane.label,"每拍四格的四個拍點")
            XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / \(total) 座小島")
            let ready=XCTNSPredicateExpectation(predicate:NSPredicate(format:"NOT label BEGINSWITH %@","先聽"),object:app.staticTexts["jumpCue"])
            XCTAssertEqual(XCTWaiter.wait(for:[ready],timeout:8),.completed)
            let pad=app.buttons[level == 7 ? "practiceTapPad" : "practiceTapPad.right"],height=app.otherElements["eggMissionScene"].firstMatch.frame.height
            if level == 7{pad.tap(withNumberOfTaps:10,numberOfTouches:1)}else{pad.tap(withNumberOfTaps:5,numberOfTouches:1);app.buttons["practiceTapPad.left"].tap(withNumberOfTaps:5,numberOfTouches:1)}
            XCTAssertFalse(app.staticTexts["jumpMatches"].label.hasPrefix("抵達 0 "))
            XCTAssertEqual(app.otherElements["eggMissionScene"].firstMatch.frame.height,height,accuracy:0.1)
            capture(app,"GAME30 level\(level) actual touches")
            app.buttons["stopPractice"].tap();XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["journeyProgress"].label,"9 / 10 關完成")
            try reveal(app.buttons["journeyLesson.\(id)"],in:app);app.buttons["journeyLesson.\(id)"].tap()
            try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
            XCTAssertTrue(pad.waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / \(total) 座小島")
            app.buttons["stopPractice"].tap()
        }
    }
    @MainActor
    func testMixedLargestTextZeroResultAndFortyNoteRetry() throws {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["BEATLAB_UI_TEST_SUITE"]="BeatLabUITests.HighLargest"
        app.launchArguments=["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch();XCTAssertTrue(app.staticTexts["9 / 10 關"].waitForExistence(timeout:5))
        try reveal(app.buttons["dailyPractice"],in:app);app.buttons["dailyPractice"].tap()
        try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
        assertWholeGameVisible(app,dual:true)
        let lane=app.otherElements["rhythmLane"].firstMatch,window=app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(lane.frame.minX,window.minX);XCTAssertLessThanOrEqual(lane.frame.maxX,window.maxX)
        XCTAssertEqual(lane.label,"每拍四格的四個拍點");XCTAssertEqual(app.staticTexts["activeLessonNumber"].label,"第 10 關 · 節奏小高手")
        capture(app,"GAME30 largest mixed full scene and four groups")
        XCTAssertTrue(app.staticTexts["practiceSummary"].waitForExistence(timeout:25))
        XCTAssertEqual(app.otherElements["practiceStars"].label,"這次得到 0 顆星");XCTAssertFalse(app.buttons["nextLesson"].exists)
        XCTAssertEqual(app.otherElements["eggMissionScene"].value as? String,"需要再試一次，抵達 0/40 座小島")
        try reveal(app.otherElements["practiceStars"],in:app,requiresHit:false)
        XCTAssertLessThanOrEqual(app.otherElements["practiceStars"].frame.maxY,app.tabBars.firstMatch.frame.minY)
        capture(app,"GAME30 largest mixed zero result")
        try reveal(app.buttons["retryLesson"],in:app);app.buttons["retryLesson"].tap()
        assertWholeGameVisible(app,dual:true);XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / 40 座小島")
        app.buttons["stopPractice"].tap();XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["journeyProgress"].label,"9 / 10 關完成")
    }

    @MainActor
    func testRestLessonsActualGridWaitTouchesCancelAndEmptyRestart() throws {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["BEATLAB_UI_TEST_SUITE"]="BeatLabUITests.RestLevels"
        app.launch();XCTAssertTrue(app.staticTexts["8 / 10 關"].waitForExistence(timeout:5))
        app.tabBars.buttons["練習"].tap()
        for (level,id,total,chapter) in [(5,"quarter-rest",8,1),(6,"eighth-rest",20,1),(9,"offbeat",16,2)] {
            try reveal(app.buttons["journeyChapter.\(chapter)"],in:app);app.buttons["journeyChapter.\(chapter)"].tap()
            try reveal(app.buttons["journeyLesson.\(id)"],in:app);app.buttons["journeyLesson.\(id)"].tap()
            XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout:5))
            XCTAssertTrue(app.staticTexts["preparedLessonNumber"].label.hasPrefix("第 \(level) 關"));capture(app,"GAME29 level\(level) preparation")
            try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
            assertWholeGameVisible(app,dual:level != 5)
            let pad=app.buttons[level == 5 ? "practiceTapPad" : "practiceTapPad.right"]
            XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / \(total) 座小島")
            let resting=XCTNSPredicateExpectation(predicate:NSPredicate(format:"value CONTAINS %@","休息"),object:app.otherElements["rhythmLane"])
            XCTAssertEqual(XCTWaiter.wait(for:[resting],timeout:10),.completed,"Observe actual musical rest, no injected clock")
            capture(app,"GAME29 level\(level) actual rest cell")
            pad.tap(withNumberOfTaps:10,numberOfTouches:1)
            XCTAssertFalse(app.staticTexts["jumpMatches"].label.hasPrefix("抵達 0 "),"Actual post-count-in touches must match at least one authored note")
            capture(app,"GAME29 level\(level) actual touch")
            app.buttons["stopPractice"].tap()
            XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["journeyProgress"].label,"8 / 10 關完成")
            try reveal(app.buttons["journeyLesson.\(id)"],in:app);app.buttons["journeyLesson.\(id)"].tap()
            try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
            XCTAssertTrue(pad.waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / \(total) 座小島")
            app.buttons["stopPractice"].tap()
        }
        try reveal(app.buttons["journeyLesson.mixed"],in:app,requiresHit:false);XCTAssertFalse(app.buttons["journeyLesson.mixed"].isEnabled)
    }
    @MainActor
    func testOffbeatActualZeroResultDoesNotUnlockAndRetryKeeps16Notes() throws {
        continueAfterFailure=false
        let app=XCUIApplication();app.launchEnvironment["BEATLAB_UI_TEST_SUITE"]="BeatLabUITests.RestZero"
        app.launch();XCTAssertTrue(app.staticTexts["8 / 10 關"].waitForExistence(timeout:5))
        try reveal(app.buttons["dailyPractice"],in:app);app.buttons["dailyPractice"].tap()
        XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["preparedLessonNumber"].label.hasPrefix("第 9 關"))
        try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
        XCTAssertTrue(app.staticTexts["practiceSummary"].waitForExistence(timeout:25))
        XCTAssertEqual(app.otherElements["practiceStars"].label,"這次得到 0 顆星");XCTAssertFalse(app.buttons["nextLesson"].exists)
        capture(app,"GAME29 ninth zero result")
        try reveal(app.buttons["retryLesson"],in:app);app.buttons["retryLesson"].tap()
        assertWholeGameVisible(app,dual:true);XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / 16 座小島")
        app.buttons["stopPractice"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["journeyProgress"].label,"8 / 10 關完成")
    }

    @MainActor
    func testDenseLevelsActualTouchesCancelAnd32IslandRestart() throws {
        continueAfterFailure = false
        let app=XCUIApplication()
        // External reviewed prior-level fixture only. No injected hits/routes.
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"]="BeatLabUITests.DenseLevels"
        app.launch()
        XCTAssertTrue(app.staticTexts["3 / 10 關"].waitForExistence(timeout:5))
        app.tabBars.buttons["練習"].tap()
        for (level,id) in [(3,"eighth"),(4,"eighth-hands")] {
            try reveal(app.buttons["journeyChapter.1"],in:app);app.buttons["journeyChapter.1"].tap()
            try reveal(app.buttons["journeyLesson.\(id)"],in:app);app.buttons["journeyLesson.\(id)"].tap()
            XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout:5))
            XCTAssertTrue(app.staticTexts["preparedLessonNumber"].label.hasPrefix("第 \(level) 關"))
            capture(app,"GAME27 level\(level) preparation")
            try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
            let pad=app.buttons[level == 3 ? "practiceTapPad" : "practiceTapPad.right"]
            XCTAssertTrue(pad.waitForExistence(timeout:5));XCTAssertGreaterThanOrEqual(pad.frame.height,44)
            if level == 4 {XCTAssertTrue(app.buttons["practiceTapPad.left"].isHittable)}
            XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / 32 座小島")
            XCTAssertTrue(app.staticTexts["activeLessonNumber"].label.hasPrefix("第 \(level) 關"))
            let stageHeight=app.otherElements["eggMissionScene"].firstMatch.frame.height
            // Observe the real four-beat count-in; input before it must be ignored.
            let ready=XCTNSPredicateExpectation(predicate:NSPredicate(format:"NOT label BEGINSWITH %@","先聽"),object:app.staticTexts["jumpCue"])
            XCTAssertEqual(XCTWaiter.wait(for:[ready],timeout:8),.completed)
            if level == 4 {
                pad.tap(withNumberOfTaps:5,numberOfTouches:1)
                app.buttons["practiceTapPad.left"].tap(withNumberOfTaps:5,numberOfTouches:1)
            } else {pad.tap(withNumberOfTaps:10,numberOfTouches:1)}
            XCTAssertFalse(app.staticTexts["jumpMatches"].label.hasPrefix("抵達 0 "),"Actual UIKit input after count-in must match dense targets")
            XCTAssertEqual(app.otherElements["eggMissionScene"].firstMatch.frame.height,stageHeight,accuracy:0.1,"Accepted/extra feedback cannot resize the stage")
            capture(app,"GAME27 level\(level) live touches")
            app.buttons["stopPractice"].tap()
            XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5))
            XCTAssertEqual(app.staticTexts["journeyProgress"].label,"3 / 10 關完成")
            try reveal(app.buttons["journeyLesson.quarter-rest"],in:app,requiresHit:false)
            XCTAssertFalse(app.buttons["journeyLesson.quarter-rest"].isEnabled)
            try reveal(app.buttons["journeyLesson.\(id)"],in:app);app.buttons["journeyLesson.\(id)"].tap()
            try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
            XCTAssertTrue(pad.waitForExistence(timeout:5))
            XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / 32 座小島")
            app.buttons["stopPractice"].tap()
        }
    }

    @MainActor
    private func secondLevelApp(largestText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        // External fixture saves ONLY a reviewed first-level result in this
        // isolated suite. Production unlock/start code still runs unchanged.
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.SecondLevel"
        if largestText {
            app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.staticTexts["1 / 10 關"].waitForExistence(timeout:5),"Requires explicit saved-first fixture")
        return app
    }
    @MainActor
    func testSecondLevelActualDualTouchesCancelAndRestart() throws {
        let app = secondLevelApp()
        app.buttons["dailyPractice"].tap()
        XCTAssertTrue(app.staticTexts["preparedLessonNumber"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["preparedLessonNumber"].label,"第 2 關 · 左右輪流")
        capture(app,"GAME26 second preparation")
        try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
        let right=app.buttons["practiceTapPad.right"],left=app.buttons["practiceTapPad.left"]
        XCTAssertTrue(right.waitForExistence(timeout:5));XCTAssertTrue(left.isHittable)
        XCTAssertEqual(app.staticTexts["activeLessonNumber"].label,"第 2 關 · 左右接力跨島")
        XCTAssertTrue(app.staticTexts["65 BPM"].exists)
        XCTAssertGreaterThanOrEqual(right.frame.height,44);XCTAssertGreaterThanOrEqual(left.frame.height,44)
        XCTAssertLessThanOrEqual(right.frame.maxX,left.frame.minX)
        let counter=app.staticTexts["jumpMatches"]
        for i in 0..<12 {
            (i%2==0 ? right : left).tap()
            if i>2 && !counter.label.hasPrefix("抵達 0 ") {break}
        }
        XCTAssertFalse(counter.label.hasPrefix("抵達 0 "),"Actual UIKit dual-pad touches must be matched")
        capture(app,"GAME26 actual dual-pad live game")
        app.buttons["stopPractice"].tap()
        XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["journeyProgress"].label,"1 / 10 關完成")
        try reveal(app.buttons["journeyChapter.1"],in:app);app.buttons["journeyChapter.1"].tap()
        try reveal(app.buttons["journeyLesson.eighth"],in:app,requiresHit:false)
        XCTAssertFalse(app.buttons["journeyLesson.eighth"].isEnabled)
        try reveal(app.buttons["journeyChapter.0"],in:app);app.buttons["journeyChapter.0"].tap()
        try reveal(app.buttons["journeyLesson.quarter-hands"],in:app);app.buttons["journeyLesson.quarter-hands"].tap()
        try reveal(app.buttons["startLesson"],in:app);app.buttons["startLesson"].tap()
        XCTAssertTrue(counter.waitForExistence(timeout:5));XCTAssertEqual(counter.label,"抵達 0 / 16 座小島")
        app.buttons["stopPractice"].tap()
    }
    @MainActor
    func testSecondLevelLargestTextZeroInputFailureKeepsThirdLocked() throws {
        let app = secondLevelApp(largestText:true)
        app.buttons["dailyPractice"].tap()
        try reveal(app.buttons["startLesson"],in:app);capture(app,"GAME26 largest preparation")
        app.buttons["startLesson"].tap()
        let right=app.buttons["practiceTapPad.right"],left=app.buttons["practiceTapPad.left"],stop=app.buttons["stopPractice"]
        XCTAssertTrue(right.waitForExistence(timeout:5));XCTAssertTrue(left.isHittable);XCTAssertTrue(stop.isHittable)
        XCTAssertGreaterThanOrEqual(right.frame.height,44);XCTAssertGreaterThanOrEqual(left.frame.height,44)
        XCTAssertLessThanOrEqual(right.frame.maxY,stop.frame.minY)
        capture(app,"GAME26 largest dual-pad controls")
        XCTAssertTrue(app.staticTexts["practiceSummary"].waitForExistence(timeout:25))
        XCTAssertEqual(app.otherElements["practiceStars"].label,"這次得到 0 顆星")
        XCTAssertFalse(app.buttons["nextLesson"].exists);capture(app,"GAME26 actual zero-input failure")
        try reveal(app.buttons["retryLesson"],in:app);app.buttons["retryLesson"].tap()
        XCTAssertTrue(right.waitForExistence(timeout:5));XCTAssertTrue(left.exists)
        XCTAssertEqual(app.staticTexts["jumpMatches"].label,"抵達 0 / 16 座小島")
        stop.tap();XCTAssertTrue(app.staticTexts["journeyProgress"].waitForExistence(timeout:5))
        try reveal(app.buttons["journeyChapter.1"],in:app);app.buttons["journeyChapter.1"].tap()
        try reveal(app.buttons["journeyLesson.eighth"],in:app,requiresHit:false)
        XCTAssertFalse(app.buttons["journeyLesson.eighth"].isEnabled)
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
        let top = inPicker ? picker.frame.maxY : app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY : app.statusBars.firstMatch.exists ? app.statusBars.firstMatch.frame.maxY : window.frame.minY
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
        try reveal(app.buttons["journeyChapter.1"],in:app);app.buttons["journeyChapter.1"].tap()
        try reveal(app.buttons["journeyLesson.eighth"],in:app,requiresHit:false)
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
        assertEssentialGameRows(in: app)
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
