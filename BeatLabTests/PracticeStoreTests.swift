import Foundation
import XCTest
import SpriteKit
import UIKit
import BeatLabCore
@testable import BeatLab

private func routeFixture(hits: [TimingHit], alignment: Double = 0) throws -> RunnerRoute {
    // Reviewed first-beat spec: 4 count-in,16 quarter notes at60BPM,epoch100.
    try XCTUnwrap(RunnerRoute(targets: (0..<16).map { TimingTarget(id: $0, time: 104 + Double($0), stroke: .right) },
                             hits: hits, epoch: 100, endTime: 120.18, alignment: alignment))
}
private func routeFixture(accepted: Set<Int> = [], alignment: Double = 0) throws -> RunnerRoute {
    var session = try TimingSession(targets: (0..<16).map { TimingTarget(id: $0, time: 104 + Double($0), stroke: .right) })
    for id in accepted.sorted() { session.tap(at: 104 + Double(id)) }
    return try routeFixture(hits: session.hits, alignment: alignment)
}

final class PracticeStoreTests: XCTestCase {
    func testRealRouteReadOnlyGeometryExpiryAndInvalidInputs() throws {
        let route = try routeFixture()
        XCTAssertEqual(route.relativeTimes.first, 4); XCTAssertEqual(route.relativeTimes.last, 19)
        XCTAssertEqual(route.duration, 20.18, accuracy: 1e-10)
        XCTAssertNil(route.currentIndex(at: 3.999)); XCTAssertEqual(route.currentIndex(at: 4), 0)
        XCTAssertEqual(route.currentIndex(at: 8), 4); XCTAssertEqual(route.currentIndex(at: 19), 15)
        XCTAssertNil(route.currentIndex(at: .nan)); XCTAssertNil(route.missed(at: .infinity))
        XCTAssertNil(route.missed(at: 4.18)); XCTAssertEqual(route.missed(at: 4.181), 0)
        XCTAssertNil(route.missed(at: 4.66)); XCTAssertEqual(route.missed(at: 5.181), 1)
        let aligned = try routeFixture(alignment: 0.2)
        XCTAssertNil(aligned.missed(at: 4.38)); XCTAssertEqual(aligned.missed(at: 4.381), 0)
        let negative = try routeFixture(alignment: -0.2)
        XCTAssertNil(negative.missed(at: 3.98)); XCTAssertEqual(negative.missed(at: 3.981), 0)
        XCTAssertEqual(route.rockPosition(index: 0, elapsed: 4, marker: 100, stride: 120, reduced: false), 100)
        XCTAssertEqual(route.rockPosition(index: 1, elapsed: 4, marker: 100, stride: 120, reduced: false), 220)
        XCTAssertEqual(route.rockPosition(index: 2, elapsed: 4, marker: 100, stride: 120, reduced: false), 340)
        XCTAssertNil(route.rockPosition(index: 16, elapsed: 4, marker: 100, stride: 120, reduced: false))
        XCTAssertNil(route.rockPosition(index: 0, elapsed: .nan, marker: 100, stride: 120, reduced: false))
        for invalid in [Double.nan, .infinity, -.infinity] {
            XCTAssertNil(RunnerRoute(targets: route.targets, hits: [], epoch: invalid, endTime: 120.18, alignment: 0))
        }
        XCTAssertNil(RunnerRoute(targets: [], hits: [], epoch: 100, endTime: 120.18, alignment: 0))
        XCTAssertNil(RunnerRoute(targets: route.targets, hits: [], epoch: 100, endTime: 120.18, alignment: 0.251))
        XCTAssertNil(RunnerRoute(targets: Array(route.targets.reversed()), hits: [], epoch: 100, endTime: 120.18, alignment: 0))
        XCTAssertNil(RunnerRoute(targets: route.targets, hits: [], epoch: 100, endTime: 118, alignment: 0))
    }
    func testRouteUsesActualMatcherForEarlyDuplicateLateAndNoMissOrPrebeatRemoval() throws {
        let fixture = try routeFixture()
        var session = try TimingSession(targets: fixture.targets)
        session.tap(at: 103.86); session.tap(at: 103.87); session.tap(at: 105.12)
        let route = try XCTUnwrap(RunnerRoute(targets: session.targets, hits: session.hits, epoch: 100, endTime: 120.18, alignment: 0))
        XCTAssertEqual(route.accepted, [0,1]); XCTAssertEqual(route.grades[0], .early); XCTAssertEqual(route.grades[1], .late)
        XCTAssertEqual(route.hits.last?.targetID, 1); XCTAssertEqual(route.hits.filter { $0.grade == .extra }.count, 1)
        XCTAssertNil(route.missed(at: 4.3)); XCTAssertNil(route.missed(at: 5.3)); XCTAssertEqual(route.missed(at: 6.3), 2)
        XCTAssertEqual(route.obstacleAlpha(index: 0, elapsed: 3.9, reduced: false), 1)
        XCTAssertEqual(route.obstacleAlpha(index: 0, elapsed: 4, reduced: false), 1)
        XCTAssertEqual(route.obstacleAlpha(index: 0, elapsed: 4.125, reduced: false), 0.5, accuracy: 1e-9)
        XCTAssertEqual(route.obstacleAlpha(index: 2, elapsed: 6.3, reduced: false), 1)
        XCTAssertEqual(EggAnimationFrame.sample(elapsed: 3.9, age: 0.04, reduceMotion: false), 8)
        XCTAssertEqual(EggAnimationFrame.sample(elapsed: 3.9, age: 0.04, reduceMotion: true), 14)
    }

    @MainActor
    func testDisplayClockIsReadOnlyContinuousAndCannotFinishOrScoreTheLesson() async throws {
        let name = "BeatLabTests.DisplayClock.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PracticeStore(repository: ProgressRepository(defaults: defaults)), audio = MetronomeAudio()
        defer { audio.stop() }
        XCTAssertEqual(store.presentationElapsed(at: .nan), 0)
        store.select(store.lessons[0]); store.start(store.lessons[0], audio: audio, eggMission: true)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing)
        let epoch = try XCTUnwrap(audio.audibleEpoch())
        let published = store.elapsed
        // Independent elapsed fixture: one millisecond host separation remains
        // one millisecond on screen, including between 30ms store updates.
        let first = store.presentationElapsed(at: epoch + 4.125)
        let second = store.presentationElapsed(at: epoch + 4.126)
        XCTAssertEqual(first, 4.125, accuracy: 0.00001)
        XCTAssertEqual(second - first, 0.001, accuracy: 0.00001)
        XCTAssertEqual(store.presentationElapsed(at: epoch - 2), 0)
        for invalid in [Double.nan, .infinity, -.infinity] { XCTAssertEqual(store.presentationElapsed(at: invalid), published) }
        XCTAssertLessThan(store.presentationElapsed(at: epoch + 1000), 21)
        XCTAssertEqual(store.elapsed, published)
        XCTAssertEqual(store.phase, .playing); XCTAssertNil(store.latestHit); XCTAssertNil(store.summary)
        XCTAssertEqual(store.stars, 0); XCTAssertTrue(store.progress.results.isEmpty)
        let route = try XCTUnwrap(store.runnerRoute)
        XCTAssertEqual(route.targets.count, 16); XCTAssertEqual(route.relativeTimes.first!, 4, accuracy: 0.00001)
        XCTAssertEqual(route.relativeTimes.last!, 19, accuracy: 0.00001)
        XCTAssertTrue(route.accepted.isEmpty); XCTAssertEqual(route.duration, 20.18, accuracy: 0.00001)
        store.tap(at: epoch + 4.125)
        XCTAssertEqual(store.latestHit?.targetID, 0); XCTAssertEqual(store.latestHit?.grade, .late)
        XCTAssertEqual(store.runnerRoute?.accepted, [0]); XCTAssertEqual(store.runnerRoute?.grades[0], .late)
        store.cancel(audio: audio)
        XCTAssertNil(store.runnerRoute)
        XCTAssertEqual(store.presentationElapsed(at: epoch + 1000), store.elapsed)
        XCTAssertTrue(store.progress.results.isEmpty)
        store.start(store.lessons[0], audio: audio, eggMission: true)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        let nextEpoch = try XCTUnwrap(audio.audibleEpoch())
        XCTAssertGreaterThan(nextEpoch, epoch)
        XCTAssertEqual(store.presentationElapsed(at: nextEpoch + 0.025), 0.025, accuracy: 0.00001)
        XCTAssertNil(store.latestHit); store.cancel(audio: audio)
    }
    @MainActor
    func testEggMissionUsesOriginalMatchingAndClearsMusicOnCancelCalibrationAndTempoChange() async throws {
        let name = "BeatLabTests.EggMission.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PracticeStore(repository: ProgressRepository(defaults: defaults)), audio = MetronomeAudio()
        defer { audio.stop() }
        let first = store.lessons[0]
        store.select(first); store.start(first, audio: audio, eggMission: true)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing); XCTAssertTrue(store.isEggMission); XCTAssertTrue(audio.practiceGrooveAvailable)
        let epoch = try XCTUnwrap(audio.audibleEpoch())
        store.tap(at: epoch + 1); XCTAssertNil(store.latestHit)
        store.tap(at: epoch + 4); XCTAssertEqual(store.latestHit?.grade, .perfect); XCTAssertEqual(store.latestHit?.targetID, 0)
        store.tap(at: epoch + 4); XCTAssertEqual(store.latestHit?.grade, .extra)
        store.cancel(audio: audio)
        XCTAssertFalse(store.isEggMission); XCTAssertFalse(audio.practiceGrooveAvailable); XCTAssertTrue(store.progress.results.isEmpty)
        store.startCalibration(audio: audio)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing); XCTAssertFalse(store.isEggMission); XCTAssertFalse(audio.practiceGrooveAvailable)
        store.cancel(audio: audio); store.select(first); store.setPracticeBPM(65)
        store.start(first, audio: audio, eggMission: true)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing); XCTAssertFalse(store.isEggMission); XCTAssertFalse(audio.practiceGrooveAvailable)
        store.cancel(audio: audio)
    }
    @MainActor
    func testRealMatcherStartsFeedbackButCountInAndCalibrationDoNot() async throws {
        let name = "BeatLabTests.Feedback.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PracticeStore(repository: ProgressRepository(defaults: defaults))
        let audio = MetronomeAudio()
        defer { audio.stop() }
        store.select(store.lessons[0]); store.setPracticeBPM(240)
        store.start(store.lessons[0], audio: audio)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing)
        let epoch = try XCTUnwrap(audio.audibleEpoch())
        XCTAssertTrue(audio.practiceFeedbackAvailable); XCTAssertFalse(audio.practiceFeedbackIsPlaying)
        store.tap(at: epoch + 0.5)
        XCTAssertNil(store.latestHit); XCTAssertFalse(audio.practiceFeedbackIsPlaying)
        // Independent quarter fixture: four count-in beats at 240 BPM = 1s.
        // Injected timestamp proves integration, not real touch-to-sound latency.
        store.tap(at: epoch + 1)
        XCTAssertEqual(store.latestHit?.grade, .perfect); XCTAssertEqual(store.latestHit?.targetID, 0)
        XCTAssertTrue(audio.practiceFeedbackIsPlaying)
        store.cancel(audio: audio)
        XCTAssertFalse(audio.practiceFeedbackIsPlaying)
        XCTAssertTrue(store.progress.results.isEmpty)
        store.startCalibration(audio: audio)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing)
        XCTAssertFalse(audio.practiceFeedbackAvailable)
        let calibrationEpoch = try XCTUnwrap(audio.audibleEpoch())
        store.tap(at: calibrationEpoch + 4)
        XCTAssertEqual(store.latestHit?.grade, .perfect)
        XCTAssertFalse(audio.practiceFeedbackIsPlaying)
        store.cancel(audio: audio)
    }

    @MainActor
    func testAllTenCatalogLessonsStartCancelAndRestoreSeededProgress() async throws {
        let ids = ["first-beat", "quarter-hands", "eighth", "eighth-hands", "quarter-rest", "eighth-rest", "sixteenth", "sixteenth-hands", "offbeat", "mixed"]
        let name = "BeatLabTests.TenLessons.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let repository = ProgressRepository(defaults: defaults)
        // Reviewed v1 fixture unlocks all lessons for smoke; it does not simulate
        // earning stars or claim real-touch completion of ten lessons.
        let results = Dictionary(uniqueKeysWithValues: ids.map { ($0, ["stars": 1.0, "bestPerfectRate": 1.0, "bestBPM": 60.0]) })
        let data = try JSONSerialization.data(withJSONObject: ["results": results, "mode": "beginner"])
        let fixture = try JSONDecoder().decode(PracticeProgress.self, from: data)
        try repository.save(fixture)
        let store = PracticeStore(repository: repository)
        XCTAssertEqual(store.lessons.map(\.id), ids)
        let audio = MetronomeAudio()
        defer { audio.stop() }
        for (index, lesson) in store.lessons.enumerated() {
            XCTAssertTrue(store.unlocked(lesson), ids[index])
            store.select(lesson)
            XCTAssertEqual(store.selected?.id, ids[index])
            store.start(lesson, audio: audio)
            for _ in 0..<60 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
            XCTAssertEqual(store.phase, .playing, "\(ids[index]): \(store.notice ?? "")")
            XCTAssertTrue(audio.isPlaying)
            store.cancel(audio: audio)
            XCTAssertEqual(store.phase, .idle)
            XCTAssertFalse(audio.isPlaying)
            XCTAssertNil(store.summary)
            XCTAssertEqual(repository.load().0, fixture, "Cancel must not award a lesson")
        }
        let restored = PracticeStore(repository: repository)
        XCTAssertEqual(restored.progress, fixture)
        XCTAssertEqual(restored.lessons.filter { restored.unlocked($0) }.count, 10)
    }
    @MainActor
    func testLockedLessonCannotBeSelectedAndModeSurvivesNewStore() async throws {
        let name = "BeatLabTests.PracticeStore.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let repository = ProgressRepository(defaults: defaults)
        let store = PracticeStore(repository: repository)
        XCTAssertEqual(store.lessons.count, 10)
        store.select(store.lessons[1])
        XCTAssertNil(store.selected)
        store.select(store.lessons[0])
        XCTAssertEqual(store.selected?.id, "first-beat")
        store.setMode(.standard)
        XCTAssertEqual(PracticeStore(repository: repository).mode, .standard)
        store.setPracticeBPM(300)
        XCTAssertEqual(store.practiceBPM, 240)
        store.setPracticeBPM(30)
        XCTAssertEqual(store.practiceBPM, 60)
    }
    @MainActor
    func testFutureProgressLocksWritesUntilExplicitReset() async throws {
        let name = "BeatLabTests.PracticeFuture.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let data = Data("{\"schemaVersion\":99,\"future\":true}".utf8)
        defaults.set(data, forKey: ProgressRepository.storageKey)
        let store = PracticeStore(repository: ProgressRepository(defaults: defaults))
        XCTAssertFalse(store.canPractice)
        XCTAssertTrue(store.progressVersionConflict)
        store.setMode(.standard)
        XCTAssertEqual(defaults.data(forKey: ProgressRepository.storageKey), data)
        store.resetProgress(); store.setMode(.standard)
        XCTAssertTrue(store.canPractice)
        XCTAssertFalse(store.progressVersionConflict)
        XCTAssertEqual(store.mode, .standard)
    }
    @MainActor
    func testCancellingAnActualPracticeTransportDoesNotRecordCompletion() async throws {
        let name = "BeatLabTests.PracticeCancel.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PracticeStore(repository: ProgressRepository(defaults: defaults))
        let audio = MetronomeAudio()
        defer { audio.stop() }
        store.start(store.lessons[0], audio: audio)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing, store.notice ?? "Practice did not start")
        store.cancel(audio: audio)
        XCTAssertEqual(store.phase, .idle)
        XCTAssertFalse(audio.isPlaying)
        XCTAssertNil(store.summary)
        XCTAssertTrue(ProgressRepository(defaults: defaults).load().0.results.isEmpty)
    }
    @MainActor
    func testUnsavedResultIsRetainedForRetryWithoutPretendingProgressIsSaved() async throws {
        let name = "BeatLabTests.UnsavedResult.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PracticeStore(repository: ProgressRepository(defaults: defaults))
        let audio = MetronomeAudio()
        defer { audio.stop() }
        let lesson = store.lessons[0]
        store.select(lesson); store.setPracticeBPM(240); store.start(lesson, audio: audio)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing, store.notice ?? "Actual practice graph did not start")
        let anchor = try XCTUnwrap(audio.audibleEpoch())
        // Four-bar quarter-note fixture at 240 BPM: four count-in beats, then
        // sixteen exact target timestamps. Injected input is not device latency evidence.
        for beat in 0..<16 { store.tap(at: anchor + Double(4 + beat) * 0.25) }
        // A version change between load and finish must fail the repository write.
        let future = Data("{\"schemaVersion\":99,\"future\":true}".utf8)
        defaults.set(future, forKey: ProgressRepository.storageKey)
        for _ in 0..<160 where store.phase == .playing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .finished)
        XCTAssertNotNil(store.summary)
        XCTAssertEqual(store.stars, 3)
        XCTAssertEqual(store.summary?.missedCount, 0)
        XCTAssertFalse(store.resultSaved)
        XCTAssertTrue(store.needsSaveRetry)
        XCTAssertNil(store.progress.lastLessonID)
        XCTAssertFalse(store.unlocked(store.lessons[1]), "Unsaved stars cannot unlock the journey")
        store.retrySave()
        XCTAssertFalse(store.resultSaved)
        XCTAssertEqual(defaults.data(forKey: ProgressRepository.storageKey), future)
        store.select(lesson)
        XCTAssertEqual(store.phase, .finished, "Pending results must not disappear when browsing lessons")
        // Explicit test removal of the incompatible payload models resolved storage.
        defaults.removeObject(forKey: ProgressRepository.storageKey)
        store.retrySave()
        XCTAssertTrue(store.resultSaved)
        XCTAssertFalse(store.needsSaveRetry)
        XCTAssertEqual(ProgressRepository(defaults: defaults).load().0.lastLessonID, lesson.id)
        XCTAssertEqual(ProgressRepository(defaults: defaults).load().0.results[lesson.id]?.stars, 3)
        XCTAssertTrue(store.unlocked(store.lessons[1]))
    }
    @MainActor
    func testPerfectActualSessionSavesStarsAndUnlocksAfterRestart() async throws {
        let name = "BeatLabTests.JourneyPass.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let repository = ProgressRepository(defaults: defaults)
        let store = PracticeStore(repository: repository)
        let audio = MetronomeAudio(); defer { audio.stop() }
        let first = store.lessons[0]
        store.select(first); store.setPracticeBPM(240); store.start(first, audio: audio)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing)
        let anchor = try XCTUnwrap(audio.audibleEpoch())
        for beat in 0..<16 { store.tap(at: anchor + Double(4 + beat) * 0.25) }
        for _ in 0..<160 where store.phase == .playing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .finished)
        XCTAssertEqual(store.summary?.targetCount, 16)
        XCTAssertEqual(store.summary?.matched.count, 16)
        XCTAssertEqual(store.summary?.extraCount, 0)
        XCTAssertEqual(store.summary?.missedCount, 0)
        XCTAssertEqual(store.stars, 3)
        XCTAssertTrue(store.resultSaved); XCTAssertFalse(store.needsSaveRetry)
        let restored = PracticeStore(repository: repository)
        XCTAssertEqual(restored.progress.results[first.id]?.stars, 3)
        XCTAssertTrue(restored.unlocked(restored.lessons[1]))
        XCTAssertFalse(restored.unlocked(restored.lessons[2]))
        XCTAssertEqual(restored.recommended?.id, "quarter-hands")
    }
    @MainActor
    func testDiscardingUnsavedPerfectResultPreservesStorageAndLocks() async throws {
        let name = "BeatLabTests.JourneyDiscard.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PracticeStore(repository: ProgressRepository(defaults: defaults))
        let audio = MetronomeAudio(); defer { audio.stop() }
        store.select(store.lessons[0]); store.setPracticeBPM(240); store.start(store.lessons[0], audio: audio)
        for _ in 0..<40 where store.phase == .preparing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .playing)
        let anchor = try XCTUnwrap(audio.audibleEpoch())
        for beat in 0..<16 { store.tap(at: anchor + Double(4 + beat) * 0.25) }
        let future = Data("{\"schemaVersion\":99,\"future\":true}".utf8)
        defaults.set(future, forKey: ProgressRepository.storageKey)
        for _ in 0..<160 where store.phase == .playing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertTrue(store.needsSaveRetry); XCTAssertEqual(store.stars, 3)
        store.discardUnsavedResult()
        XCTAssertEqual(store.phase, .idle); XCTAssertNil(store.summary)
        XCTAssertEqual(store.stars, 0); XCTAssertFalse(store.needsSaveRetry)
        XCTAssertTrue(store.progress.results.isEmpty)
        XCTAssertFalse(store.unlocked(store.lessons[1]))
        XCTAssertEqual(defaults.data(forKey: ProgressRepository.storageKey), future)
    }
}

final class EggMissionPresentationTests: XCTestCase {
    func testRecoveryHighlightIsFiniteClearsForActionAndDoesNotRunDuringReduceMotion() {
        XCTAssertEqual(EggMissionPresentation.recoveryBlend(elapsed: 4.67, accepted: [], actionAge: nil, reduceMotion: false), 0.18, accuracy: 0.0001)
        XCTAssertEqual(EggMissionPresentation.recoveryBlend(elapsed: 4.67, accepted: [], actionAge: nil, reduceMotion: true), 0.12)
        XCTAssertEqual(EggMissionPresentation.recoveryBlend(elapsed: 4.67, accepted: [0], actionAge: nil, reduceMotion: false), 0)
        XCTAssertEqual(EggMissionPresentation.recoveryBlend(elapsed: 4.67, accepted: [], actionAge: 0.01, reduceMotion: false), 0)
        for elapsed in [Double.nan, .infinity, -.infinity, -1, 0, 4, 4.99, 20] {
            XCTAssertEqual(EggMissionPresentation.recoveryBlend(elapsed: elapsed, accepted: [], actionAge: nil, reduceMotion: false), 0)
        }
    }
    @MainActor
    func testMissRecoveryKeepsRunCycleBodyRegistrationAndUpcomingCue() throws {
        for theme in RunnerTheme.allCases {
            let normal = EggSpriteScene(size: CGSize(width: 400, height: 400))
            let missed = EggSpriteScene(size: CGSize(width: 400, height: 400))
            normal.configure(EggSceneSnapshot(elapsed: 4.47, accepted: [0], theme: theme, route: try routeFixture(accepted: [0])))
            missed.configure(EggSceneSnapshot(elapsed: 4.47, theme: theme, route: try routeFixture()))
            let normalPlayer = try XCTUnwrap(normal.childNode(withName: "player"))
            let missedPlayer = try XCTUnwrap(missed.childNode(withName: "player"))
            let reference = try XCTUnwrap(normalPlayer.childNode(withName: "characterPrimary") as? SKSpriteNode)
            let character = try XCTUnwrap(missedPlayer.childNode(withName: "characterPrimary") as? SKSpriteNode)
            let before = try XCTUnwrap(character.texture)
            XCTAssertTrue(character.texture === reference.texture, "A miss must not switch a running character to a static/other-atlas pose")
            XCTAssertEqual(character.size, reference.size); XCTAssertEqual(character.anchorPoint, reference.anchorPoint)
            XCTAssertEqual(missedPlayer.position.y, normalPlayer.position.y, accuracy: 0.0001, "Miss text must not abruptly suppress the gait")
            XCTAssertGreaterThan(character.colorBlendFactor, 0)
            XCTAssertEqual(reference.colorBlendFactor, 0)
            XCTAssertFalse(try XCTUnwrap(missed.childNode(withName: "rock1")).isHidden)
            XCTAssertEqual(try XCTUnwrap(missed.childNode(withName: "rock1")).position.x,
                           try XCTUnwrap(normal.childNode(withName: "rock1")).position.x, accuracy: 0.0001)
            missed.configure(EggSceneSnapshot(elapsed: 4.57, theme: theme, route: try routeFixture()))
            XCTAssertFalse(character.texture === before, "Run poses must keep advancing during the recovery window")
            XCTAssertEqual(missedPlayer.children.count, 1, "No double character from crossfades")
        }
    }
    @MainActor
    func testEarlyMatchedObstacleStaysVisibleUntilScheduledCrossing() throws {
        let scene = EggSpriteScene(size: CGSize(width: 400, height: 400))
        let rock = try XCTUnwrap(scene.childNode(withName: "rock0"))
        let reward = try XCTUnwrap(scene.childNode(withName: "reward0"))
        scene.configure(EggSceneSnapshot(elapsed: 3.9, accepted: [0], route: try routeFixture(accepted: [0])))
        XCTAssertFalse(rock.isHidden, "An early accepted press must not remove a cue before the fixed 4s first beat")
        XCTAssertEqual(rock.alpha, 1, accuracy: 0.0001)
        XCTAssertTrue(reward.isHidden, "Route reward must not replace the upcoming rock before crossing")
    }
    @MainActor
    func testSixteenObstacleCentersCrossFixedMarkerAtCatalogBeatsRegardlessOfHitsOrDroppedFrames() throws {
        let lesson = try XCTUnwrap(try LessonCatalog.bundled().lessons.first { $0.id == "first-beat" })
        let targets = try lesson.pattern.targets(bpm: 60, bars: 4, epoch: 100)
        XCTAssertEqual(targets.map(\.time), (104...119).map(Double.init), "Reviewed first lesson: four count-in beats, then sixteen 1s targets")
        for width: CGFloat in [320, 375, 402] {
            for accepted: Set<Int> in [[], [0, 2, 5, 15], Set(0..<16)] {
                let scene = EggSpriteScene(size: CGSize(width: width, height: 400))
                let state = EggSceneSnapshot(accepted: accepted, presentationElapsed: { $0 - 100 }, route: try routeFixture(accepted: accepted))
                scene.configure(state)
                let marker = try XCTUnwrap(scene.childNode(withName: "beatMarker"))
                for target in targets {
                    // Render directly after arbitrary skipped display frames:
                    // position must still read the catalog/audio-host timeline.
                    scene.render(at: target.time - 0.1)
                    let rock = try XCTUnwrap(scene.childNode(withName: "rock\(target.id)"))
                    XCTAssertFalse(rock.isHidden); XCTAssertEqual(rock.alpha, 1, accuracy: 0.0001)
                    XCTAssertGreaterThan(rock.position.x, marker.position.x)
                    scene.render(at: target.time)
                    XCTAssertEqual(rock.position.x, marker.position.x, accuracy: 0.0001)
                    XCTAssertFalse(rock.isHidden)
                    XCTAssertEqual(marker.alpha, 1, accuracy: 0.0001)
                    scene.render(at: target.time + 0.125)
                    XCTAssertLessThan(rock.position.x, marker.position.x)
                    XCTAssertEqual(rock.alpha, accepted.contains(target.id) ? 0.5 : 1, accuracy: 0.0001)
                }
                scene.configure(EggSceneSnapshot(elapsed: 8.5, accepted: accepted, route: try routeFixture(accepted: accepted)))
                let fifth = try XCTUnwrap(scene.childNode(withName: "rock5"))
                let sixth = try XCTUnwrap(scene.childNode(withName: "rock6"))
                XCTAssertEqual(sixth.position.x - fifth.position.x, width * 0.31, accuracy: 0.0001)
            }
        }
    }
    func testBeatLaneReducedMotionAndInvalidValuesDoNotRemoveUpcomingCues() {
        for reduced in [false, true] {
            for time in [Double.nan, -.infinity, .infinity, -1, 0, 3.9, 4] {
                XCTAssertEqual(EggBeatLane.obstacleAlpha(id: 0, elapsed: time, matched: true, reduceMotion: reduced), 1)
            }
            XCTAssertEqual(EggBeatLane.obstacleAlpha(id: 0, elapsed: 4.125, matched: false, reduceMotion: reduced), 1)
            XCTAssertEqual(EggBeatLane.obstacleAlpha(id: 0, elapsed: 4.25, matched: true, reduceMotion: reduced), 0)
        }
        XCTAssertEqual(EggBeatLane.obstacleAlpha(id: 0, elapsed: 4.125, matched: true, reduceMotion: true), 0)
        XCTAssertEqual(EggBeatLane.markerAlpha(elapsed: 4, reduceMotion: true), 0.45)
        XCTAssertEqual(EggBeatLane.markerAlpha(elapsed: .nan, reduceMotion: false), 0.45)
        XCTAssertEqual(EggBeatLane.markerAlpha(elapsed: 20, reduceMotion: false), 0.45)
    }
    @MainActor
    func testCompanionScenesUseDistinctLoadedArtAndMotionWithoutChangingAcceptedState() throws {
        let scenes = try [RunnerTheme.cat, .robot].map { theme -> EggSpriteScene in
            let scene = EggSpriteScene(size: CGSize(width: 400, height: 400))
            scene.configure(EggSceneSnapshot(elapsed: 4.16, accepted: [0], latestGrade: .perfect, hitAge: 0.16, theme: theme, route: try routeFixture(accepted: [0])))
            return scene
        }
        let textures = try scenes.map { scene -> SKTexture in
            let player = try XCTUnwrap(scene.childNode(withName: "player"))
            let sprite = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
            XCTAssertEqual(player.children.count, 1); XCTAssertEqual(sprite.alpha, 1)
            XCTAssertGreaterThan(sprite.size.height, 70); XCTAssertGreaterThan(try XCTUnwrap(sprite.texture).size().width, 100)
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "rock0")).isHidden)
            XCTAssertEqual(try XCTUnwrap(scene.childNode(withName: "rock0")).alpha, 0.36, accuracy: 0.0001)
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "reward0")).isHidden)
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "rock1")).isHidden)
            XCTAssertGreaterThan(player.position.y, 100)
            return try XCTUnwrap(sprite.texture)
        }
        XCTAssertFalse(textures[0] === textures[1], "Cat and robot must have independent art, not a tint of one sprite")
        let cat = try XCTUnwrap(scenes[0].childNode(withName: "player")), robot = try XCTUnwrap(scenes[1].childNode(withName: "player"))
        XCTAssertGreaterThan(abs(cat.zRotation), abs(robot.zRotation), "Cat leans softly; robot stays upright")
        for scene in scenes {
            let count = scene.children.count, player = try XCTUnwrap(scene.childNode(withName: "player"))
            let character = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
            var state = EggSceneSnapshot(elapsed: 4, theme: scene.theme, route: try routeFixture())
            scene.configure(state); let run = try XCTUnwrap(character.texture)
            state.elapsed = 4.0625; scene.configure(state)
            XCTAssertFalse(run === character.texture, "Successive run frames must be distinct loaded textures")
            state.elapsed = 4.5; scene.configure(state)
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "rock0")).isHidden, "Miss cannot advance a target")
            state.latestGrade = .extra; state.hitAge = 0.16; scene.configure(state)
            XCTAssertLessThan(player.position.y, 70, "Extra only makes the original small bounce")
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "rock0")).isHidden)
            state.reduceMotion = true; scene.configure(state)
            XCTAssertEqual(player.position.y, 51, accuracy: 0.01); XCTAssertEqual(player.zRotation, 0)
            XCTAssertEqual(player.xScale, 1); XCTAssertEqual(player.yScale, 1)
            state = EggSceneSnapshot(preparing: true, theme: scene.theme); scene.configure(state)
            XCTAssertTrue(try XCTUnwrap(scene.childNode(withName: "rock0")).isHidden)
            scene.size = CGSize(width: 320, height: 240); scene.render(at: .nan)
            XCTAssertEqual(scene.children.count, count); XCTAssertTrue(player.position.y.isFinite)
            XCTAssertTrue(scene.childNode(withName: "player") === player)
            scene.configure(EggSceneSnapshot(preparing: true, theme: .dinosaur))
            XCTAssertEqual(scene.theme, .dinosaur); XCTAssertEqual(scene.children.count, count)
        }
    }
    @MainActor
    func testBothCompanionSKViewsReallyUpdateAndPauseInReducedMotion() async throws {
        for theme in [RunnerTheme.cat, .robot] {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800)), controller = UIViewController()
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 400)), scene = EggSpriteScene(size: CGSize(width: 400, height: 400))
            window.rootViewController = controller; controller.view.addSubview(view); window.makeKeyAndVisible()
            defer { scene.detach(); view.presentScene(nil); window.isHidden = true }
            view.isUserInteractionEnabled = false; view.presentScene(scene)
            let epoch = PracticeStore.now()
            scene.configure(EggSceneSnapshot(presentationElapsed: { 4 + $0 - epoch }, theme: theme))
            try await Task.sleep(nanoseconds: 800_000_000)
            XCTAssertGreaterThan(scene.callbackCount, 2)
            scene.configure(EggSceneSnapshot(reduceMotion: true, presentationElapsed: { 4 + $0 - epoch }, theme: theme))
            let count = scene.callbackCount; try await Task.sleep(nanoseconds: 100_000_000)
            XCTAssertEqual(scene.callbackCount, count); XCTAssertTrue(view.isPaused)
            scene.detach(); view.presentScene(nil); XCTAssertNil(view.scene)
        }
    }
    func testEightDistinctRunFramesLoopContinuouslyAndJumpHasSoftTouchdown() {
        let fixtures: [(Double, Int)] = [(4, 0), (4.0625, 1), (4.125, 2), (4.1875, 3), (4.25, 4), (4.3125, 5), (4.375, 6), (4.4375, 7)]
        for (time, frame) in fixtures { XCTAssertEqual(EggAnimationFrame.sample(elapsed: time, age: nil, reduceMotion: false), frame) }
        XCTAssertEqual(EggAnimationFrame.sample(elapsed: 4.4999, age: nil, reduceMotion: false), 7)
        XCTAssertEqual(EggAnimationFrame.sample(elapsed: 4.5001, age: nil, reduceMotion: false), 0)
        // Reviewed contract: normalized ballistic peak at one third of 0.48s,
        // with zero vertical velocity on touchdown. Not physical latency.
        XCTAssertEqual(EggMotion.sample(elapsed: 5, age: 0.16, grade: .perfect, reduceMotion: false).height, 74, accuracy: 0.001)
        XCTAssertEqual(EggMotion.sample(elapsed: 5, age: 0.16, grade: .extra, reduceMotion: false).height, 12, accuracy: 0.001)
        XCTAssertLessThan(EggMotion.sample(elapsed: 5, age: 0.479, grade: .perfect, reduceMotion: false).height, 0.003)
        XCTAssertEqual(EggMotion.sample(elapsed: 5, age: 0.48, grade: .perfect, reduceMotion: false).height, 0)
        for time in [Double.nan, .infinity, -1, 0, 4, 20, Double.greatestFiniteMagnitude] {
            XCTAssertEqual(EggAnimationFrame.sample(elapsed: time, age: 0.16, reduceMotion: true), 14)
        }
        XCTAssertEqual(EggAnimationFrame.sample(elapsed: Double.greatestFiniteMagnitude, age: nil, reduceMotion: false), 14)
    }
    @MainActor
    func testPersistentSceneNodesFollowRealAcceptedSnapshotWithoutExtraReplayOrStaleRetry() throws {
        let scene = EggSpriteScene(size: CGSize(width: 400, height: 400))
        let player = try XCTUnwrap(scene.childNode(withName: "player"))
        XCTAssertEqual(player.children.count, 1, "One opaque character layer: crossfading illustrated heads creates ghost eyes")
        let character = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
        let rock = try XCTUnwrap(scene.childNode(withName: "rock0"))
        let reward = try XCTUnwrap(scene.childNode(withName: "reward0"))
        let count = scene.children.count
        func hit(_ target: Int?, _ input: Double, _ grade: String) throws -> TimingHit {
            let id = target.map(String.init) ?? "null"
            return try JSONDecoder().decode(TimingHit.self, from: Data("{\"targetID\":\(id),\"inputTime\":\(input),\"error\":null,\"grade\":\"\(grade)\"}".utf8))
        }
        var calls = 0
        var state = EggSceneSnapshot(presentationElapsed: { host in calls += 1; return host - 100 }, route: try routeFixture())
        scene.configure(state); scene.render(at: 104)
        XCTAssertFalse(rock.isHidden); XCTAssertTrue(reward.isHidden)
        let previous = rock.position.x; scene.render(at: 104.01)
        XCTAssertLessThan(rock.position.x, previous, "Nodes move between store polls on the existing read-only clock")
        state.accepted = [0]; state.acceptedAction = try hit(0, 104, "perfect"); state.latestAction = try hit(nil, 104.2, "extra"); state.route = try routeFixture(hits: [state.acceptedAction!, state.latestAction!])
        scene.configure(state); scene.render(at: 104.24)
        XCTAssertFalse(rock.isHidden); XCTAssertEqual(rock.alpha, 0.04, accuracy: 0.0001)
        XCTAssertFalse(reward.isHidden); XCTAssertGreaterThan(player.position.y, 60)
        scene.render(at: 104.70)
        XCTAssertEqual(player.position.y, 51, accuracy: 2.001, "Old extra must not start a second bounce")
        for host in [Double.nan, .infinity, -.infinity, 103, 104.48, 105, 120.18] {
            scene.render(at: host); XCTAssertTrue(player.position.x.isFinite && player.position.y.isFinite)
            XCTAssertEqual(character.alpha, 1)
            XCTAssertEqual(scene.children.count, count); XCTAssertTrue(scene.childNode(withName: "player") === player)
        }
        scene.size = CGSize(width: 320, height: 240)
        XCTAssertEqual(scene.children.count, count, "Resize reuses the graph")
        scene.render(at: 104.08)
        XCTAssertEqual(player.position.y, 75.475, accuracy: 0.01, "Short scene scales the whole arc, not a clipped flat top")
        scene.render(at: 104.16)
        XCTAssertEqual(player.position.y, 88.6, accuracy: 0.01)
        scene.configure(EggSceneSnapshot(preparing: true)); scene.render(at: 104.24)
        XCTAssertTrue(rock.isHidden); XCTAssertTrue(reward.isHidden)
        let beforeDetach = calls; scene.detach(); scene.update(999)
        XCTAssertEqual(calls, beforeDetach); XCTAssertFalse(player.hasActions()); XCTAssertNil(player.physicsBody)
    }
    @MainActor
    func testActualSKViewCallbacksReuseGraphAndPauseDetachWithoutTimingAuthority() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800)), controller = UIViewController()
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 400)), scene = EggSpriteScene(size: CGSize(width: 400, height: 400))
        window.rootViewController = controller; controller.view.addSubview(view); window.makeKeyAndVisible()
        defer { scene.detach(); view.presentScene(nil); window.isHidden = true }
        view.isUserInteractionEnabled = false; view.ignoresSiblingOrder = true; view.preferredFramesPerSecond = 60; view.presentScene(scene)
        let epoch = PracticeStore.now(), count = scene.children.count
        scene.configure(EggSceneSnapshot(presentationElapsed: { 4 + $0 - epoch }))
        try await Task.sleep(nanoseconds: 3_000_000_000)
        XCTAssertGreaterThan(scene.callbackCount, 2, "Actual SKView must deliver update callbacks")
        XCTAssertEqual(scene.children.count, count)
        let observations = scene.diagnostics()
        print("GAME12_RENDER_DIAGNOSTICS " + String(data: try JSONSerialization.data(withJSONObject: observations, options: [.sortedKeys]), encoding: .utf8)!)
        // Callback intervals/render-method work are simulator observations,
        // not presented FPS, GPU time, input latency or a phone benchmark.
        scene.configure(EggSceneSnapshot(reduceMotion: true, presentationElapsed: { 4 + $0 - epoch }))
        let paused = scene.callbackCount; try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(scene.callbackCount, paused); XCTAssertTrue(view.isPaused)
        scene.detach(); view.presentScene(nil); XCTAssertNil(view.scene)
    }
    func testContinuousBackgroundAndFiniteImmediateJumpLandingWithoutReducedMotion() {
        let before = EggMotion.sample(elapsed: 11.9999, age: nil, grade: nil, reduceMotion: false)
        let after = EggMotion.sample(elapsed: 12.0001, age: nil, grade: nil, reduceMotion: false)
        XCTAssertLessThan(abs(after.backgroundX - before.backgroundX), 0.001, "Old 8s wrap must not teleport the background")
        XCTAssertGreaterThan(EggMotion.sample(elapsed: 5, age: 0.01, grade: .perfect, reduceMotion: false).height, 0)
        let landing = EggMotion.sample(elapsed: 5, age: 0.56, grade: .perfect, reduceMotion: false)
        XCTAssertEqual(landing.height, 0); XCTAssertGreaterThan(landing.scaleX, 1); XCTAssertLessThan(landing.scaleY, 1)
        let done = EggMotion.sample(elapsed: 5, age: 0.65, grade: .perfect, reduceMotion: false)
        XCTAssertEqual(done.height, 0); XCTAssertEqual(done.scaleX, 1); XCTAssertEqual(done.scaleY, 1)
        for age in [Double.nan, .infinity, -.infinity, -1, 0, 0.24, 0.48, 0.64, 1e100] {
            let motion = EggMotion.sample(elapsed: .nan, age: age, grade: .extra, reduceMotion: false)
            XCTAssertTrue(motion.height.isFinite && motion.scaleX.isFinite && motion.scaleY.isFinite && motion.angle.isFinite)
            let reduced = EggMotion.sample(elapsed: 5, age: age, grade: .perfect, reduceMotion: true)
            XCTAssertEqual(reduced.height, 0); XCTAssertEqual(reduced.scaleX, 1); XCTAssertEqual(reduced.scaleY, 1)
            XCTAssertEqual(reduced.angle, 0); XCTAssertEqual(reduced.landing, 0)
        }
    }
    func testExtraCannotInterruptOrExtendAcceptedJumpAndOldCallbacksCannotReplayIt() throws {
        func hit(_ target: Int?, _ input: Double, _ grade: String) throws -> TimingHit {
            let id = target.map(String.init) ?? "null"
            return try JSONDecoder().decode(TimingHit.self, from: Data("{\"targetID\":\(id),\"inputTime\":\(input),\"error\":null,\"grade\":\"\(grade)\"}".utf8))
        }
        let accepted = try hit(0, 42, "perfect"), extra = try hit(nil, 42.2, "extra")
        XCTAssertEqual(EggMotion.action(accepted: accepted, latest: extra, hostTime: 42.21), accepted)
        XCTAssertEqual(EggMotion.action(accepted: accepted, latest: extra, hostTime: 42.60), accepted)
        XCTAssertNil(EggMotion.action(accepted: accepted, latest: extra, hostTime: 42.65), "Old extra cannot replay after landing")
        let freshExtra = try hit(nil, 42.70, "extra")
        XCTAssertEqual(EggMotion.action(accepted: accepted, latest: freshExtra, hostTime: 42.71), freshExtra)
        XCTAssertEqual(EggMotion.action(accepted: accepted, latest: extra, hostTime: 41), extra)
        XCTAssertEqual(EggMotion.action(accepted: accepted, latest: extra, hostTime: .nan), extra)
        XCTAssertNil(EggMotion.action(accepted: accepted, latest: nil, hostTime: 100))
    }
    func testOpenTargetIsNeverReportedMissedAndAcceptedTargetCannotStumble() {
        XCTAssertNil(EggMissionPresentation.missed(elapsed: 4.43, accepted: []))
        XCTAssertEqual(EggMissionPresentation.missed(elapsed: 4.431, accepted: []), 0)
        XCTAssertNil(EggMissionPresentation.missed(elapsed: 4.7, accepted: [0]))
        XCTAssertNil(EggMissionPresentation.missed(elapsed: 4.95, accepted: []))
        XCTAssertEqual(EggMissionPresentation.missed(elapsed: 5.5, accepted: []), 1)
        for value in [Double.nan, .infinity, -.infinity, 1e100] { XCTAssertNil(EggMissionPresentation.missed(elapsed: value, accepted: [])) }
    }
    func testMatchedExtraAndMissHaveDifferentActionsAndReducedMotionDoesNotHop() {
        XCTAssertEqual(EggMissionPresentation.pose(elapsed: 5, hitAge: 0.2, grade: .perfect, recovering: false, reduceMotion: false), .jump)
        XCTAssertEqual(EggMissionPresentation.pose(elapsed: 5, hitAge: 0.2, grade: .extra, recovering: false, reduceMotion: false), .ready)
        XCTAssertEqual(EggMissionPresentation.pose(elapsed: 5, hitAge: nil, grade: nil, recovering: true, reduceMotion: false), .catchEgg)
        XCTAssertEqual(EggMissionPresentation.hop(hitAge: 0.24, grade: .perfect, reduceMotion: false), 74, accuracy: 0.001)
        XCTAssertEqual(EggMissionPresentation.hop(hitAge: 0.24, grade: .extra, reduceMotion: false), 12, accuracy: 0.001)
        XCTAssertEqual(EggMissionPresentation.hop(hitAge: 0.24, grade: .perfect, reduceMotion: true), 0)
        XCTAssertEqual(EggMissionPresentation.hop(hitAge: 0.5, grade: .perfect, reduceMotion: false), 0)
        XCTAssertEqual(EggMissionPresentation.pose(elapsed: .nan, hitAge: nil, grade: nil, recovering: false, reduceMotion: false), .ready)
    }
}

final class RhythmJumpPresentationTests: XCTestCase {
    private let pattern = RhythmPattern(stepsPerBeat: 1, steps: [.right, .left, .rest, .right])
    private func hit(_ id: Int?, _ grade: TimingGrade) -> TimingHit {
        let target = id.map(String.init) ?? "null"
        return try! JSONDecoder().decode(TimingHit.self, from: Data("{\"targetID\":\(target),\"inputTime\":42,\"error\":null,\"grade\":\"\(grade.rawValue)\"}".utf8))
    }
    func testPerfectStreakSkipsRestsAndBreaksOnUncrossedTargetOrExtra() {
        var reward = RhythmRewardPresentation()
        reward.record(hit(0, .perfect), accepted: true, pattern: pattern)
        reward.record(hit(1, .perfect), accepted: true, pattern: pattern)
        XCTAssertEqual(reward.perfectStreak, 2)
        reward.record(hit(3, .perfect), accepted: true, pattern: pattern)
        XCTAssertEqual(reward.perfectStreak, 3, "Rest at index 2 is not an action")
        reward.record(hit(nil, .extra), accepted: false, pattern: pattern)
        XCTAssertEqual(reward.perfectStreak, 0)
        reward.record(hit(5, .perfect), accepted: true, pattern: pattern)
        XCTAssertEqual(reward.perfectStreak, 1, "Uncrossed index 4 breaks the sequence")
        reward.record(hit(7, .late), accepted: true, pattern: pattern)
        XCTAssertEqual(reward.perfectStreak, 0)
        reward.record(hit(7, .perfect), accepted: false, pattern: pattern)
        XCTAssertEqual(reward.perfectStreak, 0, "Duplicate cannot make a reward")
    }
    func testRecoveryWaitsForFullAlignmentBufferAndDoesNotFlagRestOrMatched() {
        // At 60 BPM quarter notes: target 0 is at position 0. Existing 180 ms
        // window plus maximum 250 ms alignment means display waits beyond .43.
        func recovery(_ position: Double, _ accepted: Set<Int> = []) -> Int? {
            RhythmRewardPresentation.recoveryStep(position: position, bpm: 60, pattern: pattern, bars: 2, accepted: accepted)
        }
        XCTAssertNil(recovery(-1)); XCTAssertNil(recovery(0.43))
        XCTAssertEqual(recovery(0.431), 0)
        XCTAssertNil(recovery(0.431, [0]))
        XCTAssertNil(recovery(2.5, [0, 1]), "Rest cannot be a missed obstacle")
        XCTAssertEqual(recovery(3.5, [0, 1]), 3)
        XCTAssertNil(recovery(.nan)); XCTAssertNil(recovery(.infinity))
        XCTAssertNil(recovery(999))
    }
    func testMatchedPressLightsOnlyItsPlatformAndDuplicateDoesNotAdvance() {
        var scene = RhythmJumpPresentation()
        XCTAssertTrue(scene.record(hit(0, .perfect), pattern: pattern, bars: 2))
        XCTAssertEqual(scene.accepted, [0]); XCTAssertEqual(scene.landedStep, 0)
        XCTAssertFalse(scene.record(hit(0, .perfect), pattern: pattern, bars: 2))
        XCTAssertEqual(scene.accepted, [0]); XCTAssertEqual(scene.landedStep, 0)
    }
    func testEarlyAndLateAreMatchedButExtraNeverLightsOrAdvances() {
        var scene = RhythmJumpPresentation()
        XCTAssertTrue(scene.record(hit(1, .early), pattern: pattern, bars: 2))
        XCTAssertTrue(scene.record(hit(3, .late), pattern: pattern, bars: 2))
        XCTAssertFalse(scene.record(hit(nil, .extra), pattern: pattern, bars: 2))
        XCTAssertFalse(scene.record(hit(4, .extra), pattern: pattern, bars: 2))
        XCTAssertEqual(scene.accepted, [1, 3]); XCTAssertEqual(scene.landedStep, 3)
    }
    func testRestOutOfRangeAndInvalidTargetsCannotCreateSuccess() {
        var scene = RhythmJumpPresentation()
        for id in [-1, 2, 6, 8, 99] { XCTAssertFalse(scene.record(hit(id, .perfect), pattern: pattern, bars: 2)) }
        XCTAssertTrue(scene.accepted.isEmpty); XCTAssertEqual(scene.landedStep, -1)
    }
    func testCountInAndKnownQuarterNoteCues() {
        XCTAssertNil(RhythmJumpPresentation.cueStep(elapsed: 3.99, pattern: pattern, bpm: 60, bars: 2))
        XCTAssertEqual(RhythmJumpPresentation.cueStep(elapsed: 4, pattern: pattern, bpm: 60, bars: 2), 0)
        XCTAssertEqual(RhythmJumpPresentation.cueStep(elapsed: 5, pattern: pattern, bpm: 60, bars: 2), 1)
        XCTAssertEqual(RhythmJumpPresentation.cueStep(elapsed: 6, pattern: pattern, bpm: 60, bars: 2), 2)
        XCTAssertEqual(RhythmJumpPresentation.cueStep(elapsed: 12, pattern: pattern, bpm: 60, bars: 2), 7)
    }
    func testEighthNotesAndSafetyCatchAwardNothingForMisses() {
        let eighths = RhythmPattern(stepsPerBeat: 2, steps: Array(repeating: .right, count: 8))
        XCTAssertEqual(RhythmJumpPresentation.cueStep(elapsed: 4.5, pattern: eighths, bpm: 60, bars: 1), 1)
        let scene = RhythmJumpPresentation()
        XCTAssertEqual(scene.displayStep(cue: 3), 2)
        XCTAssertTrue(scene.accepted.isEmpty); XCTAssertEqual(scene.landedStep, -1)
        XCTAssertEqual(scene.displayStep(cue: nil), -1)
    }
    func testLatePriorTargetDoesNotMoveCharacterBackwardAndRestartClearsArt() {
        var scene = RhythmJumpPresentation()
        XCTAssertTrue(scene.record(hit(3, .early), pattern: pattern, bars: 2))
        XCTAssertTrue(scene.record(hit(1, .late), pattern: pattern, bars: 2))
        XCTAssertEqual(scene.landedStep, 3); XCTAssertEqual(scene.accepted, [1, 3])
        scene = RhythmJumpPresentation()
        XCTAssertEqual(scene.landedStep, -1); XCTAssertTrue(scene.accepted.isEmpty)
    }
    func testInvalidVisualInputsDoNotProduceCues() {
        XCTAssertNil(RhythmJumpPresentation.cueStep(elapsed: .nan, pattern: pattern, bpm: 60, bars: 2))
        XCTAssertNil(RhythmJumpPresentation.cueStep(elapsed: 4, pattern: pattern, bpm: 0, bars: 2))
        XCTAssertNil(RhythmJumpPresentation.cueStep(elapsed: 4, pattern: .init(stepsPerBeat: 1, steps: []), bpm: 60, bars: 2))
    }
}

final class RhythmRunnerPresentationTests: XCTestCase {
    func testQuarterNoteDistanceUsesFourBeatCountIn() {
        // At 60 BPM: 4 seconds count-in; note 0 at 4s, note 1 at 5s.
        XCTAssertEqual(RhythmRunnerPresentation.position(elapsed: 0, bpm: 60, stepsPerBeat: 1), -4)
        XCTAssertEqual(RhythmRunnerPresentation.position(elapsed: 4, bpm: 60, stepsPerBeat: 1), 0)
        XCTAssertEqual(RhythmRunnerPresentation.position(elapsed: 4.5, bpm: 60, stepsPerBeat: 1), 0.5)
        XCTAssertEqual(RhythmRunnerPresentation.position(elapsed: 5, bpm: 60, stepsPerBeat: 1), 1)
    }
    func testSubdivisionAndTempoChangeOnlyVisualSpacing() {
        // 120 BPM count-in ends at 2s; each eighth note is 0.25s.
        XCTAssertEqual(RhythmRunnerPresentation.position(elapsed: 2.25, bpm: 120, stepsPerBeat: 2), 1)
    }
    func testVisibleObstaclesSkipRestsAndEndAtActualCourseLength() {
        let pattern = RhythmPattern(stepsPerBeat: 1, steps: [.right, .rest, .left, .right])
        XCTAssertEqual(RhythmRunnerPresentation.visibleSteps(position: -4, pattern: pattern, bars: 2), [0])
        XCTAssertEqual(RhythmRunnerPresentation.visibleSteps(position: 0, pattern: pattern, bars: 2), [0, 2, 3, 4])
        XCTAssertEqual(RhythmRunnerPresentation.visibleSteps(position: 7, pattern: pattern, bars: 2), [6, 7])
        XCTAssertEqual(RhythmRunnerPresentation.visibleSteps(position: 10, pattern: pattern, bars: 2), [])
    }
    func testInvalidCameraInputsDoNotCreateObstacles() {
        let pattern = RhythmPattern(stepsPerBeat: 1, steps: [.right, .left, .rest, .right])
        for position in [Double.nan, Double.infinity, -999, 999] {
            XCTAssertEqual(RhythmRunnerPresentation.visibleSteps(position: position, pattern: pattern, bars: 1), [])
        }
        XCTAssertEqual(RhythmRunnerPresentation.visibleSteps(position: 0, pattern: pattern, bars: 0), [])
        XCTAssertEqual(RhythmRunnerPresentation.visibleSteps(position: 0, pattern: .init(stepsPerBeat: 1, steps: []), bars: 1), [])
        XCTAssertEqual(RhythmRunnerPresentation.position(elapsed: .nan, bpm: 60, stepsPerBeat: 1), -4)
    }
}

final class PlatformJourneyTests: XCTestCase {
    func testRealEarlyLateDuplicateAndExtraOnlyAdvanceMatchedSteps() throws {
        let fixture = try routeFixture()
        var session = try TimingSession(targets: fixture.targets)
        session.tap(at: 103.90); session.tap(at: 103.91); session.tap(at: 105.12)
        XCTAssertEqual(session.hits.map(\.grade), [.early, .extra, .late])
        let route = try routeFixture(hits: session.hits)
        XCTAssertEqual(route.journeyHits.count, 2)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 3.89, reduced: false).step, 0)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 4.14, reduced: false).step, 0.5, accuracy: 1e-8, "Reviewed 0.48s flight: halfway at0.24s")
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 4.38, reduced: false).step, 1, accuracy: 1e-8)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 5.36, reduced: false).step, 1.5, accuracy: 1e-8)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 5.60, reduced: false).step, 2, accuracy: 1e-8)
        let duplicate = try routeFixture(hits: session.hits + [session.hits[0]])
        XCTAssertEqual(duplicate.journeyHits.count, 2)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: duplicate, elapsed: 20, reduced: false).step, 2)
    }
    func testMissExpiresThenFallsAndReturnsWithoutForwardTravel() throws {
        let empty = try routeFixture()
        XCTAssertEqual(PlatformJourneyFrame.sample(route: empty, elapsed: 4.18, reduced: false).fall, 0)
        let bottom = PlatformJourneyFrame.sample(route: empty, elapsed: 4.42, reduced: false)
        XCTAssertEqual(bottom.step, 0); XCTAssertEqual(bottom.camera, 0)
        XCTAssertEqual(bottom.fall, 0.75, accuracy: 1e-8, "Gravity phase ends at .24s; catch then brakes to full depth")
        XCTAssertEqual(PlatformJourneyFrame.sample(route: empty, elapsed: 4.781, reduced: false).fall, 0)
        let aligned = try routeFixture(alignment: 0.20)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: aligned, elapsed: 4.38, reduced: false).fall, 0)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: aligned, elapsed: 4.62, reduced: false).fall, 0.75, accuracy: 1e-8)
        let resumed = try routeFixture(accepted: [1])
        XCTAssertEqual(PlatformJourneyFrame.sample(route: resumed, elapsed: 5.24, reduced: false).step, 0.5, accuracy: 1e-8)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: resumed, elapsed: 5.24, reduced: false).fall, 0)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: empty, elapsed: 20, reduced: false).step, 0)
    }
    func testCameraSharesFlightAndAbsoluteFrameSkipsReachSameEndpoint() throws {
        let route = try routeFixture(accepted: [0,1])
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 5.24, reduced: false).camera, 0.35, accuracy: 1e-8)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 5.48, reduced: false).camera, 0.70, accuracy: 1e-8)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: 5.80, reduced: false).camera, 0.70, accuracy: 1e-8)
        let all = try routeFixture(accepted: Set(0..<16))
        let skipped = PlatformJourneyFrame.sample(route: all, elapsed: 20, reduced: false)
        XCTAssertEqual(skipped.step, 16); XCTAssertEqual(skipped.camera, 14.7, accuracy: 1e-8)
        for elapsed in stride(from: 0.0, through: 20, by: 0.017) {
            let value = PlatformJourneyFrame.sample(route: all, elapsed: elapsed, reduced: false)
            XCTAssertTrue(value.step.isFinite && value.camera.isFinite)
        }
        XCTAssertEqual(PlatformJourneyFrame.sample(route: all, elapsed: 20, reduced: false).step, skipped.step)
        XCTAssertLessThan(abs(PlatformJourneyFrame.sample(route: route, elapsed: 5.6401, reduced: false).camera - PlatformJourneyFrame.sample(route: route, elapsed: 5.6399, reduced: false).camera), 0.001)
    }
    func testReducedMotionAndMissingOrInvalidClockHaveNoFlightFallOrFabricatedTravel() throws {
        let route = try routeFixture(accepted: [0,1])
        let reduced = PlatformJourneyFrame.sample(route: route, elapsed: 5.12, reduced: true)
        XCTAssertEqual(reduced.step, 2); XCTAssertEqual(reduced.camera, 0.7, accuracy: 1e-8); XCTAssertEqual(reduced.fall, 0)
        for time in [Double.nan, .infinity, -.infinity, -1] {
            let value = PlatformJourneyFrame.sample(route: route, elapsed: time, reduced: false)
            XCTAssertEqual(value.step, 0); XCTAssertEqual(value.camera, 0); XCTAssertEqual(value.fall, 0)
        }
        XCTAssertEqual(PlatformJourneyFrame.sample(route: nil, elapsed: 20, reduced: false).step, 0)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: try routeFixture(), elapsed: 4.42, reduced: true).fall, 0)
    }
    @MainActor
    func testActualThreeThemeSceneMovesAcrossSeparatedPlatformsThenSafelyResets() throws {
        for theme in RunnerTheme.allCases {
            let scene = EggSpriteScene(size: CGSize(width: 400, height: 500))
            let player = try XCTUnwrap(scene.childNode(withName: "player"))
            let platform = try XCTUnwrap(scene.childNode(withName: "platform0") as? SKSpriteNode)
            let next = try XCTUnwrap(scene.childNode(withName: "platform1") as? SKSpriteNode)
            let count = scene.children.count
            scene.configure(EggSceneSnapshot(elapsed: 3.9, theme: theme, route: try routeFixture(), platformJourney: true))
            XCTAssertEqual(player.position.x, 80, accuracy: 1e-8)
            XCTAssertEqual(next.position.x - platform.position.x, 108, accuracy: 1e-8)
            XCTAssertLessThan(platform.size.width, next.position.x - platform.position.x, "Visible gap is a playable space, not continuous ground")
            XCTAssertTrue(try XCTUnwrap(scene.childNode(withName: "rock0")).isHidden)
            let background = try XCTUnwrap(scene.childNode(withName: "backdrop") as? SKSpriteNode)
            let sourceSize = try XCTUnwrap(background.texture).size()
            XCTAssertEqual(background.size.width / background.size.height, sourceSize.width / sourceSize.height, accuracy: 1e-6, "SpriteKit float-size rounding must stay below one part per million of native art proportions")
            let route = try routeFixture(accepted: [0])
            scene.configure(EggSceneSnapshot(elapsed: 4.24, theme: theme, route: route, platformJourney: true))
            XCTAssertEqual(player.position.x, 134, accuracy: 1e-8)
            XCTAssertGreaterThan(player.position.y, 220)
            scene.configure(EggSceneSnapshot(elapsed: 4.48, theme: theme, route: route, platformJourney: true))
            XCTAssertEqual(player.position.x, 188, accuracy: 1e-8)
            XCTAssertEqual(player.position.y, 155, accuracy: 1e-8)
            scene.configure(EggSceneSnapshot(elapsed: 4.50, theme: theme, route: try routeFixture(), platformJourney: true))
            XCTAssertLessThan(player.position.y, 100)
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "safetyCatch")).isHidden)
            scene.configure(EggSceneSnapshot(elapsed: 4.781, theme: theme, route: try routeFixture(), platformJourney: true))
            XCTAssertEqual(player.position.x, 80, accuracy: 1e-8); XCTAssertEqual(player.position.y, 155, accuracy: 1e-8)
            scene.configure(EggSceneSnapshot(elapsed: 0, preparing: true, theme: theme, platformJourney: true))
            XCTAssertEqual(player.position.x, 80, accuracy: 1e-8)
            XCTAssertEqual(scene.children.count, count); XCTAssertNil(player.physicsBody); XCTAssertFalse(player.hasActions())
            scene.configure(EggSceneSnapshot(elapsed:route.duration,finishedPassed:true,theme:theme,route:route,platformJourney:true))
            XCTAssertTrue(try XCTUnwrap(scene.childNode(withName:"destination")).isHidden,"A passing flag cannot fabricate15 unplayed islands")
            XCTAssertEqual(player.position.x,188,accuracy:1e-8)
            scene.configure(EggSceneSnapshot(elapsed: 20, finishedPassed: false, theme: theme, route: try routeFixture(), platformJourney: true))
            XCTAssertTrue(try XCTUnwrap(scene.childNode(withName: "destination")).isHidden, "Only actual passed flag can show arriving at the end")
        }
    }
}

final class JourneyMotionRegressionTests: XCTestCase {
    func testScreenTravelNeverSlidesBackAfterLandingOnAnyMatchedBeat() throws {
        let all = try routeFixture(accepted: Set(0..<16))
        var previous = 0.0
        for tick in 0...4800 {
            let frame = PlatformJourneyFrame.sample(route: all, elapsed: Double(tick) / 240, reduced: false)
            let screen = frame.step - frame.camera
            XCTAssertGreaterThanOrEqual(screen + 1e-10, previous, "Camera may not pull a grounded companion backwards")
            XCTAssertLessThanOrEqual(screen, 1.3 + 1e-10)
            previous = screen
        }
        for beat in 0..<16 {
            let landed = PlatformJourneyFrame.sample(route: all, elapsed: Double(4 + beat) + 0.48, reduced: false)
            let settled = PlatformJourneyFrame.sample(route: all, elapsed: Double(4 + beat) + 0.80, reduced: false)
            XCTAssertEqual(landed.step - landed.camera, settled.step - settled.camera, accuracy: 1e-10)
        }
    }
    func testApprovedFlightHasZeroEndpointVelocityAndAcceleration() {
        XCTAssertEqual(JourneyMotion.arc(0.5), 1)
        XCTAssertEqual(JourneyMotion.progress(0.5), 0.5)
        let h = 1e-5
        for endpoint in [0.0, 1.0] {
            let left = JourneyMotion.arc(endpoint - h), center = JourneyMotion.arc(endpoint), right = JourneyMotion.arc(endpoint + h)
            XCTAssertLessThan(abs((right - left) / (2 * h)), 1e-6, "No sudden vertical velocity stop at touchdown")
            XCTAssertLessThan(abs((right - 2 * center + left) / (h * h)), 0.002, "No endpoint acceleration step")
        }
        for invalid in [Double.nan, .infinity, -.infinity, -1, 2] { XCTAssertEqual(JourneyMotion.arc(invalid), 0) }
    }
    @MainActor
    func testFlightAndMissKeepOneOpaqueRegisteredCharacterInEveryTheme() throws {
        for theme in RunnerTheme.allCases {
            let scene = EggSpriteScene(size: CGSize(width: 400, height: 500))
            let player = try XCTUnwrap(scene.childNode(withName: "player"))
            let character = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
            for route in [try routeFixture(accepted: [0,1]), try routeFixture()] {
                for time in stride(from: 3.9, through: 6.0, by: 1.0 / 120) {
                    scene.configure(EggSceneSnapshot(elapsed: time, theme: theme, route: route, platformJourney: true))
                    XCTAssertEqual(player.children.count, 1, "No second silhouette or ghost eyes in flight/recovery")
                    XCTAssertEqual(character.alpha, 1)
                    XCTAssertNotNil(character.texture)
                    XCTAssertTrue(player.position.x.isFinite && player.position.y.isFinite)
                }
            }
        }
    }
    @MainActor
    func testRealPlatformSKViewUsesOnlyDisplayCallbacksForLiveSnapshotUpdates() async throws {
        for theme in RunnerTheme.allCases {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800)), controller = UIViewController()
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 500)), scene = EggSpriteScene(size: CGSize(width: 400, height: 500))
            window.rootViewController = controller; controller.view.addSubview(view); window.makeKeyAndVisible()
            defer { scene.detach(); view.presentScene(nil); window.isHidden = true }
            view.preferredFramesPerSecond = 60; view.presentScene(scene)
            let epoch = PracticeStore.now() - 4.10
            let targets = (0..<16).map { TimingTarget(id: $0, time: epoch + 4 + Double($0), stroke: .right) }
            var session = try TimingSession(targets: targets); session.tap(at: epoch + 4)
            let route = try XCTUnwrap(RunnerRoute(targets: targets, hits: session.hits, epoch: epoch, endTime: epoch + 20.18, alignment: 0))
            let state = EggSceneSnapshot(presentationElapsed: { $0 - epoch }, theme: theme, route: route, platformJourney: true)
            scene.configure(state)
            let count = scene.renderCount, nodes = scene.children.count
            for _ in 0..<12 { scene.configure(state) }
            XCTAssertEqual(scene.renderCount, count, "Elapsed publishes cannot introduce a second live render loop")
            try await Task.sleep(nanoseconds: 900_000_000)
            XCTAssertGreaterThan(scene.callbackCount, 2)
            XCTAssertGreaterThan(scene.renderCount, count)
            XCTAssertEqual(scene.children.count, nodes)
            scene.configure(EggSceneSnapshot(reduceMotion: true, presentationElapsed: { $0 - epoch }, theme: theme, route: route, platformJourney: true))
            let paused = scene.callbackCount
            try await Task.sleep(nanoseconds: 100_000_000)
            XCTAssertEqual(scene.callbackCount, paused); XCTAssertTrue(view.isPaused)
            XCTAssertEqual(try XCTUnwrap(scene.childNode(withName: "player")).children.count, 1)
            // Native SpriteKit specimens for human motion/art inspection.
            // These explicit matcher fixtures are not UI touches or phone FPS.
            let specimenRoute = try routeFixture(accepted: [0, 1])
            for elapsed in [4.012, 4.10, 4.252, 4.42, 4.48, 4.56, 5.252, 5.48] {
                scene.configure(EggSceneSnapshot(elapsed: elapsed, theme: theme, route: specimenRoute, platformJourney: true))
                let texture = try XCTUnwrap(view.texture(from: scene))
                let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
                attachment.name = "GAME21 native specimen \(theme.rawValue) \(elapsed)"
                attachment.lifetime = .keepAlways; add(attachment)
            }
        }
    }
}

final class DenseCharacterMotionTests: XCTestCase {
    func testReviewed24To25PoseCadenceAndBoundariesWithoutDependingOnDisplayRate() {
        // Independent contract: twelve poses in .5s, twelve in .48s, four in .16s.
        for (index, time) in [4.02,4.06,4.10,4.145,4.185,4.225,4.27,4.31,4.35,4.395,4.435,4.475].enumerated() {
            XCTAssertEqual(DenseAnimationFrame.sample(elapsed: time, age: nil, reduceMotion: false, stationary: false), index)
        }
        for (index, age) in [0.02,0.06,0.10,0.14,0.18,0.22,0.26,0.30,0.34,0.38,0.42,0.46].enumerated() {
            XCTAssertEqual(DenseAnimationFrame.sample(elapsed: 4 + age, age: age, reduceMotion: false, stationary: true), 12 + index)
        }
        for (index, age) in [0.50,0.54,0.58,0.62].enumerated() {
            XCTAssertEqual(DenseAnimationFrame.sample(elapsed: 4 + age, age: age, reduceMotion: false, stationary: true), 24 + index)
        }
        XCTAssertEqual(DenseAnimationFrame.sample(elapsed: 4.499999, age: nil, reduceMotion: false, stationary: false), 11)
        XCTAssertEqual(DenseAnimationFrame.sample(elapsed: 4.500001, age: nil, reduceMotion: false, stationary: false), 0)
        XCTAssertEqual(DenseAnimationFrame.sample(elapsed: 4.48, age: 0.48, reduceMotion: false, stationary: true), 24)
        XCTAssertEqual(DenseAnimationFrame.sample(elapsed: 4.64, age: 0.64, reduceMotion: false, stationary: true), 28)
        for time in [Double.nan, .infinity, -.infinity, -1, 100, Double.greatestFiniteMagnitude] {
            XCTAssertEqual(DenseAnimationFrame.sample(elapsed: time, age: 0.16, reduceMotion: false, stationary: false), 28)
        }
        for time in [4.01,4.3,4.6,5.01] {
            XCTAssertEqual(DenseAnimationFrame.sample(elapsed: time, age: 0.16, reduceMotion: true, stationary: false), 28)
        }
    }
    @MainActor
    func testThreeLoadedPacksAndMissingArtFailureUseRegisteredCells() throws {
        XCTAssertFalse(DenseCharacterAtlas.Pack(name: "not-an-asset", referenceHeight: 200, anchors: Array(repeating: .zero, count: 32)).isValid)
        for theme in RunnerTheme.allCases {
            let pack = try XCTUnwrap(DenseCharacterAtlas.packs[theme])
            XCTAssertTrue(pack.isValid); XCTAssertEqual(pack.textures.count, 32)
            XCTAssertEqual(Set(pack.textures.map { ObjectIdentifier($0) }).count, 32)
            for (index, texture) in pack.textures.enumerated() {
                XCTAssertGreaterThan(texture.size().width, 100)
                XCTAssertGreaterThan(texture.size().height, 100)
                XCTAssertTrue(pack.anchors[index].x.isFinite && pack.anchors[index].y.isFinite)
                XCTAssertGreaterThan(pack.referenceHeight, 100)
            }
        }
    }
    @MainActor
    func testNativeSceneActuallyUsesAllFlightLandingAndRunPosesAndReadyWhileStanding() throws {
        for theme in RunnerTheme.allCases {
            let scene = EggSpriteScene(size: CGSize(width: 400, height: 500))
            let player = try XCTUnwrap(scene.childNode(withName: "player"))
            let character = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
            let pack = try XCTUnwrap(DenseCharacterAtlas.packs[theme])
            let route = try routeFixture(accepted: [0,1])
            for (index, age) in [0.02,0.06,0.10,0.14,0.18,0.22,0.26,0.30,0.34,0.38,0.42,0.46,0.50,0.54,0.58,0.62].enumerated() {
                scene.configure(EggSceneSnapshot(elapsed: 4 + age, theme: theme, route: route, platformJourney: true))
                XCTAssertTrue(character.texture === pack.textures[12 + index], "New in-between art must be used, not only supplied in assets")
                XCTAssertEqual(player.children.count, 1); XCTAssertEqual(character.alpha, 1)
            }
            for (index, time) in [4.02,4.06,4.10,4.145,4.185,4.225,4.27,4.31,4.35,4.395,4.435,4.475].enumerated() {
                scene.configure(EggSceneSnapshot(elapsed: time, theme: theme, route: try routeFixture()))
                XCTAssertTrue(character.texture === pack.textures[index])
            }
            scene.configure(EggSceneSnapshot(elapsed: 4.8, theme: theme, route: route, platformJourney: true))
            XCTAssertTrue(character.texture === pack.textures[28], "Standing keeps its registered base texture; grounded shader supplies idle motion, not running")
            scene.configure(EggSceneSnapshot(elapsed: 4.2, reduceMotion: true, theme: theme, route: route, platformJourney: true))
            XCTAssertTrue(character.texture === pack.textures[28])
            XCTAssertEqual(player.xScale, 1); XCTAssertEqual(player.yScale, 1)
        }
    }
    @MainActor
    func testDisplayCallbacksAdvanceDenseFramesAndCaptureNativeSequences() async throws {
        for theme in RunnerTheme.allCases {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800)), controller = UIViewController()
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 500)), scene = EggSpriteScene(size: CGSize(width: 400, height: 500))
            window.rootViewController = controller; controller.view.addSubview(view); window.makeKeyAndVisible()
            defer { scene.detach(); view.presentScene(nil); window.isHidden = true }
            view.preferredFramesPerSecond = 60; view.presentScene(scene)
            let route = try routeFixture(accepted: [0,1]), epoch = PracticeStore.now() - 4
            scene.configure(EggSceneSnapshot(presentationElapsed: { $0 - epoch }, theme: theme, route: route, platformJourney: true))
            let character = try XCTUnwrap(scene.childNode(withName: "player/characterPrimary") as? SKSpriteNode)
            var observed = Set<ObjectIdentifier>()
            for _ in 0..<100 {
                try await Task.sleep(nanoseconds: 8_000_000)
                observed.insert(ObjectIdentifier(try XCTUnwrap(character.texture)))
            }
            XCTAssertGreaterThan(observed.count, 8, "Live callbacks must actually expose denser poses, not a static actor or sparse fallback")
            scene.configure(EggSceneSnapshot(suspended: true, presentationElapsed: { $0 - epoch }, theme: theme, route: route, platformJourney: true))
            let count = scene.callbackCount, stoppedTexture = character.texture
            try await Task.sleep(nanoseconds: 100_000_000)
            XCTAssertEqual(scene.callbackCount, count); XCTAssertTrue(character.texture === stoppedTexture)
            // Full native sequential specimens, synthetic matcher fixture; not UI taps/physical FPS.
            let runSamples: [(String, Int, Double)] = (0..<12).map { ("run", $0, 4 + (Double($0)+0.5)/24) }
            let jumpSamples: [(String, Int, Double)] = (0..<16).map { ("jump", $0, 4 + (Double($0)+0.5)/25) }
            let samples = runSamples + jumpSamples
            for (phase,index,time) in samples {
                scene.configure(EggSceneSnapshot(elapsed: time, theme: theme, route: phase == "run" ? try routeFixture() : route, platformJourney: phase != "run"))
                let texture = try XCTUnwrap(view.texture(from: scene))
                let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
                attachment.name = "GAME22 \(theme.rawValue) \(phase) \(index)"
                attachment.lifetime = .keepAlways; add(attachment)
            }
        }
    }
}


final class JourneyFallRecoveryTests: XCTestCase {
    func testReviewedGravityCatchReturnDepthsAndContinuousVelocity() {
        // Independent art-direction contract: quadratic gravity, braking catch,
        // separate carrier return; never mirror the approved jump arc.
        let samples: [(Double, Double, JourneyRecovery.Phase)] = [
            (0.12, 0.1875, .falling), (0.24, 0.75, .catching),
            (0.28, 0.9375, .catching), (0.32, 1, .returning),
            (0.46, 0.5, .returning), (0.60, 0, .idle)]
        for (age, depth, phase) in samples {
            let value = JourneyRecovery.sample(age: age)
            XCTAssertEqual(value.depth, depth, accuracy: 1e-9); XCTAssertEqual(value.phase, phase)
        }
        let h = 1e-5
        for seam in [0.0, 0.24, 0.32, 0.60] {
            let left = JourneyRecovery.sample(age: seam - h).depth
            let center = JourneyRecovery.sample(age: seam).depth
            let right = JourneyRecovery.sample(age: seam + h).depth
            XCTAssertLessThan(abs(right - left), 0.001)
            XCTAssertEqual((center - left) / h, (right - center) / h, accuracy: 0.003,
                           "No teleport or velocity snap at catch/return contact")
        }
        XCTAssertGreaterThan(JourneyRecovery.sample(age: 0.20).depth - JourneyRecovery.sample(age: 0.16).depth,
                             JourneyRecovery.sample(age: 0.08).depth - JourneyRecovery.sample(age: 0.04).depth)
        var prior = 0.0
        for tick in 0...320 {
            let value = JourneyRecovery.sample(age: Double(tick) / 1000)
            XCTAssertGreaterThanOrEqual(value.depth + 1e-10, prior)
            XCTAssertTrue((0...0.5).contains(value.drift)); prior = value.depth
        }
        for invalid in [Double.nan, .infinity, -.infinity, -1, 0, 0.60, 99] {
            XCTAssertEqual(JourneyRecovery.sample(age: invalid).phase, .idle)
        }
        XCTAssertNotEqual(JourneyRecovery.sample(age: 0.01).instruction, "接回來了，下一拍再跳！")
    }
    func testActualMissExtraAlignmentAndEarliestNextPressDoNotManufactureTravelOrSnap() throws {
        let fixture = try routeFixture()
        var session = try TimingSession(targets: fixture.targets)
        session.tap(at: 104.40) // Actual extra: expired first beat, too early for second.
        let failed = try routeFixture(hits: session.hits)
        XCTAssertEqual(session.hits.first?.grade, .extra)
        for time in [4.20, 4.42, 4.50, 4.64, 4.78] {
            let frame = PlatformJourneyFrame.sample(route: failed, elapsed: time, reduced: false)
            XCTAssertEqual(frame.step, 0); XCTAssertEqual(frame.camera, 0)
        }
        // A valid early second beat begins after recovery finishes at4.78.
        session.tap(at: 104.83)
        XCTAssertEqual(session.hits.last?.grade, .early)
        let resumed = try routeFixture(hits: session.hits)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: resumed, elapsed: 4.829999, reduced: false).fall, 0)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: resumed, elapsed: 4.830001, reduced: false).step, 0, accuracy: 1e-8)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: resumed, elapsed: 5.31, reduced: false).step, 1, accuracy: 1e-8)
        XCTAssertEqual(failed.accepted.count, 0); XCTAssertEqual(resumed.accepted.count, 1)
        for beat in 0..<16 {
            let route = try routeFixture(alignment: 0.20)
            let value = PlatformJourneyFrame.sample(route: route, elapsed: Double(4 + beat) + 0.70, reduced: false)
            XCTAssertEqual(value.fall, 1, accuracy: 1e-8); XCTAssertEqual(value.step, 0)
            XCTAssertEqual(PlatformJourneyFrame.sample(route: route, elapsed: Double(4 + beat) + 0.981, reduced: false).fall, 0)
        }
        XCTAssertEqual(PlatformJourneyFrame.sample(route: failed, elapsed: 4.50, reduced: true).recovery.phase, .idle)
    }
    @MainActor
    func testAllThemesCatchBelowBeforeContactUseFallPosesAndReturnWithoutGhostOrNodeChurn() throws {
        for theme in RunnerTheme.allCases {
            let scene = EggSpriteScene(size: CGSize(width: 400, height: 500))
            let player = try XCTUnwrap(scene.childNode(withName: "player"))
            let actor = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
            let catchNode = try XCTUnwrap(scene.childNode(withName: "safetyCatch"))
            let pack = try XCTUnwrap(DenseCharacterAtlas.packs[theme]), route = try routeFixture()
            let count = scene.children.count
            // Reviewed six existing descending poses, then four contact poses.
            for (age,index) in [(0.02,18),(0.06,19),(0.10,20),(0.14,21),(0.18,22),(0.22,23),
                                (0.26,24),(0.30,25),(0.34,26),(0.38,27),(0.46,28)] {
                scene.configure(EggSceneSnapshot(elapsed: 4.18 + age, theme: theme, route: route, platformJourney: true))
                XCTAssertTrue(actor.texture === pack.textures[index]); XCTAssertEqual(actor.alpha, 1)
                XCTAssertEqual(player.children.count, 1); XCTAssertEqual(scene.children.count, count)
                XCTAssertFalse(catchNode.isHidden)
                XCTAssertLessThan(try XCTUnwrap(scene.childNode(withName: "beatMarker")).zPosition, player.zPosition, "Upcoming cue must not paint over a falling face")
                if age < 0.24 { XCTAssertLessThan(catchNode.position.y + 6, player.position.y) }
                else { XCTAssertEqual(catchNode.position.y + 6, player.position.y, accuracy: 1e-8) }
            }
            scene.configure(EggSceneSnapshot(elapsed: 4.50, theme: theme, route: route, platformJourney: true))
            let caught = player.position
            var session = try TimingSession(targets: route.targets); session.tap(at: 104.40)
            scene.configure(EggSceneSnapshot(elapsed: 4.50, theme: theme, route: try routeFixture(hits: session.hits), platformJourney: true))
            XCTAssertEqual(player.position, caught, "Extra text feedback cannot shake a caught actor off its carrier")
            scene.configure(EggSceneSnapshot(elapsed: 4.80, theme: theme, route: route, platformJourney: true))
            XCTAssertEqual(player.position.x, 80, accuracy: 1e-8); XCTAssertEqual(player.position.y, 155, accuracy: 1e-8)
            XCTAssertTrue(catchNode.isHidden); XCTAssertTrue(actor.texture === pack.textures[28])
            for state in [EggSceneSnapshot(elapsed: 4.46, reduceMotion: true, theme: theme, route: route, platformJourney: true),
                          EggSceneSnapshot(elapsed: 0, preparing: true, theme: theme, platformJourney: true),
                          EggSceneSnapshot(elapsed: 4.50, finishedPassed: false, theme: theme, route: route, platformJourney: true)] {
                scene.configure(state); XCTAssertTrue(catchNode.isHidden)
                XCTAssertEqual(player.position.y, 155, accuracy: 1e-8); XCTAssertEqual(player.zRotation, 0)
            }
        }
    }
    @MainActor
    func testLiveFallCallbacksAndNativeContinuousSpecimensInThreeThemes() async throws {
        for theme in RunnerTheme.allCases {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800)), controller = UIViewController()
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 500)), scene = EggSpriteScene(size: CGSize(width: 400, height: 500))
            window.rootViewController = controller; controller.view.addSubview(view); window.makeKeyAndVisible()
            defer { scene.detach(); view.presentScene(nil); window.isHidden = true }
            view.preferredFramesPerSecond = 60; view.presentScene(scene)
            let route = try routeFixture(), epoch = PracticeStore.now() - 4.17
            scene.configure(EggSceneSnapshot(presentationElapsed: { $0 - epoch }, theme: theme, route: route, platformJourney: true))
            let player = try XCTUnwrap(scene.childNode(withName: "player"))
            let actor = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
            var textures = Set<ObjectIdentifier>(), lowest = player.position.y
            for _ in 0..<46 {
                try await Task.sleep(nanoseconds: 16_000_000)
                lowest = min(lowest, player.position.y); textures.insert(ObjectIdentifier(try XCTUnwrap(actor.texture)))
            }
            XCTAssertGreaterThan(textures.count, 5); XCTAssertLessThan(lowest, 100)
            XCTAssertEqual(player.position.y, 155, accuracy: 1e-6)
            scene.configure(EggSceneSnapshot(suspended: true, presentationElapsed: { $0 - epoch }, theme: theme, route: route, platformJourney: true))
            let callbacks = scene.callbackCount
            try await Task.sleep(nanoseconds: 80_000_000)
            XCTAssertEqual(scene.callbackCount, callbacks)
            // Native full-scene 60Hz time samples, not measured physical60fps.
            for index in 0...36 {
                scene.configure(EggSceneSnapshot(elapsed: 4.18 + Double(index) / 60, theme: theme, route: route, platformJourney: true))
                let texture = try XCTUnwrap(view.texture(from: scene))
                let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
                attachment.name = "GAME23 \(theme.rawValue) fall \(String(format: "%02d", index))"
                attachment.lifetime = .keepAlways; add(attachment)
            }
            // Changed artwork/geometry at compact and tall sizes, both appearances.
            for height in [240.0,650.0] {
                scene.size = CGSize(width: 320, height: height)
                for style in [UIUserInterfaceStyle.light,.dark] {
                    view.overrideUserInterfaceStyle = style
                    scene.configure(EggSceneSnapshot(elapsed: 4.46, theme: theme, route: route, platformJourney: true))
                    XCTAssertTrue(player.position.x.isFinite && player.position.y.isFinite)
                    XCTAssertGreaterThan(player.position.y, 0)
                    let texture = try XCTUnwrap(view.texture(from: scene))
                    let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
                    attachment.name = "GAME23 \(theme.rawValue) height\(height) style\(style.rawValue)"
                    attachment.lifetime = .keepAlways; add(attachment)
                }
            }
        }
    }
}

final class JourneyRecoveryExpressionTests: XCTestCase {
    func testReviewedEmotionsAndResetBoundariesDoNotExtendRecovery() {
        let reviewed: [(Double, RecoveryExpression)] = [(0,.neutral),(0.02,.surprised),(0.239,.surprised),
            (0.24,.braced),(0.319,.braced),(0.32,.relieved),(0.399,.relieved),
            (0.40,.ready),(0.599,.ready),(0.60,.neutral),(1,.neutral)]
        for (age, expression) in reviewed {
            let recovery = JourneyRecovery.sample(age: age)
            XCTAssertEqual(RecoveryExpression.sample(recovery), expression)
            XCTAssertEqual(RecoveryExpression.sample(recovery, reduced: true), .neutral)
        }
        for invalid in [Double.nan,.infinity,-.infinity,-0.1] {
            XCTAssertEqual(RecoveryExpression.sample(.sample(age: invalid)), .neutral)
        }
        // Another miss repeats the same feedback; no expression carries into a new beat.
        XCTAssertEqual(RecoveryExpression.sample(.sample(age: 0.02)), .surprised)
    }
    @MainActor
    func testThreeThemeFaceShadersKeepOriginalBodyAndClearAfterMissAndStop() throws {
        let route = try routeFixture()
        for theme in RunnerTheme.allCases {
            let scene = EggSpriteScene(size: CGSize(width:400,height:500))
            let actor = try XCTUnwrap(scene.childNode(withName:"player/characterPrimary") as? SKSpriteNode)
            let body = try XCTUnwrap(DenseCharacterAtlas.packs[theme])
            let expressions = try XCTUnwrap(RecoveryExpressionAtlas.packs[theme])
            XCTAssertTrue(expressions.isValid)
            let count=scene.children.count
            for (age,pose) in [(0.02,18),(0.06,19),(0.10,20),(0.14,21),(0.18,22),(0.22,23),
                               (0.26,24),(0.30,25),(0.34,26),(0.38,27),(0.46,28)] {
                scene.configure(EggSceneSnapshot(elapsed:4.18+age,theme:theme,route:route,platformJourney:true))
                XCTAssertTrue(actor.texture === body.textures[pose], "The accepted body pack remains the texture authority")
                XCTAssertTrue(actor.shader === expressions.shaders[pose]); XCTAssertEqual(actor.alpha,1)
                XCTAssertEqual(scene.children.count,count)
            }
            scene.configure(EggSceneSnapshot(elapsed:4.80,theme:theme,route:route,platformJourney:true))
            XCTAssertNotNil(actor.shader, "Recovery hands off to grounded motion")
            XCTAssertFalse(expressions.shaders.contains { $0 === actor.shader }, "No stuck recovery expression on grounded idle")
            for snapshot in [EggSceneSnapshot(elapsed:4.46,reduceMotion:true,theme:theme,route:route,platformJourney:true),
                EggSceneSnapshot(elapsed:0,preparing:true,theme:theme,platformJourney:true),
                EggSceneSnapshot(elapsed:4.46,finishedPassed:false,theme:theme,route:route,platformJourney:true),
                EggSceneSnapshot(elapsed:4.46,theme:theme,platformJourney:true)] {
                scene.configure(snapshot); XCTAssertNil(actor.shader, "No stuck facial reaction after reset/reduction/finish/missing route")
            }
            XCTAssertNil(RecoveryExpressionAtlas.shader(theme:theme,pose:17))
            XCTAssertNil(RecoveryExpressionAtlas.shader(theme:theme,pose:29))
            XCTAssertFalse(RecoveryExpressionAtlas.Pack(name:"MissingExpressions",face:SIMD4(0,0,1,1)).isValid)
        }
    }
    @MainActor
    func testNativeFacePixelsChangeButFeetRemainIdenticalAndSaveThreeThemeSpecimens() throws {
        let route = try routeFixture()
        for theme in RunnerTheme.allCases {
            let window=UIWindow(frame:CGRect(x:0,y:0,width:400,height:800)),controller=UIViewController()
            let view=SKView(frame:CGRect(x:0,y:0,width:400,height:500)),scene=EggSpriteScene(size:CGSize(width:400,height:500))
            window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
            defer { scene.detach();view.presentScene(nil);window.isHidden=true }
            for (label,age) in [("surprised",0.10),("braced",0.26),("relieved",0.34),("ready",0.46)] {
                scene.configure(EggSceneSnapshot(elapsed:4.18+age,theme:theme,route:route,platformJourney:true))
                let actor=try XCTUnwrap(scene.childNode(withName:"player/characterPrimary") as? SKSpriteNode)
                let expression=try XCTUnwrap(view.texture(from:actor)).cgImage()
                let shader=actor.shader;actor.shader=nil
                let original=try XCTUnwrap(view.texture(from:actor)).cgImage();actor.shader=shader
                XCTAssertEqual(expression.width,original.width);XCTAssertEqual(expression.height,original.height)
                let a=try rgba(expression),b=try rgba(original)
                XCTAssertNotEqual(a,b,"Expression must be present in native rendered pixels, not only in state")
                // Feet occupy the lower quarter in these registered full-body fixtures.
                let feetStart=expression.width * expression.height * 3
                XCTAssertEqual(Array(a[feetStart...]),Array(b[feetStart...]),"No generated body pixels may alter the accepted feet/pose")
                let image=try XCTUnwrap(view.texture(from:scene)).cgImage()
                let attachment=XCTAttachment(image:UIImage(cgImage:image));attachment.name="GAME24 \(theme.rawValue) \(label)";attachment.lifetime = .keepAlways;add(attachment)
            }
            for height in [240.0,650.0] {
                scene.size=CGSize(width:320,height:height)
                for style in [UIUserInterfaceStyle.light,.dark] {
                    view.overrideUserInterfaceStyle=style
                    scene.configure(EggSceneSnapshot(elapsed:4.44,theme:theme,route:route,platformJourney:true))
                    let image=try XCTUnwrap(view.texture(from:scene)).cgImage()
                    let attachment=XCTAttachment(image:UIImage(cgImage:image));attachment.name="GAME24 \(theme.rawValue) height\(height) style\(style.rawValue)";attachment.lifetime = .keepAlways;add(attachment)
                }
            }
        }
    }
    private func rgba(_ image: CGImage) throws -> [UInt8] {
        var result=[UInt8](repeating:0,count:image.width*image.height*4)
        let context=try XCTUnwrap(CGContext(data:&result,width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height))
        return result
    }
}


final class JourneyIdleContinuityTests: XCTestCase {
    func testGroundedCycleAnticipatesWithoutMovingOrOverridingFlightAndInvalidStates() throws {
        let route = try routeFixture(accepted: [0,1,2,3])
        func sample(_ time: Double, reduced: Bool = false, stopped: Bool = false) -> JourneyIdleMotion {
            JourneyIdleMotion.sample(route: route, elapsed: time,
                frame: PlatformJourneyFrame.sample(route: route, elapsed: time, reduced: reduced),
                theme: .dinosaur, reduced: reduced, stopped: stopped)
        }
        XCTAssertEqual(sample(4.62).phase, .inactive)
        XCTAssertEqual(sample(4.70).phase, .waiting)
        XCTAssertEqual(sample(4.90).phase, .anticipating)
        XCTAssertGreaterThan(sample(4.90).charge, sample(4.80).charge)
        XCTAssertEqual(sample(5.02).phase, .releasing)
        XCTAssertEqual(sample(5.12).phase, .inactive)
        XCTAssertNotEqual(sample(4.72).breath, sample(4.76).breath)
        for beat in 0..<4 {
            let time = Double(4 + beat) + 0.90
            let frame = PlatformJourneyFrame.sample(route: route, elapsed: time, reduced: false)
            XCTAssertEqual(frame.step, Double(beat + 1), accuracy: 1e-10, "Anticipation never advances a platform")
            XCTAssertEqual(sample(time).phase, .anticipating)
        }
        for time in [Double.nan, .infinity, -.infinity, -1, 3.0, 100] { XCTAssertEqual(sample(time).phase, .inactive) }
        XCTAssertEqual(sample(4.90,reduced:true).phase,.inactive)
        XCTAssertEqual(sample(4.90,stopped:true).phase,.inactive)
        XCTAssertEqual(JourneyIdleMotion.sample(route:nil,elapsed:4.90,
            frame:PlatformJourneyFrame.sample(route:nil,elapsed:4.90,reduced:false),theme:.cat,reduced:false,stopped:false).phase,.inactive)
    }
    func testActualMatcherFirstEarlyFlightAndMissReturnKeepJudgmentAndWorldAuthority() throws {
        let epoch=1000.0,targets=(0..<16).map { TimingTarget(id:$0,time:epoch+4+Double($0),stroke:.right) }
        for inputs in [[3.82,5.18],[4.18,4.82],[4.0,5.0]] {
            var session=try TimingSession(targets:targets)
            for time in inputs { session.tap(at:epoch+time) }
            let route=try XCTUnwrap(RunnerRoute(targets:targets,hits:session.hits,epoch:epoch,endTime:epoch+20.18,alignment:0))
            XCTAssertEqual(session.summary.matched.count,2)
            let time=inputs[0]+0.09,frame=PlatformJourneyFrame.sample(route:route,elapsed:time,reduced:false)
            XCTAssertGreaterThan(frame.step,0)
            XCTAssertEqual(DenseAnimationFrame.sample(elapsed:time,age:frame.jumpAge,reduceMotion:false,stationary:true),14,
                "First early press must show flight before count-in ends")
            let before=route.accepted
            _=JourneyIdleMotion.sample(route:route,elapsed:inputs[0]+0.80,frame:frame,theme:.robot,reduced:false,stopped:false)
            XCTAssertEqual(route.accepted,before)
            XCTAssertEqual(session.summary.matched.count,2)
        }
        var session=try TimingSession(targets:targets)
        XCTAssertEqual(session.tap(at:epoch+4.4)?.grade,.extra)
        let missed=try XCTUnwrap(RunnerRoute(targets:targets,hits:session.hits,epoch:epoch,endTime:epoch+20.18,alignment:0))
        for time in [4.2,4.5,4.7] {
            let frame=PlatformJourneyFrame.sample(route:missed,elapsed:time,reduced:false)
            XCTAssertEqual(JourneyIdleMotion.sample(route:missed,elapsed:time,frame:frame,theme:.cat,reduced:false,stopped:false).phase,.inactive)
            XCTAssertEqual(frame.step,0)
        }
        let returning=PlatformJourneyFrame.sample(route:missed,elapsed:4.80,reduced:false)
        XCTAssertEqual(JourneyIdleMotion.sample(route:missed,elapsed:4.80,frame:returning,theme:.cat,reduced:false,stopped:false).phase,.anticipating)
        XCTAssertEqual(session.tap(at:epoch+4.82)?.targetID,1)
        let recovered=try XCTUnwrap(RunnerRoute(targets:targets,hits:session.hits,epoch:epoch,endTime:epoch+20.18,alignment:0))
        let frame=PlatformJourneyFrame.sample(route:recovered,elapsed:4.90,reduced:false)
        XCTAssertEqual(frame.recovery.phase,.idle);XCTAssertGreaterThan(frame.step,0)
        XCTAssertEqual(session.summary.matched.count,1);XCTAssertEqual(session.summary.extraCount,1)
    }
    @MainActor
    func testNativeIdleChangesUpperBodyPixelsButPreservesFeetAndSceneLocalRig() throws {
        for theme in RunnerTheme.allCases {
            let window=UIWindow(frame:CGRect(x:0,y:0,width:400,height:800)),controller=UIViewController()
            let view=SKView(frame:CGRect(x:0,y:0,width:400,height:500)),scene=EggSpriteScene(size:CGSize(width:400,height:500))
            window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
            defer { scene.detach();view.presentScene(nil);window.isHidden=true }
            let route=try routeFixture(accepted:[0,1,2,3])
            let actor=try XCTUnwrap(scene.childNode(withName:"player/characterPrimary") as? SKSpriteNode)
            let player=try XCTUnwrap(scene.childNode(withName:"player")),nodes=scene.children.count
            scene.configure(EggSceneSnapshot(elapsed:4.76,theme:theme,route:route,platformJourney:true))
            let shader=try XCTUnwrap(actor.shader),position=player.position,texture=actor.texture
            let a=try XCTUnwrap(view.texture(from:actor)).cgImage()
            scene.configure(EggSceneSnapshot(elapsed:4.94,theme:theme,route:route,platformJourney:true))
            let b=try XCTUnwrap(view.texture(from:actor)).cgImage()
            XCTAssertTrue(actor.shader === shader);XCTAssertTrue(actor.texture === texture)
            XCTAssertEqual(player.position,position);XCTAssertEqual(player.xScale,1);XCTAssertEqual(player.yScale,1)
            XCTAssertEqual(player.children.count,1);XCTAssertEqual(scene.children.count,nodes)
            XCTAssertEqual(a.width,b.width);XCTAssertEqual(a.height,b.height)
            let bytesA=try rgba(a),bytesB=try rgba(b)
            XCTAssertNotEqual(bytesA,bytesB,"Previously frozen inter-jump native pixels must actually move")
            let feetStart=a.width*a.height*3
            XCTAssertEqual(Array(bytesA[feetStart...]),Array(bytesB[feetStart...]),"Planted feet cannot drift during breathing or charge")
            let other=EggSpriteScene(size:CGSize(width:400,height:500))
            other.configure(EggSceneSnapshot(elapsed:4.94,theme:theme,route:route,platformJourney:true))
            let otherActor=try XCTUnwrap(other.childNode(withName:"player/characterPrimary") as? SKSpriteNode)
            let otherShader=try XCTUnwrap(otherActor.shader)
            XCTAssertFalse(otherShader === shader,"Scene-local uniforms must not leak across previews")
            let otherCharge=otherShader.uniformNamed("u_charge")?.floatValue
            scene.configure(EggSceneSnapshot(elapsed:4.76,theme:theme,route:route,platformJourney:true))
            XCTAssertEqual(otherShader.uniformNamed("u_charge")?.floatValue,otherCharge)
            for state in [EggSceneSnapshot(elapsed:4.94,reduceMotion:true,theme:theme,route:route,platformJourney:true),
                EggSceneSnapshot(elapsed:0,preparing:true,theme:theme,platformJourney:true),
                EggSceneSnapshot(elapsed:4.94,finishedPassed:false,theme:theme,route:route,platformJourney:true),
                EggSceneSnapshot(elapsed:4.94,theme:theme,platformJourney:true)] {
                scene.configure(state);XCTAssertNil(actor.shader)
            }
        }
    }
    @MainActor
    func testNativeFourJumpSequencesAndRecoveryHandoffAcrossThemesAndViewports() throws {
        for theme in RunnerTheme.allCases {
            let window=UIWindow(frame:CGRect(x:0,y:0,width:400,height:800)),controller=UIViewController()
            let view=SKView(frame:CGRect(x:0,y:0,width:400,height:500)),scene=EggSpriteScene(size:CGSize(width:400,height:500))
            window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
            defer { scene.detach();view.presentScene(nil);window.isHidden=true }
            let route=try routeFixture(accepted:[0,1,2,3]),missed=try routeFixture()
            for index in 0...100 {
                let time=4+Double(index)/25
                scene.configure(EggSceneSnapshot(elapsed:time,theme:theme,route:route,platformJourney:true))
                let image=try XCTUnwrap(view.texture(from:scene)).cgImage()
                let attachment=XCTAttachment(image:UIImage(cgImage:image));attachment.name="GAME25 \(theme.rawValue) loop \(index)";attachment.lifetime = .keepAlways;add(attachment)
            }
            for time in [4.70,4.78,4.82,4.86,4.90,4.98] {
                scene.configure(EggSceneSnapshot(elapsed:time,theme:theme,route:missed,platformJourney:true))
                let image=try XCTUnwrap(view.texture(from:scene)).cgImage()
                let attachment=XCTAttachment(image:UIImage(cgImage:image));attachment.name="GAME25 \(theme.rawValue) return \(time)";attachment.lifetime = .keepAlways;add(attachment)
            }
            for height in [240.0,650.0] {
                scene.size=CGSize(width:320,height:height)
                for style in [UIUserInterfaceStyle.light,.dark] {
                    view.overrideUserInterfaceStyle=style
                    scene.configure(EggSceneSnapshot(elapsed:4.94,theme:theme,route:route,platformJourney:true))
                    let image=try XCTUnwrap(view.texture(from:scene)).cgImage()
                    let attachment=XCTAttachment(image:UIImage(cgImage:image));attachment.name="GAME25 \(theme.rawValue) height\(height) style\(style.rawValue)";attachment.lifetime = .keepAlways;add(attachment)
                }
            }
        }
    }
    @MainActor
    func testLiveIdleUniformsAdvanceOnDisplayCallbacksThenFreezeWhenSuspended() async throws {
        let window=UIWindow(frame:CGRect(x:0,y:0,width:400,height:800)),controller=UIViewController()
        let view=SKView(frame:CGRect(x:0,y:0,width:400,height:500)),scene=EggSpriteScene(size:CGSize(width:400,height:500))
        window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
        defer { scene.detach();view.presentScene(nil);window.isHidden=true }
        let route=try routeFixture(accepted:[0]),epoch=PracticeStore.now()-4.72
        scene.configure(EggSceneSnapshot(presentationElapsed:{$0-epoch},theme:.dinosaur,route:route,platformJourney:true))
        let actor=try XCTUnwrap(scene.childNode(withName:"player/characterPrimary") as? SKSpriteNode)
        let shader=try XCTUnwrap(actor.shader),count=scene.callbackCount
        let old=shader.uniformNamed("u_charge")?.floatValue
        try await Task.sleep(nanoseconds:100_000_000)
        XCTAssertGreaterThan(scene.callbackCount,count)
        XCTAssertTrue(actor.shader === shader)
        XCTAssertNotEqual(shader.uniformNamed("u_charge")?.floatValue,old)
        scene.configure(EggSceneSnapshot(suspended:true,presentationElapsed:{$0-epoch},theme:.dinosaur,route:route,platformJourney:true))
        let paused=scene.callbackCount,charge=shader.uniformNamed("u_charge")?.floatValue
        try await Task.sleep(nanoseconds:100_000_000)
        XCTAssertEqual(scene.callbackCount,paused);XCTAssertEqual(shader.uniformNamed("u_charge")?.floatValue,charge)
    }
    private func rgba(_ image: CGImage) throws -> [UInt8] {
        var result=[UInt8](repeating:0,count:image.width*image.height*4)
        let context=try XCTUnwrap(CGContext(data:&result,width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height));return result
    }
}

final class SecondIslandLessonTests: XCTestCase {
    private func secondRoute(hits: [TimingHit] = []) throws -> RunnerRoute {
        let lesson = try LessonCatalog.bundled().lessons[1]
        return try XCTUnwrap(RunnerRoute(targets: lesson.pattern.targets(bpm:65,bars:4,epoch:100),
            hits:hits,epoch:100,endTime:100+1200.0/65+0.18,alignment:0))
    }
    func testFirstTwoBaseTempoProfilesAndReviewedSecondTargets() throws {
        let lessons = try LessonCatalog.bundled().lessons
        XCTAssertEqual(IslandLesson.profile(lessons[0]),.first)
        XCTAssertEqual(IslandLesson.profile(lessons[1]),.alternating)
        XCTAssertNil(IslandLesson.profile(try lessons[0].atTempo(65)))
        XCTAssertNil(IslandLesson.profile(try lessons[1].atTempo(70)))
        let route=try secondRoute()
        XCTAssertEqual(route.targets.count,16)
        XCTAssertEqual(route.relativeTimes[0],240.0/65,accuracy:1e-10)
        XCTAssertEqual(route.relativeTimes[15],1140.0/65,accuracy:1e-10)
        XCTAssertEqual(route.duration,1200.0/65+0.18,accuracy:1e-10)
        for i in 0..<16 {
            XCTAssertEqual(route.targets[i].id,i)
            XCTAssertEqual(route.targets[i].stroke,i%2==0 ? .right : .left)
            if i>0 { XCTAssertEqual(route.relativeTimes[i]-route.relativeTimes[i-1],60.0/65,accuracy:1e-10) }
        }
    }
    func testPromptAndPulseUse65BPMNotesAfterEarlyDuplicateLateAndMiss() throws {
        let fixture=try secondRoute(),t=240.0/65,beat=60.0/65
        XCTAssertEqual(fixture.promptTarget(at:0)?.stroke,.right)
        XCTAssertNil(fixture.currentIndex(at:t-0.000001))
        XCTAssertEqual(fixture.currentIndex(at:t),0,"Equivalent absolute/relative fractional boundary")
        XCTAssertEqual(fixture.promptTarget(at:t+0.181)?.id,1,"Miss advances the cue, not the world")
        for invalid in [Double.nan,.infinity,-1,fixture.duration+0.01] { XCTAssertNil(fixture.promptTarget(at:invalid)) }
        var session=try TimingSession(targets:fixture.targets)
        session.tap(at:100+t-0.14);session.tap(at:100+t-0.13)
        let early=try secondRoute(hits:session.hits)
        XCTAssertEqual(early.promptTarget(at:t-0.14)?.stroke,.left)
        XCTAssertEqual(early.accepted,[0]);XCTAssertEqual(session.summary.extraCount,1)
        session.tap(at:100+t+beat+0.14)
        let late=try secondRoute(hits:session.hits)
        XCTAssertEqual(late.promptTarget(at:t+beat+0.14)?.stroke,.right)
        XCTAssertEqual(late.grades[1],.late)
        for i in 0..<16 {
            XCTAssertEqual(EggBeatLane.markerAlpha(route:fixture,elapsed:routeTime(i),reduceMotion:false),1,accuracy:1e-8)
            XCTAssertEqual(EggBeatLane.markerAlpha(route:fixture,elapsed:routeTime(i)+0.06,reduceMotion:false),0.725,accuracy:1e-8)
        }
        XCTAssertEqual(EggBeatLane.markerAlpha(route:fixture,elapsed:t,reduceMotion:true),0.45)
        let first=try routeFixture()
        for time in [3.9,4,4.06,5.2,18.9,19.06,20] {
            XCTAssertEqual(EggBeatLane.markerAlpha(route:first,elapsed:time,reduceMotion:false),
                           EggBeatLane.markerAlpha(elapsed:time,reduceMotion:false),accuracy:1e-8)
        }
        func routeTime(_ i:Int)->Double { (240+Double(i)*60)/65 }
    }
    func testClosest65BPMHitsKeepWorldContinuousAndMissNeverMovesIsland() throws {
        let fixture=try secondRoute(),t=240.0/65,beat=60.0/65
        var session=try TimingSession(targets:fixture.targets)
        // Specification: adjacent legal late→early presses can be60/65-.36 apart.
        session.tap(at:100+t+0.18);session.tap(at:100+t+beat-0.18)
        let route=try secondRoute(hits:session.hits),second=t+beat-0.18
        XCTAssertEqual(route.accepted,[0,1]);XCTAssertEqual(session.summary.matched.count,2)
        let before=PlatformJourneyFrame.sample(route:route,elapsed:second-0.001,reduced:false)
        let after=PlatformJourneyFrame.sample(route:route,elapsed:second+0.001,reduced:false)
        XCTAssertEqual(before.step,1,accuracy:1e-7);XCTAssertLessThan(after.step-before.step,0.001)
        XCTAssertEqual(DenseAnimationFrame.sample(elapsed:second+0.04,age:after.jumpAge.map{$0+0.039},reduceMotion:false,stationary:true),13)
        let missed=PlatformJourneyFrame.sample(route:fixture,elapsed:t+0.30,reduced:false)
        XCTAssertEqual(missed.step,0);XCTAssertEqual(missed.recovery.phase,.falling)
        XCTAssertEqual(fixture.promptTarget(at:t+0.30)?.stroke,.left)
        for i in 0..<16 {session.tap(at:fixture.targets[i].time)}
        XCTAssertTrue(session.summary.extraCount>=2,"Duplicate hits cannot become another island")
    }
    @MainActor
    func testNativeSecondLevelThemesShowAlternatingCueAndRetainIdleFlightRecovery() throws {
        let t=240.0/65,beat=60.0/65,empty=try secondRoute()
        var session=try TimingSession(targets:empty.targets);session.tap(at:100+t)
        let matched=try secondRoute(hits:session.hits)
        for theme in RunnerTheme.allCases {
            let window=UIWindow(frame:CGRect(x:0,y:0,width:400,height:800)),controller=UIViewController()
            let view=SKView(frame:CGRect(x:0,y:0,width:400,height:500)),scene=EggSpriteScene(size:CGSize(width:400,height:500))
            window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
            defer {scene.detach();view.presentScene(nil);window.isHidden=true}
            let prompt=try XCTUnwrap(scene.childNode(withName:"nextLandingCue") as? SKLabelNode)
            let actor=try XCTUnwrap(scene.childNode(withName:"player/characterPrimary") as? SKSpriteNode)
            for (name,time,route) in [("count-in",t-0.10,empty),("flight",t+0.25,matched),
                                     ("idle-left",t+0.70,matched),("left",t+beat,empty),
                                     ("right-after-miss",t+2*beat,empty)] {
                scene.configure(EggSceneSnapshot(elapsed:time,theme:theme,route:route,platformJourney:true))
                XCTAssertEqual(prompt.text,time<t ? "R" : route.promptTarget(at:time)?.stroke.rawValue)
                XCTAssertNotNil(actor.texture);XCTAssertEqual(actor.parent?.children.count,1)
                XCTAssertEqual(prompt.alpha,1,"Hand instructions do not fade with decorative pulse")
                if name=="idle-left" { XCTAssertNotNil(actor.shader);XCTAssertFalse(prompt.isHidden) }
                let image=try XCTUnwrap(view.texture(from:scene)).cgImage()
                let attachment=XCTAttachment(image:UIImage(cgImage:image));attachment.name="GAME26 \(theme.rawValue) \(name)";attachment.lifetime = .keepAlways;add(attachment)
            }
            scene.configure(EggSceneSnapshot(elapsed:t+0.70,reduceMotion:true,theme:theme,route:matched,platformJourney:true))
            XCTAssertNil(actor.shader);XCTAssertEqual(prompt.text,"L")
            scene.configure(EggSceneSnapshot(elapsed:0,preparing:true,theme:theme,platformJourney:true))
            XCTAssertNil(actor.shader);XCTAssertTrue(prompt.isHidden)
        }
    }
    @MainActor
    func testSecondMissionLocksActualScorePersistenceCancelAndFasterFallback() async throws {
        try await checkStoreSave(fail:false)
    }
    @MainActor
    func testSecondMissionFailedSaveCannotUnlockUntilRetry() async throws {
        try await checkStoreSave(fail:true)
    }
    @MainActor
    private func checkStoreSave(fail:Bool) async throws {
        let name="BeatLabTests.SecondLevel.\(UUID().uuidString)",defaults=try XCTUnwrap(UserDefaults(suiteName:name))
        defer {defaults.removePersistentDomain(forName:name)}
        let repo=ProgressRepository(defaults:defaults),store=PracticeStore(repository:repo),audio=MetronomeAudio()
        defer {audio.stop()}
        let second=store.lessons[1]
        store.start(second,audio:audio,eggMission:true)
        XCTAssertEqual(store.phase,.idle);XCTAssertFalse(store.unlocked(second));XCTAssertFalse(audio.isPlaying)
        // Reviewed saved-first fixture goes through the real catalog scorer/repository.
        let first=store.lessons[0],targets=try first.pattern.targets(bpm:60,bars:4,epoch:100)
        var session=try TimingSession(targets:targets);for target in targets {session.tap(at:target.time)}
        var progress=PracticeProgress();progress.record(first,summary:session.summary);try repo.save(progress)
        let unlocked=PracticeStore(repository:repo);unlocked.select(second)
        XCTAssertEqual(unlocked.practiceBPM,65);XCTAssertFalse(unlocked.unlocked(unlocked.lessons[2]))
        unlocked.start(second,audio:audio,eggMission:true)
        for _ in 0..<40 where unlocked.phase == .preparing {try await Task.sleep(nanoseconds:50_000_000)}
        XCTAssertEqual(unlocked.phase,.playing);XCTAssertTrue(unlocked.isEggMission)
        XCTAssertFalse(audio.practiceGrooveAvailable,"The60BPM bed must not leak into65BPM")
        let route=try XCTUnwrap(unlocked.runnerRoute),anchor=try XCTUnwrap(audio.audibleEpoch())
        XCTAssertEqual(route.relativeTimes.first!,240.0/65,accuracy:0.00001)
        unlocked.tap(at:anchor+1);XCTAssertNil(unlocked.latestHit)
        unlocked.tap(at:route.targets[0].time);XCTAssertEqual(unlocked.latestHit?.grade,.perfect)
        unlocked.cancel(audio:audio);XCTAssertNil(unlocked.runnerRoute);XCTAssertFalse(unlocked.isEggMission)
        XCTAssertEqual(unlocked.progress.results.count,1)
        unlocked.start(second,audio:audio,eggMission:true)
        for _ in 0..<40 where unlocked.phase == .preparing {try await Task.sleep(nanoseconds:50_000_000)}
        let restarted=try XCTUnwrap(unlocked.runnerRoute);XCTAssertTrue(restarted.accepted.isEmpty)
        for target in restarted.targets {unlocked.tap(at:target.time)}
        let savedFirst=try XCTUnwrap(defaults.data(forKey:ProgressRepository.storageKey))
        if fail {defaults.set(Data("{\"schemaVersion\":99}".utf8),forKey:ProgressRepository.storageKey)}
        for _ in 0..<440 where unlocked.phase == .playing {try await Task.sleep(nanoseconds:50_000_000)}
        XCTAssertEqual(unlocked.phase,.finished);XCTAssertEqual(unlocked.stars,3)
        XCTAssertEqual(unlocked.summary?.matched.count,16);XCTAssertEqual(unlocked.summary?.missedCount,0)
        if fail {
            XCTAssertFalse(unlocked.resultSaved);XCTAssertTrue(unlocked.needsSaveRetry)
            XCTAssertFalse(unlocked.unlocked(unlocked.lessons[2]))
            unlocked.retrySave();XCTAssertFalse(unlocked.resultSaved)
            defaults.set(savedFirst,forKey:ProgressRepository.storageKey)
            unlocked.retrySave()
        }
        XCTAssertTrue(unlocked.resultSaved);XCTAssertFalse(unlocked.needsSaveRetry)
        let restored=PracticeStore(repository:repo)
        XCTAssertEqual(restored.progress.results[second.id]?.stars,3)
        XCTAssertEqual(restored.progress.results[second.id]?.bestBPM,65)
        XCTAssertTrue(restored.unlocked(restored.lessons[2]));XCTAssertFalse(restored.unlocked(restored.lessons[3]))
        restored.select(second);restored.setPracticeBPM(70);restored.start(second,audio:audio,eggMission:true)
        for _ in 0..<40 where restored.phase == .preparing {try await Task.sleep(nanoseconds:50_000_000)}
        XCTAssertFalse(restored.isEggMission);XCTAssertNil(restored.runnerRoute)
        restored.cancel(audio:audio)
    }
}

final class DenseIslandLessonTests: XCTestCase {
    private func fixture(_ level: Int, hits: [TimingHit] = []) throws -> RunnerRoute {
        let lesson = try LessonCatalog.bundled().lessons[level-1]
        return try XCTUnwrap(RunnerRoute(targets:lesson.pattern.targets(bpm:lesson.bpm,bars:4,epoch:100),hits:hits,epoch:100,endTime:100+1200/Double(lesson.bpm)+0.18,alignment:0))
    }
    func testReviewedHalfBeatTargetsGridAndSafeInvalidFallback() throws {
        let lessons = try LessonCatalog.bundled().lessons
        XCTAssertEqual(IslandLesson.profile(lessons[2]),.eighth)
        XCTAssertEqual(IslandLesson.profile(lessons[3]),.eighthAlternating)
        for level in [3,4] {
            let route=try fixture(level),bpm=level == 3 ? 60.0 : 65.0
            XCTAssertEqual(route.targets.count,32);XCTAssertEqual(route.grid?.steps,32)
            XCTAssertEqual(try XCTUnwrap(route.grid).interval,30/bpm,accuracy:1e-10)
            XCTAssertEqual(try XCTUnwrap(route.grid).start,240/bpm,accuracy:1e-10)
            for i in 0..<32 {
                XCTAssertEqual(route.targets[i].id,i)
                XCTAssertEqual(route.relativeTimes[i],(240+Double(i)*30)/bpm,accuracy:1e-10)
                XCTAssertEqual(route.targets[i].stroke,level == 4 && i%2==1 ? .left : .right)
            }
            XCTAssertNil(IslandLesson.profile(try lessons[level-1].atTempo(Int(bpm)+5)))
        }
        let route=try fixture(3)
        XCTAssertNil(IslandRouteGrid(targets:Array(route.targets.reversed()),epoch:100,endTime:120.18))
        XCTAssertNil(IslandRouteGrid(targets:route.targets,epoch:.nan,endTime:120.18))
        XCTAssertNil(IslandRouteGrid(targets:route.targets,epoch:100,endTime:120.3))
        XCTAssertNil(DenseJourneyFrame.sample(route:try routeFixture(),elapsed:4,reduced:false))
        let invalid=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:.nan,reduced:false))
        XCTAssertEqual(invalid.world.step,0);XCTAssertEqual(invalid.height,0)
    }
    func testClosestLegalAdjacentHitsDoNotResetHeightPoseOrCamera() throws {
        for level in [3,4] {
            let empty=try fixture(level),interval=level == 3 ? 0.5 : 6.0/13
            var matcher=try TimingSession(targets:empty.targets)
            matcher.tap(at:empty.targets[0].time+0.18)
            matcher.tap(at:empty.targets[1].time-0.18)
            XCTAssertEqual(matcher.summary.matched.count,2)
            XCTAssertEqual(matcher.hits[0].grade,.late);XCTAssertEqual(matcher.hits[1].grade,.early)
            let route=try fixture(level,hits:matcher.hits),press=empty.relativeTimes[0]+interval-0.18
            let before=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:press-1e-6,reduced:false))
            let at=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:press,reduced:false))
            let after=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:press+1e-6,reduced:false))
            XCTAssertGreaterThan(at.height,0.5,"Second press overlaps a real active flight")
            XCTAssertEqual(before.height,at.height,accuracy:0.0001);XCTAssertEqual(after.height,at.height,accuracy:0.0001)
            XCTAssertEqual(before.world.step,after.world.step,accuracy:0.0001)
            XCTAssertEqual(before.world.camera,after.world.camera,accuracy:0.0001)
            XCTAssertEqual(try XCTUnwrap(before.poseAge),try XCTUnwrap(after.poseAge),accuracy:0.0001)
            matcher.tap(at:empty.targets[1].time-0.17)
            XCTAssertEqual(matcher.summary.extraCount,1)
            let duplicate=try fixture(level,hits:matcher.hits)
            XCTAssertEqual(DenseJourneyFrame.sample(route:duplicate,elapsed:press+1,reduced:false)?.world.step,2)
            XCTAssertEqual(DenseJourneyFrame.sample(route:route,elapsed:press+1,reduced:true)?.world.step,2)
            XCTAssertEqual(DenseJourneyFrame.sample(route:route,elapsed:press+1,reduced:true)?.height,0)
        }
    }
    func testRecoveryInterruptedByNextLegalEarlyPressIsContinuous() throws {
        let empty=try fixture(4),first=empty.relativeTimes[0],press=empty.relativeTimes[1]-0.18
        var matcher=try TimingSession(targets:empty.targets);matcher.tap(at:100+press)
        XCTAssertEqual(matcher.hits.first?.targetID,1)
        let route=try fixture(4,hits:matcher.hits)
        let before=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:press-1e-6,reduced:false))
        let at=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:press,reduced:false))
        let after=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:press+1e-6,reduced:false))
        XCTAssertGreaterThan(at.world.fall,0)
        XCTAssertEqual(before.world.fall,after.world.fall,accuracy:0.0001)
        XCTAssertEqual(before.height,after.height,accuracy:0.0001)
        XCTAssertEqual(DenseJourneyFrame.sample(route:empty,elapsed:first+0.30,reduced:false)?.world.step,0)
        XCTAssertEqual(route.promptTarget(at:press)?.id,2)
    }
    @MainActor
    func testNativeDenseScenesBeyondSixteenAndLastIslandReuseNodesForAllThemes() throws {
        for level in [3,4] {
            let empty=try fixture(level);var matcher=try TimingSession(targets:empty.targets)
            for target in empty.targets {matcher.tap(at:target.time)}
            let route=try fixture(level,hits:matcher.hits)
            for theme in RunnerTheme.allCases {
                let window=UIWindow(frame:CGRect(x:0,y:0,width:400,height:800)),controller=UIViewController()
                let view=SKView(frame:CGRect(x:0,y:0,width:400,height:400)),scene=EggSpriteScene(size:CGSize(width:400,height:400))
                window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
                defer {scene.detach();view.presentScene(nil);window.isHidden=true}
                let nodeCount=scene.children.count,actor=try XCTUnwrap(scene.childNode(withName:"player"))
                let snapshots:[(String,Double)]=[("count-in",route.relativeTimes[0]-0.1),("flight",route.relativeTimes[0]+0.15),("step17",route.relativeTimes[16]+0.32),("last-flight",route.relativeTimes[31]+0.10),("last-landed",route.duration)]
                for (name,time) in snapshots {
                    scene.configure(EggSceneSnapshot(elapsed:time,theme:theme,route:route,platformJourney:true))
                    XCTAssertEqual(scene.children.count,nodeCount);XCTAssertEqual(actor.children.count,1)
                    XCTAssertTrue(actor.position.x.isFinite);XCTAssertTrue(actor.position.y.isFinite)
                    if name == "step17" || name == "last-landed" {
                        let visible=scene.children.compactMap{$0 as? SKSpriteNode}.filter{ $0.name?.hasPrefix("platform") == true && !$0.isHidden }
                        XCTAssertFalse(visible.isEmpty,"Dense path cannot disappear after16")
                        XCTAssertTrue(visible.contains{abs($0.position.x-actor.position.x)<400*0.10},"Actor stands on its actual island")
                    }
                    if name == "last-landed" {
                        let nest=try XCTUnwrap(scene.childNode(withName:"destination"))
                        XCTAssertFalse(nest.isHidden);XCTAssertEqual(nest.position.x,actor.position.x,accuracy:0.001)
                    }
                    let attachment=XCTAttachment(image:UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)).cgImage()))
                    attachment.name="GAME27 level\(level) \(theme.rawValue) \(name)";attachment.lifetime = .keepAlways;add(attachment)
                }
                scene.configure(EggSceneSnapshot(elapsed:route.relativeTimes[17]+0.1,reduceMotion:true,theme:theme,route:route,platformJourney:true))
                XCTAssertEqual(actor.position.y,400*0.31,accuracy:0.001)
            }
        }
    }
    @MainActor
    func testNativeOverlappingHalfBeatFlightsStayRegisteredOnCompactTallAndDarkScenes() throws {
        for level in [3,4] {
            let empty=try fixture(level)
            var matcher=try TimingSession(targets:empty.targets)
            matcher.tap(at:empty.targets[0].time+0.18);matcher.tap(at:empty.targets[1].time-0.18)
            let route=try fixture(level,hits:matcher.hits),press=empty.relativeTimes[1]-0.18
            for theme in RunnerTheme.allCases {
                for height in [240.0,520.0] {
                    for style in [UIUserInterfaceStyle.light,.dark] {
                        let window=UIWindow(frame:CGRect(x:0,y:0,width:375,height:812)),controller=UIViewController()
                        controller.overrideUserInterfaceStyle=style
                        let view=SKView(frame:CGRect(x:0,y:0,width:375,height:height)),scene=EggSpriteScene(size:CGSize(width:375,height:height))
                        window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
                        defer {scene.detach();view.presentScene(nil);window.isHidden=true}
                        let player=try XCTUnwrap(scene.childNode(withName:"player")),count=scene.children.count
                        var previous:CGPoint?
                        for (name,time) in [("before",press-0.001),("after",press+0.001),("overlap",press+0.05)] {
                            scene.configure(EggSceneSnapshot(elapsed:time,theme:theme,route:route,platformJourney:true))
                            XCTAssertEqual(scene.children.count,count);XCTAssertEqual(player.children.count,1)
                            XCTAssertGreaterThan(player.position.y,height*0.31)
                            XCTAssertLessThan(player.calculateAccumulatedFrame().maxY,height)
                            if name == "after",let previous {
                                XCTAssertEqual(player.position.x,previous.x,accuracy:2)
                                XCTAssertEqual(player.position.y,previous.y,accuracy:2)
                            }
                            previous=player.position
                            let attachment=XCTAttachment(image:UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)).cgImage()))
                            attachment.name="GAME27 overlap level\(level) \(theme.rawValue) h\(Int(height)) \(style.rawValue) \(name)";attachment.lifetime = .keepAlways;add(attachment)
                        }
                    }
                }
            }
        }
    }
    @MainActor
    func testCompactFinalDenseSceneBackdropCoversWholeViewportWithoutChangingActor() throws {
        let empty=try fixture(4);var matcher=try TimingSession(targets:empty.targets)
        for target in empty.targets {matcher.tap(at:target.time)}
        let route=try fixture(4,hits:matcher.hits)
        for theme in RunnerTheme.allCases {
            let window=UIWindow(frame:CGRect(x:0,y:0,width:375,height:667)),controller=UIViewController()
            let view=SKView(frame:CGRect(x:0,y:0,width:375,height:200)),scene=EggSpriteScene(size:CGSize(width:375,height:200))
            window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
            defer {scene.detach();view.presentScene(nil);window.isHidden=true}
            scene.configure(EggSceneSnapshot(elapsed:route.duration,theme:theme,route:route,platformJourney:true))
            let backdrop=try XCTUnwrap(scene.childNode(withName:"backdrop")),actor=try XCTUnwrap(scene.childNode(withName:"player"))
            XCTAssertLessThanOrEqual(backdrop.frame.minX,0);XCTAssertGreaterThanOrEqual(backdrop.frame.maxX,375-1e-6)
            XCTAssertLessThanOrEqual(backdrop.frame.minY,0);XCTAssertGreaterThanOrEqual(backdrop.frame.maxY,200-1e-6)
            // Reviewed GAME27 anchor:20% origin plus1.3 platforms at27% width.
            XCTAssertEqual(actor.position.x,375*(0.20+1.3*0.27),accuracy:0.001);XCTAssertEqual(actor.position.y,200*0.31,accuracy:0.001)
            let a=XCTAttachment(image:UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)).cgImage()))
            a.name="GAME28 compact final \(theme.rawValue)";a.lifetime = .keepAlways;add(a)
        }
    }
    @MainActor
    func testDenseBaseMissionUsesOriginalClickAndSaves32ActualTargets() async throws {
        for level in [3,4] {
            let name="BeatLabTests.Dense.\(UUID().uuidString)",defaults=try XCTUnwrap(UserDefaults(suiteName:name))
            defer {defaults.removePersistentDomain(forName:name)}
            let repo=ProgressRepository(defaults:defaults),catalog=try LessonCatalog.bundled().lessons
            var progress=PracticeProgress()
            for lesson in catalog.prefix(level-1) {
                var match=try TimingSession(targets:lesson.pattern.targets(bpm:lesson.bpm,bars:4,epoch:100))
                for target in match.targets {match.tap(at:target.time)}
                progress.record(lesson,summary:match.summary)
            }
            try repo.save(progress)
            let store=PracticeStore(repository:repo),audio=MetronomeAudio(),lesson=catalog[level-1]
            defer {audio.stop()}
            store.select(lesson);store.start(lesson,audio:audio,eggMission:true)
            for _ in 0..<40 where store.phase == .preparing {try await Task.sleep(nanoseconds:50_000_000)}
            XCTAssertTrue(store.isEggMission);XCTAssertFalse(audio.practiceGrooveAvailable,"Original60BPM first-level bed cannot leak into eighths")
            let route=try XCTUnwrap(store.runnerRoute);XCTAssertEqual(route.targets.count,32)
            for target in route.targets {store.tap(at:target.time)}
            for _ in 0..<450 where store.phase == .playing {try await Task.sleep(nanoseconds:50_000_000)}
            XCTAssertEqual(store.phase,.finished);XCTAssertEqual(store.summary?.matched.count,32)
            XCTAssertEqual(store.summary?.missedCount,0);XCTAssertEqual(store.stars,3);XCTAssertTrue(store.resultSaved)
            let reloaded=PracticeStore(repository:repo)
            XCTAssertEqual(reloaded.progress.results[lesson.id]?.bestBPM,lesson.bpm)
            XCTAssertTrue(reloaded.unlocked(catalog[level]));XCTAssertFalse(reloaded.unlocked(catalog[level+1]))
        }
    }
}


final class RestIslandLessonTests: XCTestCase {
    private func fixture(_ level: Int, hits:[TimingHit]=[], alignment:Double=0) throws -> RunnerRoute {
        let lesson=try LessonCatalog.bundled().lessons[level-1]
        return try XCTUnwrap(RunnerRoute(targets:lesson.pattern.targets(bpm:lesson.bpm,bars:4,epoch:100),hits:hits,epoch:100,endTime:100+1200/Double(lesson.bpm)+0.18,alignment:alignment))
    }
    func testReviewedRestTargetsFourBeatCountInAndInitialTrailingCells() throws {
        let lessons=try LessonCatalog.bundled().lessons
        let fixtures:[(Int,IslandLesson,Int,[Int])]=[(5,.quarterRest,16,[0,2]),(6,.eighthRest,32,[0,1,3,5,6]),(9,.offbeat,32,[1,3,5,7])]
        for (level,profile,length,barIDs) in fixtures {
            let route=try fixture(level),grid=try XCTUnwrap(route.grid),bpm=level == 9 ? 75.0 : 70.0
            let perBeat=level == 5 ? 1 : 2,interval=level == 5 ? 6.0/7 : level == 6 ? 3.0/7 : 0.4
            XCTAssertEqual(IslandLesson.profile(lessons[level-1]),profile)
            XCTAssertNil(IslandLesson.profile(try lessons[level-1].atTempo(Int(bpm)+5)))
            let expectedIDs=(0..<4).flatMap{bar in barIDs.map{bar*(length/4)+$0}}
            XCTAssertEqual(route.targets.map(\.id),expectedIDs)
            XCTAssertEqual(route.targets.count,level == 5 ? 8 : level == 6 ? 20 : 16)
            XCTAssertEqual(grid.steps,length);XCTAssertEqual(grid.start,240/bpm,accuracy:1e-10)
            XCTAssertEqual(grid.interval,interval,accuracy:1e-10)
            XCTAssertEqual(route.countInRemaining(at:0,stepsPerBeat:perBeat),4)
            XCTAssertEqual(route.countInRemaining(at:60/bpm,stepsPerBeat:perBeat),3)
            XCTAssertNil(route.countInRemaining(at:grid.start,stepsPerBeat:perBeat))
            XCTAssertNil(grid.cellIndex(at:grid.start-1e-6));XCTAssertEqual(grid.cellIndex(at:grid.start),0)
            for cell in 0..<length {
                let time=grid.start+Double(cell)*interval
                XCTAssertEqual(grid.cellIndex(at:time),cell)
                XCTAssertEqual(route.isRest(at:time),!expectedIDs.contains(cell))
                if let target=route.cellTarget(cell) {XCTAssertEqual(target.time-100,time,accuracy:1e-10)}
            }
            XCTAssertEqual(grid.cellIndex(at:route.duration),length-1)
            XCTAssertNil(grid.cellIndex(at:route.duration+0.001))
            XCTAssertEqual(route.isRest(at:grid.start),level == 9)
            XCTAssertEqual(route.isRest(at:route.duration),level != 9)
            for invalid in [Double.nan,.infinity,-1] {XCTAssertNil(grid.cellIndex(at:invalid));XCTAssertNil(route.countInRemaining(at:invalid,stepsPerBeat:perBeat))}
        }
    }
    func testRestCentersStayExtraAndNeverProduceAnIslandOrRecovery() throws {
        for level in [5,6,9] {
            let empty=try fixture(level),grid=try XCTUnwrap(empty.grid)
            for alignment in [-0.25,0,0.25] {
                var matcher=try TimingSession(targets:empty.targets,calibrationOffset:alignment)
                for cell in 0..<grid.steps where empty.cellTarget(cell)==nil {
                    let input=100+grid.start+(Double(cell)+0.5)*grid.interval+alignment
                    XCTAssertEqual(matcher.tap(at:input)?.grade,.extra,"Reviewed rest centers are more than180ms from actual notes")
                }
                XCTAssertEqual(matcher.summary.matched.count,0)
                let route=try fixture(level,hits:matcher.hits,alignment:alignment)
                let frame=DenseJourneyFrame.sample(route:route,elapsed:grid.start+0.1,reduced:false)?.world ?? PlatformJourneyFrame.sample(route:route,elapsed:grid.start+0.1,reduced:false)
                XCTAssertEqual(frame.step,0);XCTAssertTrue(route.accepted.isEmpty)
            }
            var all=try TimingSession(targets:empty.targets)
            for target in empty.targets {all.tap(at:target.time)}
            let route=try fixture(level,hits:all.hits)
            for cell in 0..<grid.steps where route.cellTarget(cell)==nil {
                let time=grid.start+(Double(cell)+0.5)*grid.interval
                let frame=DenseJourneyFrame.sample(route:route,elapsed:time,reduced:false)?.world ?? PlatformJourneyFrame.sample(route:route,elapsed:time,reduced:false)
                XCTAssertEqual(frame.recovery.phase,.idle,"Silence never creates a miss/fall")
                let past=empty.targets.filter{$0.time-100<time}.count
                XCTAssertEqual(frame.step,Double(past),accuracy:1e-8,"Only actual accepted notes move the actor")
                XCTAssertLessThan(EggBeatLane.markerAlpha(route:route,elapsed:time,reduceMotion:false),0.46)
            }
        }
    }
    func testLegalNearRestEarlyLateDuplicateAndTieRemainMatcherAuthority() throws {
        for level in [5,6,9] {
            let empty=try fixture(level),grid=try XCTUnwrap(empty.grid)
            let target=try XCTUnwrap(empty.targets.first{ $0.id>0 && empty.cellTarget($0.id-1)==nil })
            XCTAssertTrue(empty.isRest(at:target.time-100-0.15))
            for alignment in [-0.25,0,0.25] {
                var early=try TimingSession(targets:empty.targets,calibrationOffset:alignment)
                let input=target.time-0.15+alignment
                XCTAssertEqual(early.tap(at:input)?.targetID,target.id);XCTAssertEqual(early.hits.last?.grade,.early)
                XCTAssertEqual(early.tap(at:input+0.01)?.grade,.extra)
                let route=try fixture(level,hits:early.hits,alignment:alignment)
                XCTAssertEqual(route.accepted,[target.id]);XCTAssertEqual(route.promptTarget(at:input-100)?.id,empty.targets.first{$0.id>target.id}?.id)
                var late=try TimingSession(targets:empty.targets,calibrationOffset:alignment)
                XCTAssertEqual(late.tap(at:target.time+0.15+alignment)?.targetID,target.id)
                XCTAssertEqual(late.hits.last?.grade,.late)
                var tie=try TimingSession(targets:empty.targets,calibrationOffset:alignment)
                let midpoint=(empty.targets[0].time+empty.targets[1].time)/2+alignment
                XCTAssertEqual(tie.tap(at:midpoint)?.grade,.extra,"All these reviewed nearest-note ties are outside180ms")
            }
            var matcher=try TimingSession(targets:empty.targets)
            matcher.tap(at:target.time-0.15)
            let route=try fixture(level,hits:matcher.hits)
            let t=target.time-100-0.15
            let before=DenseJourneyFrame.sample(route:route,elapsed:t-1e-6,reduced:false)?.world ?? PlatformJourneyFrame.sample(route:route,elapsed:t-1e-6,reduced:false)
            let after=DenseJourneyFrame.sample(route:route,elapsed:t+1e-6,reduced:false)?.world ?? PlatformJourneyFrame.sample(route:route,elapsed:t+1e-6,reduced:false)
            XCTAssertEqual(before.step,after.step,accuracy:1e-5)
            XCTAssertEqual(grid.cellIndex(at:t),target.id-1)
        }
    }
    func testFirstFourGridCuesRemainEquivalentAndActualMissStillRecovers() throws {
        for level in 1...4 {
            let route=try fixture(level),grid=try XCTUnwrap(route.grid)
            for i in 0..<grid.steps {let time=grid.start+Double(i)*grid.interval;XCTAssertEqual(grid.cellIndex(at:time),route.currentIndex(at:time));XCTAssertFalse(route.isRest(at:time))}
            XCTAssertEqual(route.countInRemaining(at:0,stepsPerBeat:level<3 ? 1 : 2),4)
        }
        for level in [5,6,9] {
            let route=try fixture(level),time=route.relativeTimes[0]+0.30
            let frame=DenseJourneyFrame.sample(route:route,elapsed:time,reduced:false)?.world ?? PlatformJourneyFrame.sample(route:route,elapsed:time,reduced:false)
            XCTAssertEqual(frame.step,0);XCTAssertEqual(frame.recovery.phase,.falling)
        }
    }
    @MainActor
    func testNativeRestWaitEarlyFlightAndActualFinalIslandAcrossThemesAndHeights() throws {
        for level in [5,6,9] {
            let empty=try fixture(level),grid=try XCTUnwrap(empty.grid)
            var matcher=try TimingSession(targets:empty.targets)
            for target in empty.targets {matcher.tap(at:target.time)}
            let complete=try fixture(level,hits:matcher.hits)
            let rest=try XCTUnwrap((0..<grid.steps).first{empty.cellTarget($0)==nil})
            let note=try XCTUnwrap(empty.targets.first{ $0.id>0 && empty.cellTarget($0.id-1)==nil })
            var early=try TimingSession(targets:empty.targets);early.tap(at:note.time-0.15)
            let earlyRoute=try fixture(level,hits:early.hits)
            for theme in RunnerTheme.allCases {
                for height in [200.0,400.0] {
                    let window=UIWindow(frame:CGRect(x:0,y:0,width:375,height:667)),controller=UIViewController()
                    let view=SKView(frame:CGRect(x:0,y:0,width:375,height:height)),scene=EggSpriteScene(size:CGSize(width:375,height:height))
                    window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
                    defer {scene.detach();view.presentScene(nil);window.isHidden=true}
                    let actor=try XCTUnwrap(scene.childNode(withName:"player")),count=scene.children.count
                    let snapshots:[(String,RunnerRoute,Double)]=[("wait",complete,grid.start+(Double(rest)+0.5)*grid.interval),("early",earlyRoute,note.time-100-0.10),("final",complete,complete.duration)]
                    for (name,route,time) in snapshots {
                        scene.configure(EggSceneSnapshot(elapsed:time,theme:theme,route:route,platformJourney:true))
                        XCTAssertEqual(scene.children.count,count);XCTAssertEqual(actor.children.count,1)
                        XCTAssertTrue(actor.position.x.isFinite);XCTAssertTrue(actor.position.y.isFinite)
                        XCTAssertLessThan(actor.calculateAccumulatedFrame().maxY,height)
                        if name=="wait" {XCTAssertEqual((scene.childNode(withName:"nextLandingCue") as? SKLabelNode)?.text,"—")}
                        if name=="final" {
                            let nest=try XCTUnwrap(scene.childNode(withName:"destination"))
                            XCTAssertFalse(nest.isHidden);XCTAssertEqual(nest.position.x,actor.position.x,accuracy:0.001)
                        }
                        let attachment=XCTAttachment(image:UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)).cgImage()))
                        attachment.name="GAME29 level\(level) \(theme.rawValue) h\(Int(height)) \(name)";attachment.lifetime = .keepAlways;add(attachment)
                    }
                    scene.configure(EggSceneSnapshot(elapsed:complete.duration,reduceMotion:true,theme:theme,route:complete,platformJourney:true))
                    XCTAssertEqual(actor.position.y,height*0.31,accuracy:0.001)
                }
            }
        }
    }
    @MainActor
    func testRestLessonsSaveActual8TwentyAndSixteenNotesAndUnlockOnlyNext() async throws {
        for level in [5,6,9] {try await checkSave(level:level,fail:false)}
    }
    @MainActor
    func testRestSaveConflictDoesNotUnlockUntilActualRetrySucceeds() async throws {
        try await checkSave(level:6,fail:true)
    }
    @MainActor
    private func checkSave(level:Int,fail:Bool) async throws {
        let name="BeatLabTests.Rest.\(UUID().uuidString)",defaults=try XCTUnwrap(UserDefaults(suiteName:name));defer{defaults.removePersistentDomain(forName:name)}
        let repo=ProgressRepository(defaults:defaults),catalog=try LessonCatalog.bundled().lessons
        var progress=PracticeProgress()
        for lesson in catalog.prefix(level-1) {
            var session=try TimingSession(targets:lesson.pattern.targets(bpm:lesson.bpm,bars:4,epoch:100));for target in session.targets{session.tap(at:target.time)}
            progress.record(lesson,summary:session.summary)
        }
        try repo.save(progress);let original=try XCTUnwrap(defaults.data(forKey:ProgressRepository.storageKey))
        let store=PracticeStore(repository:repo),audio=MetronomeAudio(),lesson=catalog[level-1];defer{audio.stop()}
        store.select(lesson);store.start(lesson,audio:audio,eggMission:true)
        for _ in 0..<40 where store.phase == .preparing {try await Task.sleep(nanoseconds:50_000_000)}
        XCTAssertTrue(store.isEggMission);XCTAssertFalse(audio.practiceGrooveAvailable)
        let route=try XCTUnwrap(store.runnerRoute);XCTAssertEqual(route.targets.count,level == 5 ? 8 : level == 6 ? 20 : 16)
        let grid=try XCTUnwrap(route.grid),cell=try XCTUnwrap((0..<grid.steps).first{route.cellTarget($0)==nil})
        store.tap(at:route.epoch+grid.start+(Double(cell)+0.5)*grid.interval)
        XCTAssertEqual(store.latestHit?.grade,.extra)
        store.cancel(audio:audio);XCTAssertEqual(store.progress.results.count,level-1)
        store.start(lesson,audio:audio,eggMission:true)
        for _ in 0..<40 where store.phase == .preparing {try await Task.sleep(nanoseconds:50_000_000)}
        let restarted=try XCTUnwrap(store.runnerRoute);XCTAssertTrue(restarted.hits.isEmpty)
        for target in restarted.targets {store.tap(at:target.time)}
        if fail {defaults.set(Data("{\"schemaVersion\":99}".utf8),forKey:ProgressRepository.storageKey)}
        for _ in 0..<430 where store.phase == .playing {try await Task.sleep(nanoseconds:50_000_000)}
        XCTAssertEqual(store.phase,.finished);XCTAssertEqual(store.summary?.matched.count,restarted.targets.count)
        XCTAssertEqual(store.summary?.extraCount,0);XCTAssertEqual(store.summary?.missedCount,0);XCTAssertEqual(store.stars,3)
        if fail {
            XCTAssertTrue(store.needsSaveRetry);XCTAssertFalse(store.resultSaved);XCTAssertFalse(store.unlocked(catalog[level]))
            store.retrySave();XCTAssertFalse(store.resultSaved)
            defaults.set(original,forKey:ProgressRepository.storageKey);store.retrySave()
        }
        XCTAssertTrue(store.resultSaved);XCTAssertFalse(store.needsSaveRetry)
        let restored=PracticeStore(repository:repo);XCTAssertEqual(restored.progress.results[lesson.id]?.stars,3)
        XCTAssertTrue(restored.unlocked(catalog[level]));if level<9 {XCTAssertFalse(restored.unlocked(catalog[level+1]))}
    }
}


final class SixteenthIslandLessonTests: XCTestCase {
    private func fixture(_ level:Int,hits:[TimingHit]=[],alignment:Double=0) throws -> RunnerRoute {
        let lesson=try LessonCatalog.bundled().lessons[level-1]
        return try XCTUnwrap(RunnerRoute(targets:lesson.pattern.targets(bpm:lesson.bpm,bars:4,epoch:100),hits:hits,epoch:100,endTime:100+1200/Double(lesson.bpm)+0.18,alignment:alignment))
    }
    func testReviewedHighDensityTargetsAndAllBaseProfileFallbacks() throws {
        let lessons=try LessonCatalog.bundled().lessons
        let bpms=[60,65,60,65,70,70,60,65,75,70],divisions=[1,1,2,2,1,2,4,4,2,4]
        let hands=[false,true,false,true,false,true,false,true,true,true],rests=[false,false,false,false,true,true,false,false,true,true]
        for i in lessons.indices {
            let profile=try XCTUnwrap(IslandLesson.profile(lessons[i]))
            XCTAssertEqual(profile.number,i+1);XCTAssertEqual(profile.bpm,bpms[i]);XCTAssertEqual(profile.stepsPerBeat,divisions[i]);XCTAssertEqual(profile.usesBothHands,hands[i]);XCTAssertEqual(profile.hasRests,rests[i])
            XCTAssertNil(IslandLesson.profile(try lessons[i].atTempo(bpms[i]+5)))
        }
        for level in [7,8,10] {
            let route=try fixture(level),grid=try XCTUnwrap(route.grid),interval=level == 7 ? 0.25 : level == 8 ? 3.0/13 : 3.0/14,bpm=level == 7 ? 60.0 : level == 8 ? 65.0 : 70.0
            let barIDs=level == 10 ? [0,1,3,5,6,7,9,11,12,14] : Array(0..<16)
            let ids=(0..<4).flatMap{bar in barIDs.map{bar*16+$0}}
            XCTAssertEqual(route.targets.map(\.id),ids);XCTAssertEqual(route.targets.count,level == 10 ? 40 : 64)
            XCTAssertEqual(grid.steps,64);XCTAssertEqual(grid.interval,interval,accuracy:1e-10);XCTAssertEqual(grid.start,240/bpm,accuracy:1e-10)
            XCTAssertEqual(route.countInRemaining(at:0,stepsPerBeat:4),4);XCTAssertEqual(route.duration,1200/bpm+0.18,accuracy:1e-10)
            for target in route.targets {XCTAssertEqual(target.time-100,240/bpm+Double(target.id)*interval,accuracy:1e-10)}
            var object=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(lessons[level-1])) as? [String:Any])
            object["bars"]=3
            XCTAssertNil(IslandLesson.profile(try JSONDecoder().decode(Lesson.self,from:JSONSerialization.data(withJSONObject:object))))
            object["bars"]=4;object["id"]="unknown-authored-profile"
            XCTAssertNil(IslandLesson.profile(try JSONDecoder().decode(Lesson.self,from:JSONSerialization.data(withJSONObject:object))))
        }
    }
    func testActualNearestMidpointTieDuplicateAndAfterBoundaryForEveryAlignment() throws {
        for level in [7,8,10] {
            let route=try fixture(level),mid=(route.targets[0].time+route.targets[1].time)/2
            for alignment in [-0.25,0,0.25] {
                var exact=try TimingSession(targets:route.targets,calibrationOffset:alignment)
                XCTAssertEqual(exact.tap(at:mid+alignment)?.targetID,0,"Exact tie selects earliest actual note")
                XCTAssertEqual(exact.hits.last?.grade,.late)
                XCTAssertEqual(exact.tap(at:mid+alignment)?.grade,.extra,"Duplicate cannot shift to unused neighbor")
                XCTAssertEqual(exact.tap(at:mid+alignment+1e-6)?.targetID,1);XCTAssertEqual(exact.hits.last?.grade,.early)
                var close=try TimingSession(targets:route.targets,calibrationOffset:alignment)
                XCTAssertEqual(close.tap(at:mid+alignment-1e-6)?.targetID,0)
                XCTAssertEqual(close.tap(at:mid+alignment+1e-6)?.targetID,1)
                XCTAssertEqual(close.summary.matched.count,2)
                let played=try fixture(level,hits:close.hits,alignment:alignment),t=mid+alignment-100+1e-6
                let before=try XCTUnwrap(DenseJourneyFrame.sample(route:played,elapsed:t-1e-7,reduced:false)),after=try XCTUnwrap(DenseJourneyFrame.sample(route:played,elapsed:t+1e-7,reduced:false))
                XCTAssertEqual(before.world.step,after.world.step,accuracy:1e-5);XCTAssertEqual(before.world.camera,after.world.camera,accuracy:1e-5);XCTAssertEqual(before.height,after.height,accuracy:1e-5)
            }
        }
    }
    func testAcceptedBurstSequenceKeepsBoundedArcsAndContinuousActivePose() throws {
        for level in [7,8,10] {
            let empty=try fixture(level);var matcher=try TimingSession(targets:empty.targets)
            for pair in stride(from:0,to:empty.targets.count,by:2) {
                let a=empty.targets[pair],b=empty.targets[pair+1],offset=min(0.18,(b.time-a.time)/2-1e-6)
                XCTAssertEqual(matcher.tap(at:a.time+offset)?.targetID,a.id);XCTAssertEqual(matcher.tap(at:b.time-offset)?.targetID,b.id)
            }
            XCTAssertEqual(matcher.summary.matched.count,empty.targets.count)
            let route=try fixture(level,hits:matcher.hits)
            for hit in route.journeyHits {
                let t=hit.inputTime-100
                let before=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:t-1e-6,reduced:false)),after=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:t+1e-6,reduced:false))
                XCTAssertEqual(before.height,after.height,accuracy:0.0001);XCTAssertEqual(before.world.step,after.world.step,accuracy:0.0001);XCTAssertEqual(before.world.camera,after.world.camera,accuracy:0.0001)
                if before.height>1e-5 {XCTAssertEqual(try XCTUnwrap(before.poseAge),try XCTUnwrap(after.poseAge),accuracy:0.0001)}
            }
            // Reviewed legal sequence: at most two concurrent arcs; mathematical
            // saturation bound is independent of the production summation loop.
            let bound=tanh(2.0)/tanh(1.0)
            for sample in 0...Int(route.duration*240) {
                let frame=try XCTUnwrap(DenseJourneyFrame.sample(route:route,elapsed:Double(sample)/240,reduced:false))
                XCTAssertGreaterThanOrEqual(frame.height,0);XCTAssertLessThanOrEqual(frame.height,bound+1e-8)
                XCTAssertGreaterThanOrEqual(frame.world.step,0);XCTAssertLessThanOrEqual(frame.world.step,Double(empty.targets.count)+1e-8)
            }
            XCTAssertEqual(DenseJourneyFrame.sample(route:route,elapsed:route.duration,reduced:true)?.world.step,Double(empty.targets.count))
            XCTAssertEqual(DenseJourneyFrame.sample(route:route,elapsed:route.duration,reduced:true)?.height,0)
        }
    }
    func testMixedRestIsNotATargetButNearbyLegalInputStillGetsHonestGrade() throws {
        let empty=try fixture(10),grid=try XCTUnwrap(empty.grid),rest=grid.start+2.5*grid.interval
        XCTAssertTrue(empty.isRest(at:rest));XCTAssertNil(empty.cellTarget(2))
        var matcher=try TimingSession(targets:empty.targets)
        XCTAssertEqual(matcher.tap(at:100+rest)?.targetID,3,"214ms cell center is inside next note's180ms window")
        XCTAssertEqual(matcher.hits.last?.grade,.early);XCTAssertEqual(matcher.tap(at:100+rest)?.grade,.extra)
        let played=try fixture(10,hits:matcher.hits)
        XCTAssertEqual(played.accepted,[3]);XCTAssertEqual(DenseJourneyFrame.sample(route:played,elapsed:rest+0.20,reduced:true)?.world.step,1)
        var perfect=try TimingSession(targets:empty.targets);for target in empty.targets{perfect.tap(at:target.time)}
        let complete=try fixture(10,hits:perfect.hits)
        for cell in 0..<64 where complete.cellTarget(cell)==nil {
            let t=grid.start+(Double(cell)+0.5)*grid.interval
            XCTAssertEqual(DenseJourneyFrame.sample(route:complete,elapsed:t,reduced:false)?.world.recovery.phase,.idle)
        }
        XCTAssertTrue(empty.isRest(at:empty.duration));XCTAssertEqual(grid.cellIndex(at:empty.duration),63)
        let missed=try XCTUnwrap(DenseJourneyFrame.sample(route:empty,elapsed:empty.relativeTimes[0]+0.30,reduced:false))
        XCTAssertEqual(missed.world.step,0);XCTAssertEqual(missed.world.recovery.phase,.falling)
    }
    @MainActor
    func testNativeClosestBurstAnd64thOr40thIslandAcrossAllThemesViewportsAndDark() throws {
        for level in [7,8,10] {
            let empty=try fixture(level),mid=(empty.targets[0].time+empty.targets[1].time)/2
            var close=try TimingSession(targets:empty.targets);close.tap(at:mid-1e-6);close.tap(at:mid+1e-6)
            let burst=try fixture(level,hits:close.hits)
            var all=try TimingSession(targets:empty.targets);for target in empty.targets{all.tap(at:target.time)}
            let complete=try fixture(level,hits:all.hits)
            for theme in RunnerTheme.allCases {
                for height in [200.0,520.0] {
                    let window=UIWindow(frame:CGRect(x:0,y:0,width:375,height:812)),controller=UIViewController();controller.overrideUserInterfaceStyle = .dark
                    let view=SKView(frame:CGRect(x:0,y:0,width:375,height:height)),scene=EggSpriteScene(size:CGSize(width:375,height:height))
                    window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
                    defer{scene.detach();view.presentScene(nil);window.isHidden=true}
                    let actor=try XCTUnwrap(scene.childNode(withName:"player")),count=scene.children.count
                    var previous:CGPoint?
                    for (name,route,t) in [("before",burst,mid-100-0.001),("after",burst,mid-100+0.001),("overlap",burst,mid-100+0.075),("last",complete,complete.duration)] {
                        scene.configure(EggSceneSnapshot(elapsed:t,theme:theme,route:route,platformJourney:true))
                        XCTAssertEqual(scene.children.count,count);XCTAssertEqual(actor.children.count,1);XCTAssertLessThan(actor.calculateAccumulatedFrame().maxY,height)
                        if name=="after",let previous{XCTAssertEqual(actor.position.x,previous.x,accuracy:1);XCTAssertEqual(actor.position.y,previous.y,accuracy:1)}
                        previous=actor.position
                        if name=="last" {
                            let nest=try XCTUnwrap(scene.childNode(withName:"destination"));XCTAssertFalse(nest.isHidden);XCTAssertEqual(nest.position.x,actor.position.x,accuracy:0.001)
                            let background=try XCTUnwrap(scene.childNode(withName:"backdrop"));XCTAssertLessThanOrEqual(background.frame.minX,0);XCTAssertGreaterThanOrEqual(background.frame.maxX,375-1e-6)
                        }
                        let image=UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)).cgImage()),attachment=XCTAttachment(image:image)
                        attachment.name="GAME30 level\(level) \(theme.rawValue) h\(Int(height)) dark \(name)";attachment.lifetime = .keepAlways;add(attachment)
                    }
                    // Check every registered pose in the closest accepted burst,
                    // rather than relying on a single screenshot near its apex.
                    for sample in 0...64 {
                        scene.configure(EggSceneSnapshot(elapsed:mid-100+Double(sample)/240,theme:theme,route:burst,platformJourney:true))
                        XCTAssertLessThan(actor.calculateAccumulatedFrame().maxY,height)
                    }
                }
            }
        }
    }
    @MainActor
    func testHighDensityActualSessionPersists64SixtyFourAndFortyOnly() async throws {
        for level in [7,8,10] {
            let name="BeatLabTests.High.\(UUID().uuidString)",defaults=try XCTUnwrap(UserDefaults(suiteName:name));defer{defaults.removePersistentDomain(forName:name)}
            let repo=ProgressRepository(defaults:defaults),catalog=try LessonCatalog.bundled().lessons,lesson=catalog[level-1]
            let locked=PracticeStore(repository:repo),audio=MetronomeAudio();defer{audio.stop()}
            locked.start(lesson,audio:audio,eggMission:true);XCTAssertEqual(locked.phase,.idle);XCTAssertFalse(audio.isPlaying)
            var progress=PracticeProgress()
            for prior in catalog.prefix(level-1) {var matcher=try TimingSession(targets:prior.pattern.targets(bpm:prior.bpm,bars:4,epoch:100));for target in matcher.targets{matcher.tap(at:target.time)};progress.record(prior,summary:matcher.summary)}
            try repo.save(progress);let store=PracticeStore(repository:repo);store.select(lesson);store.start(lesson,audio:audio,eggMission:true)
            for _ in 0..<40 where store.phase == .preparing{try await Task.sleep(nanoseconds:50_000_000)}
            XCTAssertTrue(store.isEggMission);XCTAssertFalse(audio.practiceGrooveAvailable)
            let route=try XCTUnwrap(store.runnerRoute);XCTAssertEqual(route.targets.count,level == 10 ? 40 : 64)
            for target in route.targets{store.tap(at:target.time)}
            for _ in 0..<440 where store.phase == .playing{try await Task.sleep(nanoseconds:50_000_000)}
            XCTAssertEqual(store.phase,.finished);XCTAssertEqual(store.summary?.matched.count,route.targets.count);XCTAssertEqual(store.summary?.missedCount,0);XCTAssertEqual(store.summary?.extraCount,0);XCTAssertEqual(store.stars,3);XCTAssertTrue(store.resultSaved)
            let restored=PracticeStore(repository:repo);XCTAssertEqual(restored.progress.results[lesson.id]?.stars,3);XCTAssertEqual(restored.progress.results[lesson.id]?.bestBPM,lesson.bpm)
            if level<10{XCTAssertTrue(restored.unlocked(catalog[level]));XCTAssertFalse(restored.unlocked(catalog[level+1]))}else{XCTAssertEqual(restored.progress.results.filter{$0.value.stars>0}.count,10)}
        }
    }
}

final class JourneyResultTests: XCTestCase {
    private func fixture(_ level: Int, count: Int, alignment: Double = 0, lateLast: Bool = false) throws -> (RunnerRoute, TimingSummary, Lesson) {
        let lesson = try LessonCatalog.bundled().lessons[level-1]
        let end = 100 + 20*60/Double(lesson.bpm) + 0.18
        var matcher = try TimingSession(targets:lesson.pattern.targets(bpm:lesson.bpm,bars:4,epoch:100),calibrationOffset:alignment)
        for (index,target) in matcher.targets.prefix(count).enumerated() {
            matcher.tap(at:lateLast && index == count-1 ? end-1e-6 : target.time+alignment)
        }
        return (try XCTUnwrap(RunnerRoute(targets:matcher.targets,hits:matcher.hits,epoch:100,endTime:end,alignment:alignment)),matcher.summary,lesson)
    }
    func testReviewedPartialPassKeepsRealFourteenAndTwentyEightCountsAndTwoStars() throws {
        for (level,count,total,missed) in [(1,14,16,2),(3,28,32,4)] {
            let (route,summary,lesson) = try fixture(level,count:count)
            XCTAssertEqual(summary.targetCount,total);XCTAssertEqual(summary.matched.count,count);XCTAssertEqual(summary.missedCount,missed);XCTAssertEqual(summary.extraCount,0)
            XCTAssertTrue(lesson.passes(summary));XCTAssertEqual(lesson.stars(summary),2,"Reviewed85%/55% pass and80% two-star gates")
            XCTAssertFalse(JourneyResultPresentation.allNotes(route))
            for theme in RunnerTheme.allCases {
                XCTAssertEqual(JourneyResultPresentation.title(theme:theme,passed:true,route:route),"跟上 \(count)/\(total) 拍，挑戰通過！")
                XCTAssertEqual(JourneyResultPresentation.caption(theme:theme,passed:true,route:route,compact:true),"跟上 \(count)/\(total) 拍")
                XCTAssertNotEqual(JourneyResultPresentation.title(theme:theme,passed:true,route:route),theme.passed)
            }
            var progress = PracticeProgress();progress.record(lesson,summary:summary)
            XCTAssertEqual(progress.results[lesson.id]?.stars,2);XCTAssertEqual(progress.results[lesson.id]?.bestBPM,lesson.bpm)
        }
        let (all,summary,lesson) = try fixture(1,count:16)
        XCTAssertTrue(JourneyResultPresentation.allNotes(all));XCTAssertEqual(lesson.stars(summary),3)
        XCTAssertEqual(JourneyResultPresentation.title(theme:.cat,passed:true,route:all),RunnerTheme.cat.passed)
        let (zero,z,_) = try fixture(1,count:0)
        XCTAssertEqual(z.missedCount,16);XCTAssertEqual(JourneyResultPresentation.title(theme:.dinosaur,passed:false,route:zero),RunnerTheme.dinosaur.retry)
    }
    func testReviewedResultTailFinishesOnlyExistingCatchOrLateFlightAndIsBounded() throws {
        let first = try fixture(1,count:0).0, half = try fixture(3,count:0).0, mixed = try fixture(10,count:0).0
        // Reviewed60BPM half-grid lastnote19.5, miss19.68, return20.28 versus end20.18.
        XCTAssertEqual(JourneyResultPresentation.settlingDuration(first),0)
        XCTAssertEqual(JourneyResultPresentation.settlingDuration(half),0.10,accuracy:1e-8)
        // Reviewed70BPM mixed lastID62; final rest and recovery leave6/35sec.
        XCTAssertEqual(JourneyResultPresentation.settlingDuration(mixed),6.0/35,accuracy:1e-8)
        let late = try fixture(7,count:64,alignment:0.25,lateLast:true).0
        XCTAssertEqual(late.journeyHits.count,64);XCTAssertEqual(late.journeyHits.last?.targetID,63)
        XCTAssertEqual(JourneyResultPresentation.settlingDuration(late),0.20-1e-6,accuracy:1e-8)
        let terminalMiss = try fixture(7,count:63,alignment:0.25).0
        XCTAssertEqual(JourneyResultPresentation.settlingDuration(terminalMiss),0.60,accuracy:1e-8)
        XCTAssertEqual(DenseAnimationFrame.sample(elapsed:20.18+7e-15,age:0.001,reduceMotion:false,stationary:true),12)
        XCTAssertEqual(DenseAnimationFrame.sample(elapsed:20.18+1e-6,age:0.001,reduceMotion:false,stationary:true),28)
        for route in [first,half,mixed,late,terminalMiss] {
            let tail = JourneyResultPresentation.settlingDuration(route)
            XCTAssertGreaterThanOrEqual(tail,0);XCTAssertLessThanOrEqual(tail,0.80)
            XCTAssertEqual(JourneyResultPresentation.elapsed(route:route,start:100,host:100,reduced:false),route.duration)
            XCTAssertEqual(JourneyResultPresentation.elapsed(route:route,start:100,host:99,reduced:false),route.duration)
            XCTAssertEqual(JourneyResultPresentation.elapsed(route:route,start:100,host:10000,reduced:false),route.duration+tail)
            XCTAssertEqual(JourneyResultPresentation.elapsed(route:route,start:100,host:100,reduced:true),route.duration+tail)
            XCTAssertFalse(JourneyResultPresentation.isAtEnd(route:route,elapsed:route.duration-0.001))
            for time in [Double.nan,.infinity,-.infinity,-1] {
                XCTAssertFalse(JourneyResultPresentation.isAtEnd(route:route,elapsed:time))
                XCTAssertEqual(JourneyResultPresentation.elapsed(route:route,start:100,host:time,reduced:false),route.duration)
            }
        }
        XCTAssertEqual(JourneyResultPresentation.settlingDuration(nil),0)
        let end = half.duration+0.10
        XCTAssertEqual(DenseJourneyFrame.sample(route:half,elapsed:end,reduced:false)?.world.step,0,"Active default still rejects past transport end")
        XCTAssertEqual(DenseJourneyFrame.sample(route:half,elapsed:end,reduced:false,presentationTail:0.10)?.world.recovery.phase,.idle)
        for invalid in [Double.nan,.infinity,-1] { XCTAssertEqual(DenseJourneyFrame.sample(route:late,elapsed:late.duration+0.1,reduced:false,presentationTail:invalid)?.world.step,0) }
    }
    func testReviewedLiveStartSettledTravelAndBoundsAcrossAllTen() throws {
        for level in 1...10 {
            let lesson = try LessonCatalog.bundled().lessons[level-1]
            let total = try lesson.pattern.targets(bpm:lesson.bpm,bars:4,epoch:100).count
            let count = total/2,route = try fixture(level,count:count).0
            let settled = try XCTUnwrap(route.journeyHits.last).inputTime-route.epoch+0.64
            let dense = DenseJourneyFrame.sample(route:route,elapsed:settled,reduced:false)
            let frame = dense?.world ?? PlatformJourneyFrame.sample(route:route,elapsed:settled,reduced:false)
            XCTAssertEqual(frame.step,Double(count),accuracy:1e-8,"Each completed accepted jump contributes exactly one island")
            XCTAssertEqual(frame.camera,Double(count)-1.3,accuracy:1e-8,"Reviewed1.3-island camera lead")
            if let dense { XCTAssertEqual(dense.height,0);XCTAssertEqual(dense.landing,0) }
            let start = route.journeyHits[0].inputTime-route.epoch
            let beginning = DenseJourneyFrame.sample(route:route,elapsed:start,reduced:false)?.world ?? PlatformJourneyFrame.sample(route:route,elapsed:start,reduced:false)
            XCTAssertEqual(beginning.step,0,accuracy:1e-8);XCTAssertEqual(beginning.camera,0,accuracy:1e-8)
            for fraction in [0.0,0.18,0.5,0.95,1.0] {
                if let value = DenseJourneyFrame.sample(route:route,elapsed:route.duration*fraction,reduced:false) {
                    XCTAssertGreaterThanOrEqual(value.world.step,0);XCTAssertLessThanOrEqual(value.world.step,Double(count))
                    XCTAssertGreaterThanOrEqual(value.height,0);XCTAssertLessThanOrEqual(value.height,1+1e-8,"Exact grid-time presses do not overlap authored shorter flights")
                }
            }
            if route.grid?.isDense == true {
                XCTAssertEqual(DenseJourneyFrame.sample(route:route,elapsed:route.duration+0.001,reduced:false)?.world.step,0,"Default active sampler still stops at transport end")
            }
        }
    }
    @MainActor
    func testNativeResultBoundaryPreservesActorTerrainRegistrationAndSettlesAcrossThemesAndSizes() throws {
        let cases:[(String,RunnerRoute,Bool)] = [("partial14",try fixture(1,count:14).0,true),("partial28",try fixture(3,count:28).0,true),("lastmiss",try fixture(3,count:31).0,true),("late64",try fixture(7,count:64,alignment:0.25,lateLast:true).0,true),("boundaryMiss63",try fixture(7,count:63,alignment:0.25).0,true),("zero",try fixture(10,count:0).0,false)]
        for (name,route,passed) in cases { for theme in RunnerTheme.allCases { for height in [200.0,520.0] {
            let window = UIWindow(frame:CGRect(x:0,y:0,width:375,height:812)),controller = UIViewController();controller.overrideUserInterfaceStyle = .dark
            let view = SKView(frame:CGRect(x:0,y:0,width:375,height:height)),scene = EggSpriteScene(size:CGSize(width:375,height:height))
            window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
            defer{scene.detach();view.presentScene(nil);window.isHidden=true}
            let actor = try XCTUnwrap(scene.childNode(withName:"player")),sprite = try XCTUnwrap(actor.childNode(withName:"characterPrimary") as? SKSpriteNode),nest = try XCTUnwrap(scene.childNode(withName:"destination"))
            scene.configure(EggSceneSnapshot(elapsed:route.duration,theme:theme,route:route,platformJourney:true))
            let position = actor.position,rotation=actor.zRotation,texture=sprite.texture,anchor=sprite.anchorPoint,scale=CGPoint(x:actor.xScale,y:actor.yScale),nestX=nest.position.x,nodeCount=scene.children.count
            scene.configure(EggSceneSnapshot(elapsed:route.duration,finishedPassed:passed,theme:theme,route:route,platformJourney:true))
            let start = try XCTUnwrap(scene.resultStartHost),tail = JourneyResultPresentation.settlingDuration(route)
            scene.render(at:start)
            XCTAssertEqual(actor.position.x,position.x,accuracy:1e-8);XCTAssertEqual(actor.position.y,position.y,accuracy:1e-8);XCTAssertEqual(actor.zRotation,rotation)
            XCTAssertEqual(actor.xScale,scale.x);XCTAssertEqual(actor.yScale,scale.y);XCTAssertTrue(sprite.texture === texture);XCTAssertEqual(sprite.anchorPoint,anchor);XCTAssertEqual(nest.position.x,nestX,accuracy:1e-8)
            for (frame,age) in [("handoff",0.0),("settling",tail/2),("settled",tail+0.01)] {
                scene.render(at:start+age)
                XCTAssertEqual(scene.children.count,nodeCount);XCTAssertEqual(actor.children.count,1);XCTAssertEqual(sprite.alpha,1)
                XCTAssertLessThan(actor.calculateAccumulatedFrame().maxY,height);XCTAssertGreaterThanOrEqual(actor.calculateAccumulatedFrame().minY,0)
                if frame == "settled" {
                    XCTAssertEqual(actor.position.y,height*0.31,accuracy:1e-5)
                    XCTAssertEqual(nest.position.x-actor.position.x,Double(route.targets.count-route.journeyHits.count)*375*0.27,accuracy:1e-6,"Unplayed islands remain ahead; passing flag cannot invent travel")
                    XCTAssertTrue(view.isPaused);XCTAssertTrue(try XCTUnwrap(scene.childNode(withName:"safetyCatch")).isHidden)
                }
                let attachment = XCTAttachment(image:UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)).cgImage()));attachment.name="GAME31 \(name) \(theme.rawValue) h\(Int(height)) dark \(frame)";attachment.lifetime = .keepAlways;add(attachment)
            }
        } } }
    }
    @MainActor
    func testResultCallbackIsFiniteDoesNotRestartAndResetsOnPrepareSuspendReduceAndDetach() async throws {
        let route = try fixture(3,count:0).0
        let window = UIWindow(frame:CGRect(x:0,y:0,width:375,height:812)),controller = UIViewController(),view=SKView(frame:CGRect(x:0,y:0,width:375,height:300)),scene=EggSpriteScene(size:CGSize(width:375,height:300))
        window.rootViewController=controller;controller.view.addSubview(view);window.makeKeyAndVisible();view.presentScene(scene)
        defer{scene.detach();view.presentScene(nil);window.isHidden=true}
        var state=EggSceneSnapshot(elapsed:route.duration,finishedPassed:false,theme:.cat,route:route,platformJourney:true)
        scene.configure(state);let start=try XCTUnwrap(scene.resultStartHost);XCTAssertFalse(view.isPaused)
        scene.configure(state);XCTAssertEqual(scene.resultStartHost,start)
        try await Task.sleep(nanoseconds:350_000_000);XCTAssertTrue(view.isPaused)
        let count=scene.callbackCount;try await Task.sleep(nanoseconds:80_000_000);XCTAssertEqual(scene.callbackCount,count)
        scene.configure(state);XCTAssertEqual(scene.resultStartHost,start);XCTAssertTrue(view.isPaused)
        scene.configure(EggSceneSnapshot(preparing:true,theme:.cat,platformJourney:true));XCTAssertNil(scene.resultStartHost);XCTAssertTrue(view.isPaused)
        scene.configure(state);XCTAssertGreaterThan(try XCTUnwrap(scene.resultStartHost),start)
        state.suspended=true;scene.configure(state);XCTAssertTrue(view.isPaused)
        state.suspended=false;state.reduceMotion=true;scene.configure(state);XCTAssertTrue(view.isPaused)
        let player=try XCTUnwrap(scene.childNode(withName:"player"));XCTAssertEqual(player.position.y,93,accuracy:1e-8)
        scene.detach();XCTAssertNil(scene.resultStartHost);XCTAssertTrue(view.isPaused)
        scene.configure(EggSceneSnapshot(elapsed:.nan,finishedPassed:false,theme:.cat,route:route,platformJourney:true));XCTAssertNil(scene.resultStartHost);XCTAssertTrue(view.isPaused)
    }
    @MainActor
    func testActualPartialStoreFinishKeepsTwoStarsSavesMissesAndOriginalUnlocks() async throws {
        let catalog=try LessonCatalog.bundled().lessons
        for (level,matched,missed) in [(1,14,2),(3,28,4)] {
            let name="BeatLabTests.Result.\(UUID().uuidString)",defaults=try XCTUnwrap(UserDefaults(suiteName:name));defer{defaults.removePersistentDomain(forName:name)}
            let repository=ProgressRepository(defaults:defaults),lesson=catalog[level-1]
            var progress=PracticeProgress()
            for prior in catalog.prefix(level-1) { var session=try TimingSession(targets:prior.pattern.targets(bpm:prior.bpm,bars:4,epoch:100));for target in session.targets{session.tap(at:target.time)};progress.record(prior,summary:session.summary) }
            try repository.save(progress)
            let store=PracticeStore(repository:repository),audio=MetronomeAudio();defer{audio.stop()}
            store.select(lesson);store.start(lesson,audio:audio,eggMission:true)
            for _ in 0..<40 where store.phase == .preparing{try await Task.sleep(nanoseconds:50_000_000)}
            let route=try XCTUnwrap(store.runnerRoute);for target in route.targets.prefix(matched){store.tap(at:target.time)}
            for _ in 0..<440 where store.phase == .playing{try await Task.sleep(nanoseconds:50_000_000)}
            XCTAssertEqual(store.phase,.finished);XCTAssertEqual(store.stars,2);XCTAssertEqual(store.summary?.matched.count,matched);XCTAssertEqual(store.summary?.missedCount,missed);XCTAssertEqual(store.summary?.extraCount,0);XCTAssertTrue(store.resultSaved);XCTAssertFalse(audio.isPlaying)
            let finished=try XCTUnwrap(store.runnerRoute);XCTAssertEqual(finished.journeyHits.count,matched)
            let restored=PracticeStore(repository:repository);XCTAssertEqual(restored.progress.results[lesson.id]?.stars,2);XCTAssertTrue(restored.unlocked(catalog[level]));XCTAssertFalse(restored.unlocked(catalog[level+1]))
        }
    }
}
