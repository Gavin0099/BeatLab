import Foundation
import Combine
import BeatLabCore
import AVFoundation
import Darwin

@MainActor
final class PracticeStore: ObservableObject {
    enum Phase: Equatable { case idle, preparing, playing, finished }
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
        guard phase != .playing && phase != .preparing, !needsSaveRetry, unlocked(lesson) else { return }
        selected = lesson; summary = nil; latestHit = nil; stars = 0; isCalibrating = false; phase = .idle
        practiceBPM = lesson.bpm
    }
    func setPracticeBPM(_ value: Int) {
        guard phase != .playing && phase != .preparing else { return }
        practiceBPM = min(240, max(selected?.bpm ?? recommended?.bpm ?? 60, value))
    }
    func setMode(_ value: InterfaceMode) { var next = progress; next.mode = value; save(next) }
    func resetProgress() {
        guard phase != .playing && phase != .preparing else { return }
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

    func start(_ lesson: Lesson, audio: MetronomeAudio) {
        guard canPractice, unlocked(lesson), !needsSaveRetry, phase != .playing && phase != .preparing else { return }
        do { selected = try lesson.atTempo(max(lesson.bpm, practiceBPM)) }
        catch { notice = "練習速度無法使用。"; return }
        isCalibrating = false
        begin(audio: audio, bpm: selected!.bpm)
    }
    func startCalibration(audio: MetronomeAudio) {
        guard writable, !needsSaveRetry, phase != .playing && phase != .preparing else { return }
        guard audio.supportsCalibration else { notice = "校正請使用內建喇叭或有線耳機。"; return }
        isCalibrating = true; selected = nil
        begin(audio: audio, bpm: 60)
    }
    private func begin(audio: MetronomeAudio, bpm: Int) {
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
        audio.start(configuration: configuration)
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
                phase = .playing
            } catch { cancel(audio: audio, message: "練習資料無法使用。"); return }
            while !Task.isCancelled, token == generation, phase == .playing {
                guard audio.isPlaying else { cancel(audio: audio, message: "播放已中斷，這次練習不計成績。"); return }
                let time = Self.now()
                elapsed = max(0, time - epoch)
                if time >= endTime { finish(audio: audio); return }
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }
    }
    func tap(at time: Double, accessibility: Bool = false) {
        guard phase == .playing, time >= epoch + (isCalibrating ? 4 : 4 * 60 / Double(selected?.bpm ?? 60))
                - TimingSession.matchingWindow, time <= endTime else { return }
        if accessibility { calibrated = false }
        latestHit = session?.tap(at: time)
    }
    func cancel(audio: MetronomeAudio, message: String? = nil) {
        generation += 1; task?.cancel(); task = nil
        audio.stop(); restoreOptions(audio)
        session = nil; phase = .idle; summary = nil; notice = message
    }
    private func finish(audio: MetronomeAudio) {
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
}
