import Foundation

/// Original four-bar percussion phrase, prepared outside the render callback.
/// Musical positions are sample offsets in the existing 60 BPM transport.
enum PracticeGroove {
    static func samples(sampleRate: Double) -> [Float]? {
        guard sampleRate.isFinite, sampleRate == sampleRate.rounded(),
              (8_000...192_000).contains(sampleRate) else { return nil }
        let rate = Int(sampleRate)
        var phrase = [Float](repeating: 0, count: rate * 16)
        func voice(duration: Double, kind: Int) -> [Float] {
            var seed: UInt32 = 0x42544C42
            return (0..<Int(duration * sampleRate)).map { i in
                let t = Double(i) / sampleRate
                let attack = min(1, t * 400)
                seed = 1_664_525 &* seed &+ 1_013_904_223
                let noise = Double(seed) / Double(UInt32.max) * 2 - 1
                let sound: Double
                if kind == 0 {
                    let phase = 2 * Double.pi * (45 * t + 70 * (1 - exp(-22 * t)) / 22)
                    sound = 0.11 * sin(phase) * exp(-20 * t)
                } else if kind == 1 {
                    sound = 0.045 * (0.75 * noise + 0.25 * sin(2 * .pi * 180 * t)) * exp(-45 * t)
                } else {
                    sound = 0.015 * noise * exp(-150 * t)
                }
                return i == 0 || i == Int(duration * sampleRate) - 1 ? 0 : Float(attack * sound)
            }
        }
        let kick = voice(duration: 0.20, kind: 0)
        let snare = voice(duration: 0.10, kind: 1)
        let hat = voice(duration: 0.025, kind: 2)
        func place(_ voice: [Float], at offset: Int) {
            for i in voice.indices where offset + i < phrase.count { phrase[offset + i] += voice[i] }
        }
        for beat in 0..<16 {
            place(beat % 2 == 0 ? kick : snare, at: beat * rate)
            place(hat, at: beat * rate)
            place(hat, at: beat * rate + rate / 2)
        }
        // A restrained closing fill; the metronome stays the clear main cue.
        place(snare, at: 15 * rate + rate / 2)
        return phrase
    }
}
