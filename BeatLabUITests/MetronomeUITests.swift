import XCTest

final class MetronomeUITests: XCTestCase {
    @MainActor
    func testBeatCycleSoundCuesAndTempoUndoRedo() async {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BEATLAB_UI_TEST_SUITE"] = "BeatLabUITests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-test-settings"]
        app.launch()
        app.tabBars.buttons["節拍器"].tap()
        capture(app, named: "Tempo controls")
        reveal(app.buttons["tempoPlusFive"], in: app)
        app.buttons["tempoPlusFive"].tap()
        reveal(app.buttons["undoTempo"], in: app, scrollDirection: -1)
        app.buttons["undoTempo"].tap()
        XCTAssertTrue(app.staticTexts["tempoValue"].label.contains("80 BPM"))
        app.buttons["redoTempo"].tap()
        XCTAssertTrue(app.staticTexts["tempoValue"].label.contains("85 BPM"))
        let beat = app.buttons["beatControl.0"]
        reveal(beat, in: app)
        XCTAssertEqual(beat.value as? String, "重音")
        capture(app, named: "Editable beats and pendulum")
        beat.tap(); XCTAssertEqual(beat.value as? String, "一般")
        beat.tap(); XCTAssertEqual(beat.value as? String, "靜音")
        beat.tap(); XCTAssertEqual(beat.value as? String, "重音")
        let timbre = app.segmentedControls["clickTimbrePicker"]
        reveal(timbre, in: app)
        timbre.buttons["木魚聲"].tap()
        let pulse = app.switches["screenPulseToggle"]
        reveal(pulse, in: app)
        pulse.tap()
        capture(app, named: "Timbre and visual haptic controls")
        app.terminate(); app.launchArguments = []; app.launch()
        app.tabBars.buttons["節拍器"].tap()
        reveal(timbre, in: app)
        XCTAssertTrue(timbre.buttons["木魚聲"].isSelected)
        reveal(pulse, in: app)
        XCTAssertEqual(pulse.value as? String, "1")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, scrollDirection: CGFloat = 1) {
        // A control behind the fixed transport can report isHittable. Require
        // its complete frame to be in the scrolling area before tapping.
        let top = app.navigationBars.firstMatch.frame.maxY
        let bottom = app.buttons["transportButton"].frame.minY
        for _ in 0..<15 {
            let exists = element.exists
            let frame = exists ? element.frame : .zero
            print("Reveal frame \(frame), viewport \(top)...\(bottom), exists \(exists)")
            if exists && element.isHittable && frame.minY >= top && frame.maxY <= bottom { return }
            let middle = (top + bottom) / 2
            let direction: CGFloat = exists ? (frame.minY < top ? -1 : 1) : scrollDirection
            let origin = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            let start = origin.withOffset(CGVector(dx: 0, dy: middle + direction * 90))
            let end = origin.withOffset(CGVector(dx: 0, dy: middle - direction * 90))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Control did not become fully visible above the transport: \(element)")
    }

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
