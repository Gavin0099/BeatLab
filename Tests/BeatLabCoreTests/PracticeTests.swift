import XCTest
@testable import BeatLabCore

final class PracticeTests: XCTestCase {
    private func target(_ id: Int, _ time: Double) -> TimingTarget {
        TimingTarget(id: id, time: time, stroke: .right)
    }
    func testSignedGradesAndPerfectBoundariesUseSpecifiedOffsets() throws {
        var session = try TimingSession(targets: [target(0, 10), target(1, 11), target(2, 12), target(3, 13)])
        XCTAssertEqual(session.tap(at: 9.94)?.grade, .early)
        XCTAssertEqual(session.tap(at: 11.05)?.grade, .perfect)
        XCTAssertEqual(session.tap(at: 11.95)?.grade, .perfect)
        XCTAssertEqual(session.tap(at: 13.06)?.grade, .late)
        XCTAssertEqual(try XCTUnwrap(session.summary.meanSignedError), 0, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(session.summary.meanAbsoluteError), 0.055, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(session.summary.standardDeviation), sqrt(0.00305), accuracy: 1e-9)
    }
    func testNearestTieChoosesEarlierAndDuplicateStaysExtra() throws {
        var session = try TimingSession(targets: [target(0, 1), target(1, 1.2)])
        XCTAssertEqual(session.tap(at: 1.1)?.targetID, 0)
        XCTAssertEqual(session.tap(at: 1.1)?.grade, .extra)
        XCTAssertEqual(session.tap(at: 1.2)?.targetID, 1)
        XCTAssertEqual(session.summary.extraCount, 1)
    }
    func testWindowMissExtraRestAndInvalidInput() throws {
        let pattern = RhythmPattern(stepsPerBeat: 1, steps: [.right, .rest, .left, .rest])
        let targets = try pattern.targets(bpm: 60, bars: 1, epoch: 0, countInBeats: 0)
        XCTAssertEqual(targets.map(\.time), [0, 2])
        var session = try TimingSession(targets: targets)
        XCTAssertNil(session.tap(at: .nan))
        XCTAssertEqual(session.tap(at: 1)?.grade, .extra) // rest is not a target
        XCTAssertEqual(session.tap(at: 0.18)?.targetID, 0)
        XCTAssertEqual(session.tap(at: 2.181)?.grade, .extra)
        XCTAssertEqual(session.summary.missedCount, 1)
        XCTAssertEqual(session.summary.hitRate, 0.5)
        XCTAssertEqual(session.summary.extraCount, 2)
    }
    func testCalibrationRemovesKnownOffsetAndRejectsUnstableOrWrongRoute() throws {
        let calibration = try TimingCalibration.estimate(errors: Array(repeating: 0.080, count: 20), route: "speaker", sampleRate: 48000)
        XCTAssertTrue(calibration.valid(for: "speaker", sampleRate: 48000))
        XCTAssertFalse(calibration.valid(for: "headphones", sampleRate: 48000))
        XCTAssertFalse(calibration.valid(for: "speaker", sampleRate: 44100))
        var session = try TimingSession(targets: [target(0, 5)], calibrationOffset: calibration.offset)
        XCTAssertEqual(session.tap(at: 5.08)?.grade, .perfect)
        XCTAssertEqual(try XCTUnwrap(session.summary.meanAbsoluteError), 0, accuracy: 1e-9)
        XCTAssertThrowsError(try TimingCalibration.estimate(errors: Array(repeating: 0, count: 15), route: "speaker", sampleRate: 48000))
        XCTAssertThrowsError(try TimingCalibration.estimate(errors: (0..<20).map { $0 < 10 ? -0.15 : 0.15 }, route: "speaker", sampleRate: 48000))
        XCTAssertThrowsError(try TimingSession(targets: [target(0, 1), target(0, 2)]))
        XCTAssertThrowsError(try TimingSession(targets: [target(0, .infinity)]))
    }
    func testCatalogAllTenLessonsWalkThroughAndUnlockWithoutUIChanges() throws {
        let lessons = try LessonCatalog.bundled().lessons
        XCTAssertEqual(lessons.count, 10)
        var progress = PracticeProgress()
        for (index, lesson) in lessons.enumerated() {
            XCTAssertTrue(progress.isUnlocked(lesson.id, in: lessons))
            if index + 1 < lessons.count { XCTAssertFalse(progress.isUnlocked(lessons[index + 1].id, in: lessons)) }
            let targets = try lesson.pattern.targets(bpm: lesson.bpm, bars: lesson.bars, epoch: 100)
            let expectedCount = lesson.pattern.steps.filter { $0 != .rest }.count * lesson.bars
            XCTAssertEqual(targets.count, expectedCount)
            var session = try TimingSession(targets: targets)
            for target in targets { session.tap(at: target.time) }
            XCTAssertTrue(lesson.passes(session.summary))
            XCTAssertEqual(lesson.stars(session.summary), 3)
            progress.record(lesson, summary: session.summary)
            XCTAssertEqual(progress.results[lesson.id]?.bestBPM, lesson.bpm)
        }
        XCTAssertEqual(progress.results.count, 10)
    }
    func testMissesAndSpamCannotPassWithPerfectMatchedTaps() throws {
        let lesson = try LessonCatalog.bundled().lessons[0]
        let targets = try lesson.pattern.targets(bpm: lesson.bpm, bars: lesson.bars, epoch: 0)
        var misses = try TimingSession(targets: targets)
        misses.tap(at: targets[0].time)
        XCTAssertFalse(lesson.passes(misses.summary))
        var spam = try TimingSession(targets: targets)
        for target in targets { spam.tap(at: target.time); spam.tap(at: target.time) }
        XCTAssertEqual(spam.summary.perfectRate, 1)
        XCTAssertFalse(lesson.passes(spam.summary))
        var progress = PracticeProgress(); progress.record(lesson, summary: spam.summary)
        XCTAssertNil(progress.results[lesson.id])
    }
    func testInvalidCatalogVersionDuplicateAndEmptyPatternFailClosed() throws {
        XCTAssertThrowsError(try LessonCatalog.load(Data("{\"schemaVersion\":2,\"lessons\":[]}".utf8)))
        XCTAssertThrowsError(try RhythmPattern(stepsPerBeat: 1, steps: [.rest, .rest, .rest, .rest]).validate())
        XCTAssertThrowsError(try RhythmPattern(stepsPerBeat: 4, steps: [.right]).validate())
        let lesson = try LessonCatalog.bundled().lessons[0]
        let data = try JSONEncoder().encode([lesson, lesson])
        let duplicated = Data("{\"schemaVersion\":1,\"lessons\":".utf8) + data + Data("}".utf8)
        XCTAssertThrowsError(try LessonCatalog.load(duplicated))
    }
    func testBestBPMOnlyAdvancesAfterHigherTempoPasses() throws {
        let base = try LessonCatalog.bundled().lessons[0]
        let challenge = try base.atTempo(80)
        XCTAssertThrowsError(try base.atTempo(30))
        var session = try TimingSession(targets: challenge.pattern.targets(bpm: 80, bars: 4, epoch: 0))
        for target in session.targets { session.tap(at: target.time) }
        var progress = PracticeProgress(); progress.record(challenge, summary: session.summary)
        XCTAssertEqual(progress.results[base.id]?.bestBPM, 80)
        let faster = try base.atTempo(120)
        let failed = try TimingSession(targets: faster.pattern.targets(bpm: 120, bars: 4, epoch: 0))
        progress.record(faster, summary: failed.summary)
        XCTAssertEqual(progress.results[base.id]?.bestBPM, 80)
    }
}
