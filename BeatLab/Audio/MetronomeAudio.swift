import Foundation
import AVFoundation
import AudioToolbox
import Combine
import UIKit
import Darwin
import BeatLabCore
import BeatLabDSP

private final class RenderKernel: @unchecked Sendable {
    let pointer: OpaquePointer
    init?(rate: UInt32, settings: BLSettings) {
        guard let pointer = BLDSPCreate(rate, settings) else { return nil }
        self.pointer = pointer
    }
    deinit { BLDSPDestroy(pointer) }
}

/// A bounded input-feedback voice. Musical cues and judgments remain elsewhere.
@MainActor
final class PracticeFeedbackVoice {
    let node = AVAudioPlayerNode()
    private weak var graph: AVAudioEngine?
    private let buffers: [TimingGrade: AVAudioPCMBuffer]
    private var gain: Float

    init?(graph: AVAudioEngine, sampleRate: Double, gain: Float) {
        guard sampleRate.isFinite, (8_000...192_000).contains(sampleRate),
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let perfect = Self.makeBuffer(grade: .perfect, sampleRate: sampleRate),
              let matched = Self.makeBuffer(grade: .early, sampleRate: sampleRate),
              let extra = Self.makeBuffer(grade: .extra, sampleRate: sampleRate) else { return nil }
        buffers = [.perfect: perfect, .early: matched, .late: matched, .extra: extra]
        self.gain = gain.isFinite ? min(1, max(0, gain)) : 0
        self.graph = graph
        graph.attach(node)
        graph.connect(node, to: graph.mainMixerNode, format: format)
        node.volume = self.gain
        node.prepare(withFrameCount: perfect.frameLength)
    }

    static func makeBuffer(grade: TimingGrade, sampleRate: Double) -> AVAudioPCMBuffer? {
        guard sampleRate.isFinite, (8_000...192_000).contains(sampleRate),
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return nil }
        let duration = grade == .perfect ? 0.040 : grade == .extra ? 0.030 : 0.024
        let count = Int(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)),
              let samples = buffer.floatChannelData?.pointee else { return nil }
        buffer.frameLength = AVAudioFrameCount(count)
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let taper = pow(sin(.pi * Double(index) / Double(count - 1)), 2)
            let wave: Double
            switch grade {
            case .perfect: wave = 0.07 * (sin(2 * .pi * 880 * time) + sin(2 * .pi * 1320 * time))
            case .early, .late: wave = 0.06 * sin(2 * .pi * 660 * time)
            case .extra: wave = 0.055 * sin(2 * .pi * 220 * time)
            }
            samples[index] = index == 0 || index == count - 1 ? 0 : Float(taper * wave)
        }
        return buffer
    }

    @discardableResult
    func play(_ grade: TimingGrade) -> Bool {
        guard graph?.isRunning == true, gain > 0, let buffer = buffers[grade] else { return false }
        // Replace the previous short effect; rapid/extra inputs cannot queue a song.
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !node.isPlaying { node.play() }
        return true
    }
    func setGain(_ value: Float) {
        gain = value.isFinite ? min(1, max(0, value)) : 0
        node.volume = gain
        if gain == 0 { node.stop() }
    }
    func detach() {
        node.stop()
        graph?.detach(node)
        graph = nil
    }
}

@MainActor
final class MetronomeAudio: ObservableObject {
    struct DisplayBeat: Equatable {
        let index: Int
        let count: Int
        let phase: Double
        let configuration: MetronomeConfiguration
        let bar: UInt64
        let muted: Bool
        let number: UInt64
    }

    @Published private(set) var isPlaying = false
    @Published private(set) var status: String?
    @Published private(set) var volume: Float = 0.7
    @Published private(set) var sound: CountSound = .click
    @Published private(set) var gapBars = 0
    @Published private(set) var ladderBars = 0
    @Published private(set) var preparingVoice = false
    private var voiceSamples: [[Float]] = []
    private var voiceRate: Double = 0
    private let countVoice = CountVoice()
    private var preparation: Task<Void, Never>?
    private var voiceGeneration = 0
    private var requestedTempo = 80
    private var engine: AVAudioEngine?
    private var source: AVAudioSourceNode?
    private var feedbackVoice: PracticeFeedbackVoice?
    private var kernel: RenderKernel?
    private var observers: [NSObjectProtocol] = []
    private var latencyEstimate: Double = 0

    init() {
        let center = NotificationCenter.default
        for name in [AVAudioSession.interruptionNotification,
                     AVAudioSession.routeChangeNotification,
                     AVAudioSession.mediaServicesWereResetNotification,
                     Notification.Name.AVAudioEngineConfigurationChange,
                     UIApplication.didEnterBackgroundNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                Task { @MainActor [weak self] in self?.handle(note) }
            })
        }
    }

    deinit {
        // App root owns this object for its lifetime; stop graph before freeing C state.
        engine?.stop()
        if let node = source { engine?.detach(node) }
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    var practiceFeedbackAvailable: Bool { feedbackVoice != nil }
    var practiceFeedbackIsPlaying: Bool { isPlaying && feedbackVoice?.node.isPlaying == true }
    private(set) var practiceGrooveAvailable = false

    func start(configuration: MetronomeConfiguration, practiceFeedback: Bool = false, eggMission: Bool = false) {
        guard !isPlaying else { return }
        stop()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
            let sampleRate = session.sampleRate
            guard sound == .click || (voiceRate == sampleRate && voiceSamples.count == 5) else {
                stop(reason: "語音尚未準備完成，請稍候或切回 Click。")
                selectSound(sound)
                return
            }
            guard sampleRate == sampleRate.rounded(),
                  let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
                  let owner = RenderKernel(rate: UInt32(sampleRate), settings: Self.settings(configuration)) else {
                throw AudioFailure.unsupportedRoute
            }
            kernel = owner
            if eggMission, practiceFeedback, sound == .click, gapBars == 0, ladderBars == 0,
               configuration.tempo.bpm == 60, configuration.timeSignature == .fourFour,
               configuration.subdivision == .quarter,
               let samples = PracticeGroove.samples(sampleRate: sampleRate) {
                practiceGrooveAvailable = samples.withUnsafeBufferPointer {
                    BLDSPSetPracticeBed(owner.pointer, $0.baseAddress, UInt32($0.count), UInt32(sampleRate) * 4)
                }
            }
            for (index, samples) in voiceSamples.enumerated() where voiceRate == sampleRate {
                let loaded = samples.withUnsafeBufferPointer {
                    BLDSPSetVoice(owner.pointer, Int32(index), $0.baseAddress, UInt32($0.count))
                }
                guard loaded else { throw AudioFailure.unsupportedRoute }
            }
            BLDSPSetGain(owner.pointer, volume)
            _ = BLDSPSetPracticeOptions(owner.pointer, Int32(sound.rawValue), Int32(gapBars), Int32(ladderBars))
            requestedTempo = configuration.tempo.bpm
            let graph = AVAudioEngine()
            let node = AVAudioSourceNode(format: format) { silence, timestamp, count, bufferList in
                let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
                guard buffers.count == 1, let data = buffers[0].mData else {
                    for buffer in buffers {
                        if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) }
                    }
                    silence.pointee = true
                    return noErr
                }
                BLDSPRender(owner.pointer, data.assumingMemoryBound(to: Float.self), count, timestamp.pointee.mHostTime)
                silence.pointee = false
                return noErr
            }
            engine = graph
            source = node
            graph.attach(node)
            graph.connect(node, to: graph.mainMixerNode, format: format)
            if practiceFeedback {
                feedbackVoice = PracticeFeedbackVoice(graph: graph, sampleRate: sampleRate, gain: volume)
            }
            graph.prepare()
            // An estimate for display, not a measured score/calibration guarantee.
            latencyEstimate = session.outputLatency + session.ioBufferDuration
            try graph.start()
            isPlaying = true
            status = nil
        } catch {
            stop(reason: "暫時無法播放。請確認音訊輸出後再試。")
        }
    }

    func stop(reason: String? = nil) {
        // stop() closes rendering before detached node releases its callback capture.
        engine?.stop()
        feedbackVoice?.detach(); feedbackVoice = nil
        if let source { engine?.detach(source) }
        source = nil
        engine = nil
        // The callback retains RenderKernel, so an in-flight callback never sees freed state.
        kernel = nil
        practiceGrooveAvailable = false
        isPlaying = false
        status = reason
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func request(_ configuration: MetronomeConfiguration) {
        var settings = Self.settings(configuration)
        if configuration.tempo.bpm != requestedTempo { setLadder(0) }
        else if ladderBars > 0, let kernel { settings.bpm = BLDSPRequestedSettings(kernel.pointer).bpm }
        requestedTempo = configuration.tempo.bpm
        if let kernel { _ = BLDSPRequest(kernel.pointer, settings) }
    }

    func selectSound(_ value: CountSound) {
        sound = value
        if value == .click {
            voiceGeneration += 1; preparation?.cancel(); countVoice.cancel(); preparingVoice = false
            updateOptions()
            if !isPlaying { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
            return
        }
        // Loading voices requires a stopped kernel; switching an active graph stops safely.
        if isPlaying { stop(reason: "語音模式已變更，請重新開始。") }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch { status = "無法準備語音，請切回 Click。"; return }
        let rate = session.sampleRate
        guard rate >= 8000 else { status = "音訊輸出尚未準備完成。"; return }
        guard voiceRate != rate || voiceSamples.count != 5 else {
            if !isPlaying { try? session.setActive(false, options: .notifyOthersOnDeactivation) }
            return
        }
        preparation?.cancel(); countVoice.cancel(); voiceGeneration += 1
        let generation = voiceGeneration
        preparingVoice = true
        preparation = Task { [weak self] in
            guard let self else { return }
            do {
                let samples = try await countVoice.prepare(sampleRate: rate)
                guard !Task.isCancelled, generation == voiceGeneration else { return }
                voiceSamples = samples; voiceRate = rate; status = nil
            } catch {
                guard generation == voiceGeneration else { return }
                status = "無法準備語音，請切回 Click 或再試一次。"
            }
            if generation == voiceGeneration { preparingVoice = false }
            if !isPlaying { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        }
    }
    func setGap(_ bars: Int) { gapBars = min(2, max(0, bars)); updateOptions() }
    func setLadder(_ bars: Int) { ladderBars = min(32, max(0, bars)); updateOptions() }
    private func updateOptions() {
        if let kernel { _ = BLDSPSetPracticeOptions(kernel.pointer, Int32(sound.rawValue), Int32(gapBars), Int32(ladderBars)) }
    }

    var routeIdentity: String {
        AVAudioSession.sharedInstance().currentRoute.outputs.map { "\($0.portType.rawValue):\($0.uid)" }.joined(separator: "|")
    }
    var sampleRate: Double { AVAudioSession.sharedInstance().sampleRate }
    var supportsCalibration: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.allSatisfy {
            ![AVAudioSession.Port.bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType)
        }
    }
    /// Engine sample zero projected to estimated audible host time; refreshed from rendered data.
    func audibleEpoch() -> Double? {
        guard isPlaying, let kernel else { return nil }
        var clock = BLClock()
        guard BLDSPReadClock(kernel.pointer, &clock), clock.hostTime > 0 else { return nil }
        return AVAudioTime.seconds(forHostTime: clock.hostTime) - Double(clock.renderStartFrame) / Double(clock.sampleRate) + latencyEstimate
    }

    func setGain(_ value: Float) {
        volume = min(1, max(0, value))
        if let kernel { BLDSPSetGain(kernel.pointer, volume) }
        feedbackVoice?.setGain(volume)
    }

    @discardableResult
    func playPracticeFeedback(_ grade: TimingGrade) -> Bool {
        guard isPlaying else { return false }
        return feedbackVoice?.play(grade) ?? false
    }

    func displayBeat(now: Double? = nil) -> DisplayBeat? {
        guard isPlaying, let kernel else { return nil }
        var clock = BLClock()
        guard BLDSPReadClock(kernel.pointer, &clock), clock.hostTime > 0 else { return nil }
        let now = now ?? AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let renderTime = AVAudioTime.seconds(forHostTime: clock.hostTime)
        let frame = clock.renderStartFrame + Int64(((now - renderTime - latencyEstimate) * Double(clock.sampleRate)).rounded(.down))
        var beat = BLBeat()
        guard BLDSPReadBeat(kernel.pointer, frame, &beat),
              let configuration = Self.configuration(beat.settings) else { return nil }
        let phase = Double(frame - beat.startFrame) / Double(beat.endFrame - beat.startFrame)
        return DisplayBeat(index: Int(beat.beatInBar), count: configuration.timeSignature.beatsPerBar,
                           phase: min(1, max(0, phase)), configuration: configuration, bar: beat.barNumber,
                           muted: beat.muted, number: beat.beatNumber)
    }

    private enum AudioFailure: Error { case unsupportedRoute }

    private func handle(_ note: Notification) {
        if note.name == AVAudioSession.routeChangeNotification,
           let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
           reason == AVAudioSession.RouteChangeReason.categoryChange.rawValue { return }
        if note.name == AVAudioSession.routeChangeNotification || note.name == AVAudioSession.mediaServicesWereResetNotification {
            voiceGeneration += 1; preparation?.cancel(); countVoice.cancel()
            voiceSamples = []; voiceRate = 0; preparingVoice = false
        }
        if note.name == UIApplication.didEnterBackgroundNotification || note.name == AVAudioSession.interruptionNotification {
            voiceGeneration += 1; preparation?.cancel(); countVoice.cancel(); preparingVoice = false
            if !isPlaying { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        }
        guard isPlaying else { return }
        if note.name == Notification.Name.AVAudioEngineConfigurationChange,
           let changed = note.object as? AVAudioEngine, changed !== engine { return }
        if note.name == AVAudioSession.interruptionNotification,
           let kind = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
           kind != AVAudioSession.InterruptionType.began.rawValue { return }
        stop(reason: "音訊環境已改變。準備好後，請重新開始。")
    }

    static func settings(_ configuration: MetronomeConfiguration) -> BLSettings {
        let meter = TimeSignature.allCases.firstIndex(of: configuration.timeSignature) ?? 2
        let sub = Subdivision.allCases.firstIndex(of: configuration.subdivision) ?? 0
        return BLSettings(bpm: Int32(configuration.tempo.bpm), meter: Int32(meter),
                          subdivision: Int32(sub), accent: configuration.accentEnabled ? 1 : 0,
                          beatPattern: Int32(configuration.encodedBeatPattern), timbre: Int32(configuration.clickTimbre.rawValue))
    }

    private static func configuration(_ settings: BLSettings) -> MetronomeConfiguration? {
        guard TimeSignature.allCases.indices.contains(Int(settings.meter)),
              Subdivision.allCases.indices.contains(Int(settings.subdivision)),
              let tempo = try? Tempo(bpm: Int(settings.bpm)),
              let timbre = ClickTimbre(rawValue: Int(settings.timbre)) else { return nil }
        let signature = TimeSignature.allCases[Int(settings.meter)]
        let pattern: [BeatEmphasis]? = settings.beatPattern == 0 ? nil : (0..<signature.beatsPerBar).compactMap {
            BeatEmphasis(rawValue: (Int(settings.beatPattern) >> ($0 * 2)) & 3)
        }
        return try? MetronomeConfiguration(tempo: tempo,
            timeSignature: signature,
            subdivision: Subdivision.allCases[Int(settings.subdivision)], accentEnabled: settings.accent != 0,
            beatEmphases: pattern, clickTimbre: timbre)
    }
}
