import Foundation
import XCTest
import BeatLabCore
@testable import BeatLab

final class PracticeStoreTests: XCTestCase {
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
        // A version change between load and finish must fail the repository write.
        let future = Data("{\"schemaVersion\":99,\"future\":true}".utf8)
        defaults.set(future, forKey: ProgressRepository.storageKey)
        for _ in 0..<160 where store.phase == .playing { try await Task.sleep(nanoseconds: 50_000_000) }
        XCTAssertEqual(store.phase, .finished)
        XCTAssertNotNil(store.summary)
        XCTAssertFalse(store.resultSaved)
        XCTAssertTrue(store.needsSaveRetry)
        XCTAssertNil(store.progress.lastLessonID)
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
    }
}
