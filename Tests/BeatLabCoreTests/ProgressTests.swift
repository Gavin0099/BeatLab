import XCTest
@testable import BeatLabCore

final class ProgressTests: XCTestCase {
    private func isolated(_ body: (UserDefaults, ProgressRepository) throws -> Void) throws {
        let name = "BeatLabTests.Progress.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults, ProgressRepository(defaults: defaults))
    }
    func testProgressModeCalibrationAndBestScoresSurviveRepositoryRestart() throws {
        try isolated { defaults, repository in
            let lessons = try LessonCatalog.bundled().lessons, lesson = lessons[0]
            var session = try TimingSession(targets: lesson.pattern.targets(bpm: lesson.bpm, bars: lesson.bars, epoch: 0))
            for target in session.targets { session.tap(at: target.time) }
            var progress = PracticeProgress(); progress.record(lesson, summary: session.summary)
            progress.mode = .standard
            progress.calibration = try TimingCalibration.estimate(errors: Array(repeating: 0.05, count: 20), route: "speaker", sampleRate: 48000)
            try repository.save(progress)
            let restored = ProgressRepository(defaults: defaults).load()
            XCTAssertEqual(restored.1, .restored)
            XCTAssertEqual(restored.0, progress)
            XCTAssertTrue(restored.0.isUnlocked(lessons[1].id, in: lessons))
            var worse = try TimingSession(targets: session.targets); worse.tap(at: session.targets[0].time)
            progress.record(lesson, summary: worse.summary)
            XCTAssertEqual(progress.results[lesson.id]?.stars, 3)
        }
    }
    func testCorruptionRecoveryAndFutureSchemaPreservedUntilExplicitReset() throws {
        try isolated { defaults, repository in
            defaults.set(Data("bad json".utf8), forKey: ProgressRepository.storageKey)
            XCTAssertEqual(repository.load().1, .corrupt)
            try repository.save(.init()); XCTAssertEqual(repository.load().1, .restored)
            let future = Data("{\"schemaVersion\":99,\"opaque\":\"retain\"}".utf8)
            defaults.set(future, forKey: ProgressRepository.storageKey)
            XCTAssertEqual(repository.load().1, .futureVersion)
            XCTAssertThrowsError(try repository.save(.init()))
            XCTAssertEqual(defaults.data(forKey: ProgressRepository.storageKey), future)
            repository.reset(); try repository.save(.init())
            XCTAssertEqual(repository.load().1, .restored)
        }
    }
    func testMalformedPersistedScoreIsRejected() throws {
        try isolated { _, repository in
            var progress = PracticeProgress()
            progress.results["first-beat"] = LessonProgress(stars: 4, bestPerfectRate: 1, bestBPM: 60)
            XCTAssertThrowsError(try repository.save(progress))
            XCTAssertEqual(repository.load().1, .new)
        }
    }
}
