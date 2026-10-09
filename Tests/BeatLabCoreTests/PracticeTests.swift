import XCTest
@testable import BeatLabCore

final class PracticeTests: XCTestCase {
    // Independent policy fixture:16 separated notes. +100ms is an existing
    // late matched hit, never Perfect; duplicates are real extra taps.
    private func introductorySummary(matched: Int, perfect: Int = 0, extras: Int = 0) throws -> TimingSummary {
        var session = try TimingSession(targets: (0..<16).map { target($0, 104 + Double($0)) })
        for i in 0..<matched { session.tap(at: 104 + Double(i) + (i < perfect ? 0 : 0.1)) }
        for _ in 0..<extras { session.tap(at: matched == 0 ? 100 : 104.01) }
        return session.summary
    }
    func testIntroOneStarIntegerBoundariesDoNotRequirePerfect() throws {
        for lesson in try LessonCatalog.bundled().lessons.prefix(2) {
            let pass = try introductorySummary(matched: 12, extras: 4)
            XCTAssertEqual(pass.matched.count, 12); XCTAssertEqual(pass.perfectRate, 0)
            XCTAssertEqual(pass.extraCount, 4); XCTAssertEqual(pass.missedCount, 4)
            XCTAssertTrue(lesson.passes(pass)); XCTAssertEqual(lesson.stars(pass), 1)
            for fail in [try introductorySummary(matched: 11), try introductorySummary(matched: 12, extras: 5),
                         try introductorySummary(matched: 0), try introductorySummary(matched: 16, perfect: 16, extras: 16)] {
                XCTAssertFalse(lesson.passes(fail)); XCTAssertEqual(lesson.stars(fail), 0)
            }
        }
    }
    func testIntroTwoAndThreeStarAccuracyRequirementsArePreserved() throws {
        for lesson in try LessonCatalog.bundled().lessons.prefix(2) {
            XCTAssertEqual(lesson.stars(try introductorySummary(matched: 13, perfect: 13)), 1, "13/16 cannot earn two stars despite80% Perfect")
            XCTAssertEqual(lesson.stars(try introductorySummary(matched: 14, perfect: 13)), 2)
            XCTAssertEqual(lesson.stars(try introductorySummary(matched: 16, perfect: 15)), 2)
            XCTAssertEqual(lesson.stars(try introductorySummary(matched: 16, perfect: 16)), 3)
            XCTAssertEqual(lesson.stars(try introductorySummary(matched: 16, perfect: 16, extras: 1)), 1, "One extra still exceeds the original two-star5% budget")
        }
    }
    func testHigherLessonsAndMatcherAccuracyAreNotRelaxed() throws {
        XCTAssertEqual(TimingSession.matchingWindow, 0.180)
        XCTAssertEqual(TimingSession.perfectWindow, 0.050)
        for lesson in try LessonCatalog.bundled().lessons.dropFirst(2) {
            XCTAssertEqual(lesson.requiredHitRate, 0.85); XCTAssertEqual(lesson.requiredPerfectRate, 0.55)
            XCTAssertEqual(lesson.maxExtraRate, 0.1); XCTAssertNil(lesson.requiredTwoStarHitRate)
            var session = try TimingSession(targets: lesson.pattern.targets(bpm: lesson.bpm, bars: lesson.bars, epoch: 100))
            for target in session.targets { session.tap(at: target.time + 0.1) }
            XCTAssertEqual(session.summary.matched.count, session.targets.count)
            XCTAssertEqual(session.summary.perfectRate, 0); XCTAssertEqual(lesson.stars(session.summary), 0)
        }
    }
    func testLegacyCatalogOptionalTierFloorAndTempoCopyAreCompatible() throws {
        let intro = try LessonCatalog.bundled().lessons[0]
        XCTAssertEqual(try intro.atTempo(80).requiredTwoStarHitRate, 0.85)
        var row = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(intro)) as? [String: Any])
        row.removeValue(forKey: "requiredTwoStarHitRate")
        row["requiredHitRate"] = 0.85; row["requiredPerfectRate"] = 0.55; row["maxExtraRate"] = 0.1
        let legacy = try LessonCatalog.load(JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "lessons": [row]])).lessons[0]
        XCTAssertNil(legacy.requiredTwoStarHitRate)
        XCTAssertEqual(legacy.stars(try introductorySummary(matched: 13, perfect: 13)), 0)
        XCTAssertEqual(legacy.stars(try introductorySummary(matched: 14, perfect: 13)), 2)
        XCTAssertEqual(legacy.stars(try introductorySummary(matched: 16, perfect: 16)), 3)
        XCTAssertNil(try legacy.atTempo(80).requiredTwoStarHitRate)
        row["requiredHitRate"] = 0.75; row["requiredPerfectRate"] = 0; row["maxExtraRate"] = 0.25
        let noFloor = try LessonCatalog.load(JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "lessons": [row]])).lessons[0]
        XCTAssertEqual(noFloor.stars(try introductorySummary(matched: 13, perfect: 13)), 2, "Absent field preserves the original customizable tier semantics")
    }
    func testInvalidOptionalTwoStarFloorsFailClosed() throws {
        let intro = try LessonCatalog.bundled().lessons[0]
        var row = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(intro)) as? [String: Any])
        for invalid in [-0.1, 0.74, 1.01] {
            row["requiredTwoStarHitRate"] = invalid
            XCTAssertThrowsError(try LessonCatalog.load(JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "lessons": [row]])))
        }
        row["requiredTwoStarHitRate"] = 0.85
        XCTAssertNoThrow(try LessonCatalog.load(JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "lessons": [row]])))
    }
    func testNewOneStarPersistedUnlockAndExistingBestStarsSurvive() throws {
        let name = "BeatLabTests.IntroPolicy.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name)); defer { defaults.removePersistentDomain(forName: name) }
        let repository = ProgressRepository(defaults: defaults), lessons = try LessonCatalog.bundled().lessons
        let pass = try introductorySummary(matched: 12, extras: 4)
        var progress = PracticeProgress(); progress.record(lessons[0], summary: pass)
        try repository.save(progress)
        progress = repository.load().0
        XCTAssertEqual(progress.results[lessons[0].id]?.stars, 1); XCTAssertEqual(progress.results[lessons[0].id]?.bestPerfectRate, 0)
        XCTAssertTrue(progress.isUnlocked(lessons[1].id, in: lessons)); XCTAssertFalse(progress.isUnlocked(lessons[2].id, in: lessons))
        progress.record(lessons[1], summary: pass); try repository.save(progress)
        let restored = ProgressRepository(defaults: defaults).load().0
        XCTAssertTrue(restored.isUnlocked(lessons[2].id, in: lessons)); XCTAssertFalse(restored.isUnlocked(lessons[3].id, in: lessons))
        progress.results[lessons[0].id] = LessonProgress(stars: 3, bestPerfectRate: 1, bestBPM: 80)
        progress.record(lessons[0], summary: pass); try repository.save(progress)
        XCTAssertEqual(repository.load().0.results[lessons[0].id], progress.results[lessons[0].id])
        XCTAssertEqual(repository.load().0.results[lessons[0].id]?.stars, 3)
        XCTAssertEqual(repository.load().0.results[lessons[0].id]?.bestBPM, 80)
        XCTAssertEqual(repository.load().0.results[lessons[0].id]?.bestPerfectRate, 1)
    }
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
