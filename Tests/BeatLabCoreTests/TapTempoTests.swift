import XCTest
@testable import BeatLabCore

final class TapTempoTests: XCTestCase {
    func testRequiresThreeTapsAndEstimates120BPM() {
        var tap = TapTempo()
        XCTAssertNil(tap.tap(at: 10))
        XCTAssertNil(tap.tap(at: 10.5))
        XCTAssertEqual(tap.tap(at: 11)?.bpm, 120)
    }

    func testAccepts30And240BPMBoundaries() {
        var tap = TapTempo()
        _ = tap.tap(at: 0); _ = tap.tap(at: 2)
        XCTAssertEqual(tap.tap(at: 4)?.bpm, 30)
        tap.reset()
        _ = tap.tap(at: 0); _ = tap.tap(at: 0.25)
        XCTAssertEqual(tap.tap(at: 0.5)?.bpm, 240)
    }

    func testDoubleTapDoesNotShiftIntendedReference() {
        var tap = TapTempo()
        _ = tap.tap(at: 0)
        XCTAssertNil(tap.tap(at: 0.1))
        _ = tap.tap(at: 0.5)
        XCTAssertEqual(tap.tap(at: 1)?.bpm, 120)
    }

    func testLongPauseAndExplicitResetStartNewSeries() {
        var tap = TapTempo()
        _ = tap.tap(at: 0); _ = tap.tap(at: 0.5); _ = tap.tap(at: 1)
        XCTAssertNil(tap.tap(at: 5))
        XCTAssertNil(tap.tap(at: 5.5))
        XCTAssertEqual(tap.tap(at: 6)?.bpm, 120)
        tap.reset()
        XCTAssertNil(tap.tap(at: 7))
    }

    func testInvalidOrReversedTimestampsResetSafely() {
        var tap = TapTempo()
        for time in [Double.nan, .infinity, -1] { XCTAssertNil(tap.tap(at: time)) }
        _ = tap.tap(at: 10)
        XCTAssertNil(tap.tap(at: 9))
        XCTAssertNil(tap.tap(at: 9.5))
        XCTAssertEqual(tap.tap(at: 10)?.bpm, 120)
    }

    func testDeliberateTempoChangeDoesNotBlendOldIntervals() {
        var tap = TapTempo()
        _ = tap.tap(at: 0); _ = tap.tap(at: 0.5); _ = tap.tap(at: 1)
        XCTAssertNil(tap.tap(at: 2))
        XCTAssertEqual(tap.tap(at: 3)?.bpm, 60)
    }
}
