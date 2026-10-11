import Foundation
import Combine
import BeatLabCore
import AVFoundation
import Darwin

@MainActor
final class PracticeStore: ObservableObject {
    enum Phase: Equatable { case idle, preparing, playing, paused, finished }
    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var progress: PracticeProgress
    @Published private(set) var notice: String?
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var selected: Lesson?
    @Published private(set) var latestHit: TimingHit?
    @Published private(set) var summary: TimingSummary?
    @Published private(set) var stars = 0
    @Published private(set) var isCalibrating = false
    @Published private(set) var elapsed: Double = 0
    @Published private(set) var calibrated = false
    @Published private(set) var practiceBPM = 60
    @Published private(set) var resultSaved = false
    @Published private(set) var calibrationSaved = false
    @Published private(set) var needsSaveRetry = false
    @Published private(set) var isEggMission = false
    @Published private(set) var isComparison = false
    @Published var presentation: RhythmPresentation = .falling
    @Published private(set) var pressedStroke: Stroke?
    @Published private(set) var pressSerial = 0
    @Published private(set) var isResuming = false
    private var audioObservation: AnyCancellable?
    private var projection: PracticeTransportProjection?
    private var frozenElapsed: Double?
    var isActive: Bool { phase == .playing || phase == .preparing || phase == .paused }
    private let repository: ProgressRepository
    private var writable = true
    private var session: TimingSession?
    private var task: Task<Void, Never>?
    private var generation = 0
    private var epoch: Double = 0
    private var endTime: Double = 0
    private var calibrationRoute = ""
    private var calibrationRate: Double = 0
    private var savedOptions: (CountSound, Int, Int)?
    private var pendingProgress: PracticeProgress?
    private weak var feedbackAudio: MetronomeAudio?

    init(repository: ProgressRepository) {
        self.repository = repository
        let loaded = repository.load()
        progress = loaded.0
        switch loaded.1 {
        case .corrupt: notice = "上次進度無法讀取。完成練習後會重新保存。"
        case .futureVersion: notice = "進度需要較新版拍拍冒險。請更新 App 或重設進度。"; writable = false
        default: break
        }
        do { lessons = try LessonCatalog.bundled().lessons }
        catch { notice = "課程無法讀取。你仍可使用自由節拍器。" }
    }
    var mode: InterfaceMode { progress.mode }
    var recommended: Lesson? { progress.recommended(in: lessons) }
    var canPractice: Bool { writable && !lessons.isEmpty }
    var progressVersionConflict: Bool { !writable }
    var diagnosticJSON: String? {
        guard let summary, let session else { return nil }
        struct Export: Encodable {
            let schemaVersion = 1
            let alignment: String
            let route: String
            let sampleRate: Double
            let targets: [TimingTarget]
            let summary: TimingSummary
        }
        let value = Export(alignment: calibrated ? "user_alignment_estimate" : "uncalibrated",
                           route: calibrationRoute, sampleRate: calibrationRate,
                           targets: session.targets, summary: summary)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    func unlocked(_ lesson: Lesson) -> Bool { progress.isUnlocked(lesson.id, in: lessons) }

    func select(_ lesson: Lesson) {
        guard !isActive, !needsSaveRetry, unlocked(lesson) else { return }
        isComparison = false; presentation = .falling; selected = lesson; summary = nil; latestHit = nil; stars = 0; isCalibrating = false; isEggMission = false; phase = .idle
        practiceBPM = lesson.bpm
    }
    func setPracticeBPM(_ value: Int) {
        guard !isActive else { return }
        practiceBPM = min(240, max(selected?.bpm ?? recommended?.bpm ?? 60, value))
    }
    func setMode(_ value: InterfaceMode) { var next = progress; next.mode = value; save(next) }
    func resetProgress() {
        guard !isActive else { return }
        repository.reset(); writable = true; progress = .init(); notice = nil
        pendingProgress = nil; needsSaveRetry = false; resultSaved = false; calibrationSaved = false
    }
    func retrySave() {
        guard var pending = pendingProgress, phase == .finished else { return }
        pending.mode = progress.mode
        guard save(pending) else { return }
        pendingProgress = nil; needsSaveRetry = false
        resultSaved = !isCalibrating; calibrationSaved = isCalibrating
        notice = isCalibrating ? "對齊已保存。換音訊輸出後，請重新對齊。" : nil
    }
    func discardUnsavedResult() {
        guard phase == .finished, needsSaveRetry else { return }
        pendingProgress = nil; needsSaveRetry = false; summary = nil; phase = .idle
        stars = 0; notice = nil; isCalibrating = false
    }

    func start(_ lesson: Lesson, audio: MetronomeAudio, eggMission: Bool = false) {
        guard canPractice, unlocked(lesson), !needsSaveRetry, !isActive else { return }
        do { selected = try lesson.atTempo(max(lesson.bpm, practiceBPM)) }
        catch { notice = "練習速度無法使用。"; return }
        isComparison = false; presentation = .falling
        isCalibrating = false
        isEggMission = eggMission && selected.flatMap(IslandLesson.profile) != nil
        begin(audio: audio, bpm: selected!.bpm)
    }
    #if DEBUG
    func startComparison(_ lesson: Lesson, presentation: RhythmPresentation, audio: MetronomeAudio) {
        guard canPractice, !isActive, !needsSaveRetry, lessons.dropFirst().prefix(2).contains(where: { $0.id == lesson.id }) else { return }
        selected = lesson; practiceBPM = lesson.bpm; self.presentation = presentation
        isComparison = true; isCalibrating = false; isEggMission = IslandLesson.profile(lesson) != nil
        begin(audio: audio, bpm: lesson.bpm)
    }
    #endif
    func startCalibration(audio: MetronomeAudio) {
        guard writable, !needsSaveRetry, !isActive else { return }
        guard audio.supportsCalibration else { notice = "校正請使用內建喇叭或有線耳機。"; return }
        isComparison = false; isCalibrating = true; selected = nil; isEggMission = false
        begin(audio: audio, bpm: 60)
    }
    private func begin(audio: MetronomeAudio, bpm: Int) {
        projection = nil; frozenElapsed = nil; isResuming = false; pressedStroke = nil; pressSerial = 0
        feedbackAudio = nil
        generation += 1; task?.cancel()
        let token = generation
        savedOptions = (audio.sound, audio.gapBars, audio.ladderBars)
        audio.stop(); audio.selectSound(.click); audio.setGap(0); audio.setLadder(0)
        guard let tempo = try? Tempo(bpm: bpm),
              let configuration = try? MetronomeConfiguration(tempo: tempo, timeSignature: .fourFour,
                                                              subdivision: .quarter, accentEnabled: true) else {
            cancel(audio: audio, message: "練習速度無法使用。"); return
        }
        summary = nil; latestHit = nil; stars = 0; session = nil; elapsed = 0; calibrated = false
        resultSaved = false; calibrationSaved = false; pendingProgress = nil; needsSaveRetry = false; notice = nil
        phase = .preparing
        audioObservation = audio.$status.dropFirst().sink { [weak self, weak audio] message in
            guard let self, let audio, self.phase == .paused, message != nil else { return }
            self.cancel(audio: audio, message: "音訊已中斷，請重新開始。")
        }
        audio.start(configuration: configuration, practiceFeedback: !isCalibrating, eggMission: isEggMission && selected.flatMap(IslandLesson.profile) == .first)
        task = Task { [weak self, weak audio] in
            guard let self, let audio else { return }
            let deadline = Self.now() + 2
            var anchor: Double?
            while !Task.isCancelled, token == generation, audio.isPlaying, Self.now() < deadline {
                if let value = audio.audibleEpoch() { anchor = value; break }
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
            guard !Task.isCancelled, token == generation else { return }
            guard let anchor, audio.isPlaying else { cancel(audio: audio, message: "未能開始音訊，請再試一次。"); return }
            epoch = anchor; calibrationRoute = audio.routeIdentity; calibrationRate = audio.sampleRate
            do {
                let targets: [TimingTarget]
                if isCalibrating {
                    targets = (0..<20).map { TimingTarget(id: $0, time: anchor + 4 + Double($0), stroke: .right) }
                    endTime = anchor + 24 + TimingSession.matchingWindow
                } else if let lesson = selected {
                    targets = try lesson.pattern.targets(bpm: lesson.bpm, bars: lesson.bars, epoch: anchor)
                    endTime = anchor + Double(4 + lesson.bars * 4) * 60 / Double(lesson.bpm) + TimingSession.matchingWindow
                } else { throw LessonError.invalidLesson }
                let alignment = progress.calibration
                calibrated = !isCalibrating && audio.supportsCalibration
                    && (alignment?.valid(for: calibrationRoute, sampleRate: calibrationRate) ?? false)
                session = try TimingSession(targets: targets, calibrationOffset: calibrated ? alignment!.offset : 0)
                feedbackAudio = isCalibrating ? nil : audio
                phase = .playing
            } catch { cancel(audio: audio, message: "練習資料無法使用。"); return }
            await watch(audio: audio, token: token)

        }
    }
    private func watch(audio: MetronomeAudio, token: Int) async {
        while !Task.isCancelled, token == generation, phase == .playing {
            guard audio.isPlaying else { cancel(audio: audio, message: "播放已中斷，這次練習不計成績。"); return }
            let host = Self.now()
            let time = projection?.logicalTime(at: host) ?? (projection == nil ? host : epoch + elapsed)
            elapsed = presentationElapsed(at: host)
            if let projection, host >= projection.resumeHost { isResuming = false }
            if time >= endTime { finish(audio: audio); return }
            try? await Task.sleep(nanoseconds: 30_000_000)
        }
    }
    func tap(at host: Double, accessibility: Bool = false, stroke: Stroke? = nil) {
        guard host.isFinite, phase == .playing, !isResuming || projection?.logicalTime(at: host) != nil else { return }
        let time: Double
        if let projection { guard let logical = projection.logicalTime(at: host) else { return }; time = logical }
        else { time = host }
        guard time >= epoch + (isCalibrating ? 4 : 4 * 60 / Double(selected?.bpm ?? 60)) - TimingSession.matchingWindow,
              time <= endTime else { return }
        if accessibility { calibrated = false }
        guard let hit = session?.tap(at: time) else { return }
        pressedStroke = stroke; pressSerial += 1; latestHit = hit
        if !isCalibrating { feedbackAudio?.playPracticeFeedback(hit.grade) }
    }
    func pause(audio: MetronomeAudio) {
        guard phase == .playing, !isCalibrating,
              let position = audio.pausePractice() else { return }
        generation += 1; task?.cancel(); task = nil
        frozenElapsed = min(position, endTime - epoch); elapsed = frozenElapsed!
        feedbackAudio = nil; phase = .paused; isResuming = false
    }
    func resume(audio: MetronomeAudio) {
        guard phase == .paused, let frozenElapsed, let lesson = selected,
              audio.routeIdentity == calibrationRoute, audio.sampleRate == calibrationRate,
              let countInDuration = audio.resumePractice(bpm: lesson.bpm) else {
            if phase == .paused { cancel(audio: audio, message: "無法續玩，請重新開始。") }; return
        }
        generation += 1; let token = generation
        phase = .preparing; isResuming = true
        task = Task { [weak self, weak audio] in
            guard let self, let audio else { return }
            let deadline = Self.now() + 2
            var anchor: Double?
            while !Task.isCancelled, token == generation, audio.isPlaying, Self.now() < deadline {
                if let value = audio.audibleEpoch() { anchor = value; break }
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
            guard !Task.isCancelled, token == generation else { return }
            guard let anchor, let mapping = PracticeTransportProjection(logicalEpoch: epoch, frozenElapsed: frozenElapsed,
                    countInEpoch: anchor, countInDuration: countInDuration), audio.isPlaying else {
                cancel(audio: audio, message: "未能續玩，請重新開始。"); return
            }
            projection = mapping; self.frozenElapsed = nil; feedbackAudio = audio; phase = .playing
            await watch(audio: audio, token: token)
        }
    }
    var resumeCountdown: Int? {
        guard isResuming, let projection else { return nil }
        let remaining = projection.resumeHost - Self.now()
        return remaining > 0 ? min(4, max(1, Int(ceil(remaining * Double(selected?.bpm ?? 60) / 60)))) : nil
    }
    var gameSnapshot: RhythmGameSnapshot? {
        guard let session, let selected, isActive || phase == .finished else { return nil }
        return RhythmGameSnapshot(targets: session.targets, hits: session.hits, epoch: epoch,
                                  duration: endTime - epoch, alignment: session.calibrationOffset, bpm: selected.bpm, subdivisions: selected.pattern.stepsPerBeat)
    }
    var gameRoute: RunnerRoute? {
        guard let value = gameSnapshot else { return nil }
        return RunnerRoute(targets: value.targets, hits: value.hits, epoch: value.epoch,
                           endTime: value.epoch + value.duration, alignment: value.alignment)
    }
    var liveSummary: TimingSummary? { session?.summary }
    func cancel(audio: MetronomeAudio, message: String? = nil) {
        audioObservation = nil
        projection = nil; frozenElapsed = nil; isResuming = false
        feedbackAudio = nil
        generation += 1; task?.cancel(); task = nil
        audio.stop(); restoreOptions(audio)
        session = nil; phase = .idle; summary = nil; notice = message; isEggMission = false; isComparison = false; presentation = .falling
    }
    private func finish(audio: MetronomeAudio) {
        feedbackAudio = nil
        guard let session else { cancel(audio: audio); return }
        audio.stop(); restoreOptions(audio)
        summary = session.summary; phase = .finished
        if isCalibrating {
            do {
                guard session.summary.extraCount <= 2, session.summary.missedCount <= 4 else { throw PracticeError.invalidCalibration }
                let alignment = try TimingCalibration.estimate(errors: session.summary.matched.compactMap(\.error),
                    route: calibrationRoute, sampleRate: calibrationRate)
                var next = progress; next.calibration = alignment
                calibrationSaved = save(next)
                if calibrationSaved { notice = "對齊完成，已保存。換音訊輸出後，請重新對齊。" }
                else { pendingProgress = next; needsSaveRetry = true }
            } catch { notice = "這次跟拍不夠穩定，校正未保存。準備好後再試一次。" }
        } else if let selected {
            stars = selected.stars(session.summary)
            if isComparison { resultSaved = false; needsSaveRetry = false; notice = "比較試玩不保存星星或解鎖。"; return }
            var next = progress; next.record(selected, summary: session.summary)
            resultSaved = save(next)
            if !resultSaved { pendingProgress = next; needsSaveRetry = true }
            else { notice = nil }
            self.selected = lessons.first { $0.id == selected.id } ?? selected
        }
    }
    private func restoreOptions(_ audio: MetronomeAudio) {
        guard let options = savedOptions else { return }; savedOptions = nil
        audio.setGap(options.1); audio.setLadder(options.2); audio.selectSound(options.0)
    }
    @discardableResult
    private func save(_ next: PracticeProgress) -> Bool {
        guard writable else { return false }
        do { try repository.save(next); progress = next; return true }
        catch { notice = "進度尚未保存，請稍後重試。若這份進度需要較新版 App，請先更新。"; return false }
    }
    static func now() -> Double { AVAudioTime.seconds(forHostTime: mach_absolute_time()) }

    /// Snapshot of the actual native session; presentation cannot publish scores.
    var runnerRoute: RunnerRoute? {
        guard isEggMission, let session, phase == .playing || phase == .paused || phase == .finished else { return nil }
        return RunnerRoute(targets: session.targets, hits: session.hits, epoch: epoch,
                           endTime: endTime, alignment: session.calibrationOffset)
    }

    /// Read-only display position on the existing audio-host epoch. Display
    /// callbacks cannot advance matching, finish a lesson or publish state.
    func presentationElapsed(at hostTime: Double) -> Double {
        guard phase == .playing, hostTime.isFinite, epoch.isFinite else { return elapsed }
        return min(projection?.elapsed(at: hostTime) ?? max(0, hostTime - epoch), max(0, endTime - epoch))
    }
}
