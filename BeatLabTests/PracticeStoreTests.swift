import Foundation
import XCTest
import SpriteKit
import UIKit
import BeatLabCore
@testable import BeatLab

final class PracticeStoreTests: XCTestCase {
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
        store.tap(at: epoch + 4.125)
        XCTAssertEqual(store.latestHit?.targetID, 0); XCTAssertEqual(store.latestHit?.grade, .late)
        store.cancel(audio: audio)
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
    @MainActor
    func testCompanionScenesUseDistinctLoadedArtAndMotionWithoutChangingAcceptedState() throws {
        let scenes = [RunnerTheme.cat, .robot].map { theme -> EggSpriteScene in
            let scene = EggSpriteScene(size: CGSize(width: 400, height: 400))
            scene.configure(EggSceneSnapshot(elapsed: 4.16, accepted: [0], latestGrade: .perfect, hitAge: 0.16, theme: theme))
            return scene
        }
        let textures = try scenes.map { scene -> SKTexture in
            let player = try XCTUnwrap(scene.childNode(withName: "player"))
            let sprite = try XCTUnwrap(player.childNode(withName: "characterPrimary") as? SKSpriteNode)
            XCTAssertEqual(player.children.count, 1); XCTAssertEqual(sprite.alpha, 1)
            XCTAssertGreaterThan(sprite.size.height, 70); XCTAssertGreaterThan(try XCTUnwrap(sprite.texture).size().width, 100)
            XCTAssertTrue(try XCTUnwrap(scene.childNode(withName: "rock0")).isHidden)
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
            var state = EggSceneSnapshot(elapsed: 4, theme: scene.theme)
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
        var state = EggSceneSnapshot(presentationElapsed: { host in calls += 1; return host - 100 })
        scene.configure(state); scene.render(at: 104)
        XCTAssertFalse(rock.isHidden); XCTAssertTrue(reward.isHidden)
        let previous = rock.position.x; scene.render(at: 104.01)
        XCTAssertLessThan(rock.position.x, previous, "Nodes move between store polls on the existing read-only clock")
        state.accepted = [0]; state.acceptedAction = try hit(0, 104, "perfect"); state.latestAction = try hit(nil, 104.2, "extra")
        scene.configure(state); scene.render(at: 104.24)
        XCTAssertTrue(rock.isHidden); XCTAssertFalse(reward.isHidden); XCTAssertGreaterThan(player.position.y, 60)
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
