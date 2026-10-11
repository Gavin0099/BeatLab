import XCTest
import UIKit
import AVFoundation
import BeatLabCore
import BeatLabDSP
@testable import BeatLab

final class MetronomeAudioTests: XCTestCase {
    func testOriginalGrooveHasBoundedPCMAndAnIndependentFourBeatCountIn() throws {
        for rate in [8_000.0, 44_100, 48_000, 96_000, 192_000] {
            let samples = try XCTUnwrap(PracticeGroove.samples(sampleRate: rate))
            XCTAssertEqual(samples.count, Int(rate) * 16)
            XCTAssertEqual(samples.first, 0); XCTAssertEqual(samples.last, 0)
            XCTAssertTrue(samples.allSatisfy(\.isFinite))
            XCTAssertLessThanOrEqual(samples.map { abs($0) }.max() ?? 1, 0.20)
        }
        for rate in [Double.nan, .infinity, 0, 7999, 192001, 48000.5] { XCTAssertNil(PracticeGroove.samples(sampleRate: rate)) }
        let samples = try XCTUnwrap(PracticeGroove.samples(sampleRate: 8000))
        let dsp = try XCTUnwrap(BLDSPCreate(8000, BLSettings(bpm: 60, meter: 2, subdivision: 0, accent: 1, beatPattern: 0, timbre: 0)))
        defer { BLDSPDestroy(dsp) }
        // Speech-only with no voice buffers isolates actual bed output from clicks.
        XCTAssertTrue(BLDSPSetPracticeOptions(dsp, 1, 0, 0)); BLDSPSetGain(dsp, 1)
        XCTAssertTrue(samples.withUnsafeBufferPointer { BLDSPSetPracticeBed(dsp, $0.baseAddress, UInt32($0.count), 32000) })
        var output = [Float](repeating: 0, count: 160128)
        output.withUnsafeMutableBufferPointer { BLDSPRender(dsp, $0.baseAddress, UInt32($0.count), 999) }
        XCTAssertTrue(output[..<32000].allSatisfy { $0 == 0 })
        XCTAssertEqual(Array(output[32000..<160000]), samples)
        XCTAssertTrue(output[160000...].allSatisfy { $0 == 0 })
        for beat in 0..<16 {
            let start = 32000 + beat * 8000
            XCTAssertGreaterThan(output[start..<(start + 800)].reduce(0.0) { $0 + Double($1 * $1) }, 0.01, "Every musical beat has real original percussion")
        }
    }

    @MainActor
    func testMissionGrooveIsPreparedOnlyForTheScopedGraphAndReleasedOnRestart() async throws {
        let audio = MetronomeAudio(); defer { audio.stop() }
        let configuration = try MetronomeConfiguration(tempo: Tempo(bpm: 60), timeSignature: .fourFour, subdivision: .quarter, accentEnabled: true)
        audio.start(configuration: configuration, practiceFeedback: true, eggMission: true)
        XCTAssertTrue(audio.isPlaying, audio.status ?? "Graph failed"); XCTAssertTrue(audio.practiceGrooveAvailable)
        for _ in 0..<20 where audio.displayBeat() == nil { try await Task.sleep(nanoseconds: 50_000_000) }
        let before = try XCTUnwrap(audio.displayBeat())
        audio.setGain(0); try await Task.sleep(nanoseconds: 150_000_000)
        let after = try XCTUnwrap(audio.displayBeat())
        XCTAssertGreaterThan(Double(after.number) + after.phase, Double(before.number) + before.phase)
        audio.stop(); XCTAssertFalse(audio.practiceGrooveAvailable)
        audio.start(configuration: configuration); XCTAssertTrue(audio.isPlaying); XCTAssertFalse(audio.practiceGrooveAvailable)
        audio.stop()
        audio.start(configuration: .defaultValue, practiceFeedback: true, eggMission: true)
        XCTAssertTrue(audio.isPlaying); XCTAssertFalse(audio.practiceGrooveAvailable, "80 BPM cannot reuse a 60 BPM phrase")
    }
    @MainActor
    func testFeedbackBuffersAreShortQuietTaperedMonoAndRejectInvalidRates() throws {
        for rate in [8_000.0, 44_100, 48_000, 96_000, 192_000] {
            for grade in [TimingGrade.perfect, .early, .late, .extra] {
                let buffer = try XCTUnwrap(PracticeFeedbackVoice.makeBuffer(grade: grade, sampleRate: rate))
                XCTAssertEqual(buffer.format.channelCount, 1)
                XCTAssertEqual(buffer.format.sampleRate, rate)
                let count = Int(buffer.frameLength)
                XCTAssertGreaterThan(count, 1)
                XCTAssertLessThanOrEqual(Double(count) / rate, 0.050)
                let pointer = try XCTUnwrap(buffer.floatChannelData?.pointee)
                let samples = Array(UnsafeBufferPointer(start: pointer, count: count))
                XCTAssertTrue(samples.allSatisfy(\.isFinite))
                XCTAssertEqual(samples.first, 0); XCTAssertEqual(samples.last, 0)
                XCTAssertLessThanOrEqual(samples.map { abs($0) }.max() ?? 1, 0.140001)
                XCTAssertGreaterThan(samples.reduce(0.0) { $0 + Double($1 * $1) } / Double(count), 0.00005)
            }
        }
        let graph = AVAudioEngine()
        let nodesBefore = graph.attachedNodes.count
        for rate in [Double.nan, .infinity, -48_000, 0, 7_999, 192_001] {
            XCTAssertNil(PracticeFeedbackVoice.makeBuffer(grade: .perfect, sampleRate: rate))
            XCTAssertNil(PracticeFeedbackVoice(graph: graph, sampleRate: rate, gain: 1))
        }
        XCTAssertEqual(graph.attachedNodes.count, nodesBefore)
    }

    @MainActor
    func testFeedbackActualOfflineGraphEmitsAudioMutesAndBoundsRapidReplacement() throws {
        let graph = AVAudioEngine()
        let voice = try XCTUnwrap(PracticeFeedbackVoice(graph: graph, sampleRate: 48_000, gain: 1))
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        try graph.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 256)
        let output = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256))
        try graph.start()
        defer { graph.stop(); voice.detach(); graph.disableManualRenderingMode() }
        func render() throws -> [Float] {
            XCTAssertEqual(try graph.renderOffline(256, to: output), .success)
            return Array(UnsafeBufferPointer(start: try XCTUnwrap(output.floatChannelData?.pointee), count: Int(output.frameLength)))
        }
        XCTAssertTrue(try render().allSatisfy { $0 == 0 })
        XCTAssertTrue(voice.play(.perfect))
        let audible = try render()
        XCTAssertGreaterThan(audible.map { abs($0) }.max() ?? 0, 0.005)
        XCTAssertTrue(audible.allSatisfy(\.isFinite))
        for _ in 0..<20 { XCTAssertTrue(voice.play(.extra)) }
        // 32 quanta = 170ms, far beyond one <=50ms effect, but shorter than
        // twenty queued effects. Final silence proves replacement is bounded.
        var tail: [Float] = []
        for _ in 0..<32 { tail = try render() }
        XCTAssertTrue(tail.allSatisfy { abs($0) < 0.000001 })
        XCTAssertTrue(voice.play(.late)); voice.setGain(0)
        XCTAssertFalse(voice.play(.perfect))
        for _ in 0..<4 { XCTAssertTrue(try render().allSatisfy { abs($0) < 0.000001 }) }
        graph.stop(); voice.setGain(1)
        XCTAssertFalse(voice.play(.perfect))
    }

    @MainActor
    func testPracticeFeedbackKeepsActualCueClockRunningAcrossMuteAndRestart() async throws {
        let audio = MetronomeAudio()
        defer { audio.stop() }
        audio.start(configuration: .defaultValue, practiceFeedback: true)
        XCTAssertTrue(audio.isPlaying, audio.status ?? "Graph failed")
        XCTAssertTrue(audio.practiceFeedbackAvailable)
        for _ in 0..<20 where audio.displayBeat() == nil { try await Task.sleep(nanoseconds: 50_000_000) }
        let before = try XCTUnwrap(audio.displayBeat())
        for _ in 0..<20 { XCTAssertTrue(audio.playPracticeFeedback(.perfect)) }
        audio.setGain(0)
        XCTAssertFalse(audio.playPracticeFeedback(.extra))
        XCTAssertTrue(audio.isPlaying)
        try await Task.sleep(nanoseconds: 150_000_000)
        let after = try XCTUnwrap(audio.displayBeat())
        XCTAssertGreaterThan(Double(after.number) + after.phase, Double(before.number) + before.phase)
        audio.stop()
        XCTAssertFalse(audio.practiceFeedbackAvailable); XCTAssertFalse(audio.practiceFeedbackIsPlaying)
        XCTAssertFalse(audio.playPracticeFeedback(.perfect))
        audio.start(configuration: .defaultValue)
        XCTAssertTrue(audio.isPlaying); XCTAssertFalse(audio.practiceFeedbackAvailable)
        XCTAssertFalse(audio.playPracticeFeedback(.perfect), "Free metronome must not gain game effects")
        audio.stop(); audio.setGain(0.7)
        audio.start(configuration: .defaultValue, practiceFeedback: true)
        XCTAssertTrue(audio.playPracticeFeedback(.late))
    }

    @MainActor
    func testPracticeFeedbackStopsOnBackgroundInterruptionAndRouteReset() async throws {
        let audio = MetronomeAudio()
        defer { audio.stop() }
        let events: [(Notification.Name, [AnyHashable: Any]?)] = [
            (UIApplication.didEnterBackgroundNotification, nil),
            (AVAudioSession.interruptionNotification, [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]),
            (AVAudioSession.routeChangeNotification, [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue]),
            (AVAudioSession.mediaServicesWereResetNotification, nil)
        ]
        for (name, info) in events {
            audio.start(configuration: .defaultValue, practiceFeedback: true)
            XCTAssertTrue(audio.playPracticeFeedback(.perfect))
            NotificationCenter.default.post(name: name, object: nil, userInfo: info)
            for _ in 0..<20 where audio.isPlaying { try await Task.sleep(nanoseconds: 25_000_000) }
            XCTAssertFalse(audio.isPlaying); XCTAssertFalse(audio.practiceFeedbackAvailable)
            XCTAssertFalse(audio.practiceFeedbackIsPlaying)
            XCTAssertFalse(audio.playPracticeFeedback(.extra)); XCTAssertNil(audio.audibleEpoch())
        }
    }

    @MainActor
    func testDomainToKernelMappingUsesCompoundMeter() async throws {
        let configuration = try MetronomeConfiguration(tempo: Tempo(bpm: 60),
            timeSignature: .sixEight, subdivision: .compoundEighth, accentEnabled: false)
        let settings = MetronomeAudio.settings(configuration)
        XCTAssertEqual(settings.bpm, 60)
        XCTAssertEqual(settings.meter, 3)
        XCTAssertEqual(settings.subdivision, 4)
        XCTAssertEqual(settings.accent, 0)
        XCTAssertEqual(settings.beatPattern, 5)
        XCTAssertEqual(settings.timbre, 0)
    }

    @MainActor
    func testActualEngineStartStopAndBackgroundStop() async throws {
        let audio = MetronomeAudio()
        defer { audio.stop() }
        audio.start(configuration: .defaultValue)
        XCTAssertTrue(audio.isPlaying, audio.status ?? "Audio engine did not start")
        guard audio.isPlaying else { return }
        var observedClock = false
        for _ in 0..<20 {
            try await Task.sleep(nanoseconds: 100_000_000)
            if audio.displayBeat() != nil { observedClock = true; break }
        }
        XCTAssertTrue(observedClock, "No audible-time beat snapshot from actual render callbacks")
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        for _ in 0..<10 where audio.isPlaying { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertFalse(audio.isPlaying)
        XCTAssertNil(audio.displayBeat())
        audio.start(configuration: .defaultValue)
        XCTAssertTrue(audio.isPlaying, audio.status ?? "Explicit restart failed")
        audio.stop()
        audio.stop()
        XCTAssertFalse(audio.isPlaying)
        XCTAssertNil(audio.displayBeat())
    }
    @MainActor
    func testVoicePreparationCanBeCancelledBackToClick() async throws {
        let audio = MetronomeAudio()
        defer { audio.stop() }
        audio.selectSound(.voice)
        audio.selectSound(.click)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(audio.sound, .click)
        XCTAssertFalse(audio.preparingVoice)
        audio.start(configuration: .defaultValue)
        XCTAssertTrue(audio.isPlaying, audio.status ?? "Click should remain available after voice cancellation")
    }
    @MainActor
    func testLifecycleNotificationsStopActualGraphAndRequireExplicitRestart() async throws {
        let audio = MetronomeAudio()
        defer { audio.stop() }
        let events: [(Notification.Name, [AnyHashable: Any]?)] = [
            (AVAudioSession.interruptionNotification, [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]),
            (AVAudioSession.routeChangeNotification, [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue]),
            (AVAudioSession.mediaServicesWereResetNotification, nil)
        ]
        for (name, info) in events {
            audio.start(configuration: .defaultValue)
            XCTAssertTrue(audio.isPlaying, audio.status ?? "Explicit start failed")
            NotificationCenter.default.post(name: name, object: nil, userInfo: info)
            for _ in 0..<20 where audio.isPlaying { try await Task.sleep(nanoseconds: 25_000_000) }
            XCTAssertFalse(audio.isPlaying)
            XCTAssertNil(audio.audibleEpoch())
            XCTAssertNil(audio.displayBeat())
        }
    }
}


final class RhythmAudioResumeTests: XCTestCase {
    @MainActor
    func testSamePercussionForAllJudgmentsAndLRTimingMeaning() throws {
        for rate in [8000.0,44100,48000,96000] {
            let reference=try XCTUnwrap(PracticeFeedbackVoice.makeBuffer(grade:.perfect,sampleRate:rate))
            let pcm=Array(UnsafeBufferPointer(start:reference.floatChannelData!.pointee,count:Int(reference.frameLength)))
            for grade in [TimingGrade.early,.late,.extra] {
                let buffer=try XCTUnwrap(PracticeFeedbackVoice.makeBuffer(grade:grade,sampleRate:rate))
                XCTAssertEqual(Array(UnsafeBufferPointer(start:buffer.floatChannelData!.pointee,count:Int(buffer.frameLength))),pcm)
            }
        }
    }
    func testActualPCMResumeIsBitEqualToUninterruptedTailAcrossBufferSplit() throws {
        // Independent specification:60BPM,48kHz,pause4.75s,count-in4s.
        let settings=BLSettings(bpm:60,meter:2,subdivision:0,accent:1,beatPattern:0,timbre:0)
        let original=try XCTUnwrap(RenderKernel(rate:48000,settings:settings))
        let reference=try XCTUnwrap(RenderKernel(rate:48000,settings:settings))
        let countIn=try XCTUnwrap(RenderKernel(rate:48000,settings:settings))
        var prefix=[Float](repeating:0,count:228000)
        BLDSPRender(original.pointer,&prefix,228000,100)
        BLDSPRender(reference.pointer,&prefix,228000,100)
        var expected=[Float](repeating:0,count:96000)
        BLDSPRender(reference.pointer,&expected,96000,200)
        let bridge=PracticeResumeBridge(original:original,countIn:countIn,frames:192000,rate:48000)
        var played=[Float](repeating:0,count:288000)
        // Deliberately crosses the count-in boundary inside a render buffer.
        played.withUnsafeMutableBufferPointer { p in
            bridge.render(p.baseAddress!,count:191997,host:300)
            bridge.render(p.baseAddress!.advanced(by:191997),count:96003,host:400)
        }
        XCTAssertEqual(Array(played[192000...]),expected)
        XCTAssertEqual(bridge.remaining,0)
        XCTAssertTrue(expected[12000..<12480].contains { abs($0)>0.01 },"First remaining beat at5.0s is0.25s after frozen4.75")
        XCTAssertTrue(expected[0..<11000].allSatisfy { abs($0)<0.001 })
        var clock=BLClock(); XCTAssertTrue(BLDSPReadClock(original.pointer,&clock))
        XCTAssertEqual(clock.renderStartFrame,228000); XCTAssertEqual(clock.frameCount,96000)
    }
}
