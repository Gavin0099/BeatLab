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

@MainActor
final class MetronomeAudio: ObservableObject {
    struct DisplayBeat: Equatable {
        let index: Int
        let count: Int
        let phase: Double
        let configuration: MetronomeConfiguration
        let bar: UInt64
        let muted: Bool
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

    func start(configuration: MetronomeConfiguration) {
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
        if let source { engine?.detach(source) }
        source = nil
        engine = nil
        // The callback retains RenderKernel, so an in-flight callback never sees freed state.
        kernel = nil
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
                           phase: min(1, max(0, phase)), configuration: configuration, bar: beat.barNumber, muted: beat.muted)
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
                          subdivision: Int32(sub), accent: configuration.accentEnabled ? 1 : 0)
    }

    private static func configuration(_ settings: BLSettings) -> MetronomeConfiguration? {
        guard TimeSignature.allCases.indices.contains(Int(settings.meter)),
              Subdivision.allCases.indices.contains(Int(settings.subdivision)),
              let tempo = try? Tempo(bpm: Int(settings.bpm)) else { return nil }
        return try? MetronomeConfiguration(tempo: tempo,
            timeSignature: TimeSignature.allCases[Int(settings.meter)],
            subdivision: Subdivision.allCases[Int(settings.subdivision)], accentEnabled: settings.accent != 0)
    }
}
