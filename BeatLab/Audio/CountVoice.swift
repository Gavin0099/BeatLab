import Foundation
import AVFoundation

/// Callback owns copies, never calls UI or the realtime renderer. Completion is single-shot.
private final class SpeechCollection: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Float] = []
    private var rate: Double = 0
    private var continuation: CheckedContinuation<([Float], Double), Error>?
    init(_ continuation: CheckedContinuation<([Float], Double), Error>) { self.continuation = continuation }

    func receive(_ buffer: AVAudioBuffer) {
        guard let pcm = buffer as? AVAudioPCMBuffer else { fail(); return }
        if pcm.frameLength == 0 { finish(); return }
        guard let channels = pcm.floatChannelData, pcm.format.channelCount > 0 else { fail(); return }
        lock.lock()
        defer { lock.unlock() }
        guard continuation != nil else { return }
        if rate == 0 { rate = pcm.format.sampleRate }
        guard rate == pcm.format.sampleRate, samples.count + Int(pcm.frameLength) <= Int(rate * 3) else {
            let completion = continuation; continuation = nil
            completion?.resume(throwing: VoiceError.unavailable)
            return
        }
        for frame in 0..<Int(pcm.frameLength) {
            var value: Float = 0
            for channel in 0..<Int(pcm.format.channelCount) {
                value += pcm.format.isInterleaved
                    ? channels[0][frame * Int(pcm.format.channelCount) + channel]
                    : channels[channel][frame]
            }
            samples.append(value / Float(pcm.format.channelCount))
        }
    }
    func fail() {
        lock.lock(); let completion = continuation; continuation = nil; lock.unlock()
        completion?.resume(throwing: VoiceError.unavailable)
    }
    private func finish() {
        lock.lock(); let completion = continuation; continuation = nil
        let result = (samples, rate); lock.unlock()
        if result.0.isEmpty || result.1 <= 0 { completion?.resume(throwing: VoiceError.unavailable) }
        else { completion?.resume(returning: result) }
    }
}

enum VoiceError: Error { case unavailable }
enum CountSound: Int, CaseIterable, Hashable { case click, voice, both
    var title: String { self == .click ? "Click" : self == .voice ? "Voice" : "Both" }
}

@MainActor
final class CountVoice {
    private let synthesizer = AVSpeechSynthesizer()

    func prepare(sampleRate: Double) async throws -> [[Float]] {
        var voices: [[Float]] = []
        for word in ["one", "two", "three", "four", "and"] {
            try Task.checkCancellation()
            let utterance = AVSpeechUtterance(string: word)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.55
            let (samples, sourceRate): ([Float], Double) = try await withCheckedThrowingContinuation { continuation in
                let collection = SpeechCollection(continuation)
                // Missing synthesis completion fails visibly instead of hanging Start.
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { collection.fail() }
                synthesizer.write(utterance) { collection.receive($0) }
            }
            // Trim leading silence; onset remains material-dependent and needs device evidence.
            guard let first = samples.firstIndex(where: { abs($0) > 0.003 }),
                  let last = samples.lastIndex(where: { abs($0) > 0.003 }) else { throw VoiceError.unavailable }
            let trimmed = Array(samples[max(0, first - Int(sourceRate * 0.002))...last])
            let count = Int(Double(trimmed.count) * sampleRate / sourceRate)
            guard count > 0, count <= Int(sampleRate) else { throw VoiceError.unavailable }
            let converted = (0..<count).map { index -> Float in
                let position = Double(index) * sourceRate / sampleRate
                let lower = min(trimmed.count - 1, Int(position)), upper = min(trimmed.count - 1, lower + 1)
                let fraction = Float(position - Double(lower))
                return trimmed[lower] * (1 - fraction) + trimmed[upper] * fraction
            }
            voices.append(converted)
        }
        return voices
    }
    func cancel() { synthesizer.stopSpeaking(at: .immediate) }
}
