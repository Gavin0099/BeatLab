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
        XCTAssertEqual(bottom.fall, 1, accuracy: 1e-8)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: empty, elapsed: 4.661, reduced: false).fall, 0)
        let aligned = try routeFixture(alignment: 0.20)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: aligned, elapsed: 4.38, reduced: false).fall, 0)
        XCTAssertEqual(PlatformJourneyFrame.sample(route: aligned, elapsed: 4.62, reduced: false).fall, 1, accuracy: 1e-8)
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
            scene.configure(EggSceneSnapshot(elapsed: 4.42, theme: theme, route: try routeFixture(), platformJourney: true))
            XCTAssertLessThan(player.position.y, 100)
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "safetyCatch")).isHidden)
            scene.configure(EggSceneSnapshot(elapsed: 4.661, theme: theme, route: try routeFixture(), platformJourney: true))
            XCTAssertEqual(player.position.x, 80, accuracy: 1e-8); XCTAssertEqual(player.position.y, 155, accuracy: 1e-8)
            scene.configure(EggSceneSnapshot(elapsed: 0, preparing: true, theme: theme, platformJourney: true))
            XCTAssertEqual(player.position.x, 80, accuracy: 1e-8)
            XCTAssertEqual(scene.children.count, count); XCTAssertNil(player.physicsBody); XCTAssertFalse(player.hasActions())
            scene.configure(EggSceneSnapshot(elapsed: 20, finishedPassed: true, theme: theme, route: route, platformJourney: true))
            XCTAssertFalse(try XCTUnwrap(scene.childNode(withName: "destination")).isHidden)
            XCTAssertEqual(player.position.x, try XCTUnwrap(scene.childNode(withName: "destination")).position.x, accuracy: 1e-8)
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
    func testFlightAndFallHaveZeroEndpointVelocityAndAcceleration() {
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
        for time in [Double.nan, .infinity, -.infinity, -1, 3.99, 100, Double.greatestFiniteMagnitude] {
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
            XCTAssertTrue(character.texture === pack.textures[28], "Standing on a platform cannot animate a running gait")
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
