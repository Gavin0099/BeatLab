import XCTest
import BeatLabDSP

final class DSPTests: XCTestCase {
    func testFinitePracticeBedStartsOnExistingCursorAndDoesNotChangeBeatHistory() throws {
        let settings = BLSettings(bpm: 60, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)
        let plain = try XCTUnwrap(BLDSPCreate(8000, settings)), bed = try XCTUnwrap(BLDSPCreate(8000, settings))
        defer { BLDSPDestroy(plain); BLDSPDestroy(bed) }
        BLDSPSetGain(plain, 1); BLDSPSetGain(bed, 1)
        let fixture: [Float] = [0.1, -0.1, 0.2, 0]
        // Four seconds count-in at 8k = 32,000. Deliberately nonbeat offset
        // proves indexing follows samples, not pulse/animation events.
        XCTAssertTrue(fixture.withUnsafeBufferPointer { BLDSPSetPracticeBed(bed, $0.baseAddress, 4, 32001) })
        let a = render(plain, 32010), b = render(bed, 32010)
        XCTAssertEqual(Array(a[..<32001]), Array(b[..<32001]))
        for i in 0..<4 { XCTAssertEqual(b[32001 + i] - a[32001 + i], fixture[i], accuracy: 0.000001) }
        XCTAssertEqual(Array(a[32005...]), Array(b[32005...]))
        for frame in [0, 7999, 8000, 16000, 24000, 32000] {
            var x = BLBeat(), y = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(plain, Int64(frame), &x)); XCTAssertTrue(BLDSPReadBeat(bed, Int64(frame), &y))
            XCTAssertEqual(x.startFrame, y.startFrame); XCTAssertEqual(x.endFrame, y.endFrame)
            XCTAssertEqual(x.beatNumber, y.beatNumber); XCTAssertEqual(x.barNumber, y.barNumber)
        }
        var x = BLClock(), y = BLClock()
        XCTAssertTrue(BLDSPReadClock(plain, &x)); XCTAssertTrue(BLDSPReadClock(bed, &y))
        XCTAssertEqual(x.renderStartFrame, y.renderStartFrame); XCTAssertEqual(x.hostTime, y.hostTime)
        XCTAssertEqual(x.frameCount, y.frameCount)
        XCTAssertFalse(fixture.withUnsafeBufferPointer { BLDSPSetPracticeBed(bed, $0.baseAddress, 4, 0) })
    }

    func testPracticeBedRejectsInvalidDataAndIsIndependentOfRenderQuantum() throws {
        let settings = BLSettings(bpm: 60, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)
        let a = try XCTUnwrap(BLDSPCreate(8000, settings)), b = try XCTUnwrap(BLDSPCreate(8000, settings))
        defer { BLDSPDestroy(a); BLDSPDestroy(b) }
        XCTAssertFalse(BLDSPSetPracticeBed(a, nil, 0, 0))
        for invalid: Float in [.nan, .infinity, 0.201, -0.201] {
            var value = invalid
            XCTAssertFalse(BLDSPSetPracticeBed(a, &value, 1, 0))
        }
        var value: Float = 0.1
        XCTAssertFalse(BLDSPSetPracticeBed(a, &value, 128001, 0))
        XCTAssertFalse(BLDSPSetPracticeBed(a, &value, 1, 64001))
        let fixture = [Float](repeating: 0.1, count: 2000)
        for dsp in [a,b] { XCTAssertTrue(fixture.withUnsafeBufferPointer { BLDSPSetPracticeBed(dsp, $0.baseAddress, 2000, 32000) }) }
        let whole = render(a, 35000)
        var chunks: [Float] = []
        for _ in 0..<350 { chunks += render(b, 100) }
        XCTAssertEqual(whole, chunks)
    }

    func testPracticeBedRespectsMuteGainAndDisablesOnTempoMeterOrSubdivisionChange() throws {
        let settings = BLSettings(bpm: 60, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)
        let fixture = [Float](repeating: 0.1, count: 128000)
        for mode in 0..<5 {
            var initial = settings
            if mode == 0 { initial.beatPattern = 255 }
            let dsp = try XCTUnwrap(BLDSPCreate(8000, initial)); defer { BLDSPDestroy(dsp) }
            XCTAssertTrue(fixture.withUnsafeBufferPointer { BLDSPSetPracticeBed(dsp, $0.baseAddress, UInt32($0.count), 0) })
            if mode == 1 { BLDSPSetGain(dsp, 0) }
            if mode <= 1 {
                XCTAssertTrue(render(dsp, 32001).allSatisfy { $0 == 0 })
                var beat = BLBeat(); XCTAssertTrue(BLDSPReadBeat(dsp, 32000, &beat)); XCTAssertEqual(beat.beatNumber, 4)
            } else {
                _ = render(dsp, 1)
                var changed = settings
                if mode == 2 { changed.bpm = 120 }
                if mode == 3 { changed.meter = 1 }
                if mode == 4 { changed.subdivision = 1 }
                XCTAssertTrue(BLDSPRequest(dsp, changed))
                // Meter applies at next bar; tempo/subdivision at next beat.
                _ = render(dsp, 32100)
                XCTAssertTrue(render(dsp, 32).allSatisfy { $0 == 0 }, "Bed must be silent after transport changes")
                XCTAssertTrue(BLDSPRequest(dsp, settings)); _ = render(dsp, 32100)
                XCTAssertTrue(render(dsp, 32).allSatisfy { $0 == 0 }, "A changed bed cannot rejoin at the wrong phrase")
            }
        }
    }
    func testMutedBeatSuppressesEverySubdivisionAndVoiceWhileClockAdvances() throws {
        // Independent fixture: 120 BPM / 48 kHz = 24,000 samples per big beat.
        // Accent, mute, normal, accent = 158 in the documented 2-bit format.
        for timbre in 0...2 {
            let dsp = try XCTUnwrap(BLDSPCreate(48000, BLSettings(bpm: 120, meter: 2, subdivision: 2, accent: 1, beatPattern: 158, timbre: Int32(timbre))))
            defer { BLDSPDestroy(dsp) }
            let output = render(dsp, 96001)
            XCTAssertNotEqual(output[0], 0)
            XCTAssertTrue(output[24000..<48000].allSatisfy { $0 == 0 })
            for position in [48000, 54000, 60000, 66000, 72000, 96000] { XCTAssertNotEqual(output[position], 0) }
            var beat = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(dsp, 24000, &beat))
            XCTAssertTrue(beat.muted)
            XCTAssertTrue(BLDSPReadBeat(dsp, 96000, &beat))
            XCTAssertEqual(beat.beatNumber, 4)
            XCTAssertFalse(beat.muted)
        }
        for mode in [1, 2] {
            let dsp = try XCTUnwrap(BLDSPCreate(48000, BLSettings(bpm: 120, meter: 2, subdivision: 1, accent: 1, beatPattern: 158, timbre: 0)))
            defer { BLDSPDestroy(dsp) }
            let fixture: [Float] = [0.4, 0.2, 0.1]
            for voice in 0..<5 { XCTAssertTrue(fixture.withUnsafeBufferPointer { BLDSPSetVoice(dsp, Int32(voice), $0.baseAddress!, 3) }) }
            XCTAssertTrue(BLDSPSetPracticeOptions(dsp, Int32(mode), 0, 0))
            let output = render(dsp, 48001)
            XCTAssertTrue(output[24000..<48000].allSatisfy { $0 == 0 })
            XCTAssertNotEqual(output[48000], 0)
        }
    }

    func testPatternWaitsForBarTimbreForBeatAndAllMutedRecoveryKeepsPhase() throws {
        try withDSP { dsp in
            _ = render(dsp, 1)
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 120, meter: 2, subdivision: 0, accent: 1, beatPattern: 255, timbre: 2)))
            let output = render(dsp, 95999)
            XCTAssertNotEqual(output[23999], 0) // next beat still audible
            var beat = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(dsp, 24000, &beat))
            XCTAssertEqual(beat.settings.beatPattern, 0)
            XCTAssertEqual(beat.settings.timbre, 2)
            XCTAssertTrue(render(dsp, 96000).allSatisfy { $0 == 0 })
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 120, meter: 2, subdivision: 0, accent: 1, beatPattern: 86, timbre: 1)))
            XCTAssertNotEqual(render(dsp, 1)[0], 0)
            XCTAssertTrue(BLDSPReadBeat(dsp, 192000, &beat))
            XCTAssertEqual(beat.beatNumber, 8)
            XCTAssertEqual(beat.barNumber, 2)
            XCTAssertEqual(beat.startFrame, 192000)
        }
    }

    func testInvalidOutputSettingsAreRejectedWithoutChangingRequestedState() throws {
        try withDSP { dsp in
            for pair in [(1, 0), (256, 0), (85, 3), (-1, 0)] {
                XCTAssertFalse(BLDSPRequest(dsp, BLSettings(bpm: 120, meter: 2, subdivision: 0, accent: 1, beatPattern: Int32(pair.0), timbre: Int32(pair.1))))
            }
            XCTAssertEqual(BLDSPRequestedSettings(dsp).beatPattern, 0)
            XCTAssertEqual(BLDSPRequestedSettings(dsp).timbre, 0)
        }
    }

    func testTempoChangeDoesNotApplyPendingCompoundMutePatternToOldBar() throws {
        try withDSP { dsp in
            _ = render(dsp, 1)
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 60, meter: 3, subdivision: 4, accent: 0, beatPattern: 15, timbre: 1)))
            let output = render(dsp, 168000)
            // Beat 1 changes tempo at 24,000, then the old four-beat bar finishes
            // at 168,000. Compound meter and its two muted beats start together.
            for frame in [24000, 72000, 120000] { XCTAssertNotEqual(output[frame - 1], 0) }
            XCTAssertEqual(output[167999], 0)
            var beat = BLBeat()
            XCTAssertTrue(BLDSPReadBeat(dsp, 24000, &beat))
            XCTAssertEqual(beat.settings.meter, 2)
            XCTAssertEqual(beat.settings.beatPattern, 0)
            XCTAssertFalse(beat.muted)
            XCTAssertTrue(BLDSPReadBeat(dsp, 168000, &beat))
            XCTAssertEqual(beat.settings.meter, 3)
            XCTAssertEqual(beat.settings.beatPattern, 15)
            XCTAssertEqual(beat.beatInBar, 0)
            XCTAssertTrue(beat.muted)
        }
    }

    private func withDSP(_ body: (OpaquePointer) throws -> Void) throws {
        let dsp = try XCTUnwrap(BLDSPCreate(48000, BLSettings(bpm: 120, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)))
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
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 60, meter: 2, subdivision: 1, accent: 1, beatPattern: 0, timbre: 0)))
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
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 120, meter: 3, subdivision: 4, accent: 0, beatPattern: 0, timbre: 0)))
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
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 60, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)))
            XCTAssertTrue(BLDSPRequest(dsp, BLSettings(bpm: 180, meter: 2, subdivision: 3, accent: 1, beatPattern: 0, timbre: 0)))
            XCTAssertFalse(BLDSPRequest(dsp, BLSettings(bpm: 241, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)))
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
        XCTAssertNil(BLDSPCreate(0, BLSettings(bpm: 120, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)))
        XCTAssertNil(BLDSPCreate(48000, BLSettings(bpm: 120, meter: 3, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)))
    }
}
