import XCTest
import BeatLabDSP

final class DSPTests: XCTestCase {
    private func withDSP(_ body: (OpaquePointer) throws -> Void) throws {
        let dsp = try XCTUnwrap(BLDSPCreate(48000, BLSettings(bpm: 120, meter: 2, subdivision: 0, accent: 1)))
        defer { BLDSPDestroy(dsp) }
        try body(dsp)
    }

    private func render(_ dsp: OpaquePointer, _ count: Int) -> [Float] {
        var output = [Float](repeating: 0, count: count)
        output.withUnsafeMutableBufferPointer { buffer in
            BLDSPRender(dsp, buffer.baseAddress!, UInt32(count), 12345)
        }
        return output
    }

    func testClickOnsetsAreAtExactTargetSamples() throws {
        try withDSP { dsp in
            let output = render(dsp, 48001)
            XCTAssertNotEqual(output[0], 0)
            XCTAssertEqual(output[23999], 0)
            XCTAssertNotEqual(output[24000], 0)
            XCTAssertNotEqual(output[48000], 0)
        }
    }

    func testBPMAndSubdivisionWaitForNextBeat() throws {
        try withDSP { dsp in
            _ = render(dsp, 1000)
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 60, meter: 2, subdivision: 1, accent: 1)))
            _ = render(dsp, 23001)
            var beat = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(dsp, 24000, &beat))
            XCTAssertEqual(beat.startFrame, 24000)
            XCTAssertEqual(beat.endFrame, 72000)
            XCTAssertEqual(beat.settings.bpm, 60)
            XCTAssertEqual(beat.settings.subdivision, 1)
        }
    }

    func testMeterAndAccentWaitForBarWhileTempoCanChangeAtBeat() throws {
        try withDSP { dsp in
            _ = render(dsp, 1)
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 120, meter: 3, subdivision: 4, accent: 0)))
            _ = render(dsp, 24000)
            var beat = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(dsp, 24000, &beat))
            XCTAssertEqual(beat.settings.meter, 2)
            XCTAssertEqual(beat.settings.subdivision, 0)
            XCTAssertEqual(beat.settings.accent, 1)
            _ = render(dsp, 72000)
            XCTAssertTrue(BLDSPReadBeat(dsp, 96000, &beat))
            XCTAssertEqual(beat.settings.meter, 3)
            XCTAssertEqual(beat.settings.subdivision, 4)
            XCTAssertEqual(beat.settings.accent, 0)
            XCTAssertEqual(beat.beatInBar, 0)
        }
    }

    func testRapidRequestsUseLatestStateAndInvalidRequestIsRejected() throws {
        try withDSP { dsp in
            _ = render(dsp, 1)
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 60, meter: 2, subdivision: 0, accent: 1)))
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 180, meter: 2, subdivision: 3, accent: 1)))
            XCTAssertFalse(BLDSPRequest(dsp, BLSettings(bpm: 241, meter: 2, subdivision: 0, accent: 1)))
            _ = render(dsp, 24000)
            var beat = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(dsp, 24000, &beat))
            XCTAssertEqual(beat.settings.bpm, 180)
            XCTAssertEqual(beat.settings.subdivision, 3)
            XCTAssertEqual(beat.endFrame, 40000)
        }
    }

    func testZeroGainKeepsClockAndBeatAdvancing() throws {
        try withDSP { dsp in
            BLDSPSetGain(dsp, 0)
            XCTAssertTrue(render(dsp, 48001).allSatisfy { $0 == 0 })
            var beat = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(dsp, 48000, &beat))
            XCTAssertEqual(beat.beatNumber, 2)
            var clock = BLClock()
            XCTAssertTrue(BLDSPReadClock(dsp, &clock))
            XCTAssertEqual(clock.hostTime, 12345)
            XCTAssertEqual(clock.frameCount, 48001)
        }
    }

    func testInvalidSampleRateAndCompoundCombinationCannotCreateKernel() {
        XCTAssertNil(BLDSPCreate(0, BLSettings(bpm: 120, meter: 2, subdivision: 0, accent: 1)))
        XCTAssertNil(BLDSPCreate(48000, BLSettings(bpm: 120, meter: 3, subdivision: 0, accent: 1)))
    }
}
