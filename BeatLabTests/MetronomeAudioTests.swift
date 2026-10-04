import XCTest
import UIKit
import AVFoundation
import BeatLabCore
import BeatLabDSP
@testable import BeatLab

final class MetronomeAudioTests: XCTestCase {
    @MainActor
    func testDomainToKernelMappingUsesCompoundMeter() async throws {
        let configuration = try MetronomeConfiguration(tempo: Tempo(bpm: 60),
            timeSignature: .sixEight, subdivision: .compoundEighth, accentEnabled: false)
        let settings = MetronomeAudio.settings(configuration)
        XCTAssertEqual(settings.bpm, 60)
        XCTAssertEqual(settings.meter, 3)
        XCTAssertEqual(settings.subdivision, 4)
        XCTAssertEqual(settings.accent, 0)
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
