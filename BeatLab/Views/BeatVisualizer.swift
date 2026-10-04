import SwiftUI
import BeatLabCore

struct BeatVisualizer: View {
    @EnvironmentObject private var audio: MetronomeAudio
    @EnvironmentObject private var store: ConfigurationStore
    @EnvironmentObject private var practice: PracticeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Only samples the audio clock. Never schedules sound or advances beat state.
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !audio.isPlaying)) { _ in
            let beat = audio.displayBeat()
            let config = beat?.configuration ?? fallbackConfiguration
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(0..<config.timeSignature.beatsPerBar, id: \.self) { index in
                        let active = beat?.index == index
                        VStack(spacing: 4) {
                            Text("\(index + 1)").font(.system(.largeTitle, design: .rounded).bold()).minimumScaleFactor(0.5).lineLimit(1)
                            Circle().fill(active ? BeatLabStyle.onAccent : Color.clear).frame(width: 6, height: 6)
                        }
                            .foregroundStyle(active ? BeatLabStyle.onAccent : BeatLabStyle.ink)
                            .frame(maxWidth: .infinity, minHeight: 72).padding(.vertical, 8)
                            .background(active ? Color.accentColor : BeatLabStyle.accentSoft,
                                        in: RoundedRectangle(cornerRadius: 20))
                            .scaleEffect(active && !reduceMotion ? 1 + 0.04 * (1 - (beat?.phase ?? 0)) : 1)
                            .accessibilityLabel("第 \(index + 1) 拍")
                            .accessibilityElement(children: .ignore)
                            .accessibilityValue(active ? "目前" : "")
                            .accessibilityAddTraits(active ? .isSelected : [])
                    }
                }
                if config.timeSignature.isCompound {
                    Text("1-la-li · 2-la-li")
                        .font(.headline.monospaced())
                }
                if let beat, audio.isPlaying {
                    Text("\(beat.configuration.tempo.bpm) BPM · 第 \(beat.bar + 1) 小節\(beat.muted ? " · 靜音，保持內心節拍" : "")")
                        .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                }
                if audio.isPlaying, practice.phase != .playing && practice.phase != .preparing,
                   audio.ladderBars == 0, beat?.configuration != store.configuration {
                    Text("設定將在下一拍或下一小節生效")
                        .font(.caption)
                        .foregroundStyle(BeatLabStyle.muted)
                        .accessibilityIdentifier("pendingConfiguration")
                }
            }
        }
        .accessibilityIdentifier("beatVisualizer")
    }
    private var fallbackConfiguration: MetronomeConfiguration {
        guard practice.phase == .playing || practice.phase == .preparing else { return store.configuration }
        let bpm = practice.isCalibrating ? 60 : practice.selected?.bpm ?? 60
        return (try? MetronomeConfiguration(tempo: Tempo(bpm: bpm), timeSignature: .fourFour,
                    subdivision: .quarter, accentEnabled: true)) ?? store.configuration
    }
}
