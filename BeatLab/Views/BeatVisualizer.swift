import SwiftUI
import BeatLabCore
import UIKit

struct BeatVisualizer: View {
    @EnvironmentObject private var audio: MetronomeAudio
    @EnvironmentObject private var store: ConfigurationStore
    @EnvironmentObject private var practice: PracticeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var feedback = UIImpactFeedbackGenerator(style: .light)
    var interactive = false

    var body: some View {
        // Only samples the audio clock. Never schedules sound or advances beat state.
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !audio.isPlaying)) { _ in
            let beat = audio.displayBeat()
            let config = interactive ? store.configuration : beat?.configuration ?? fallbackConfiguration
            VStack(spacing: 12) {
                if interactive {
                    Text("點拍點切換：重音 → 一般 → 靜音").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: textSize.isAccessibilitySize ? 2 : config.timeSignature.beatsPerBar), spacing: 12) {
                    ForEach(0..<config.timeSignature.beatsPerBar, id: \.self) { index in
                        let active = beat?.index == index && beat?.configuration.timeSignature == config.timeSignature
                        let emphasis = config.beatEmphases[index]
                        if interactive {
                            Button { store.cycleBeat(at: index) } label: { beatLabel(index, active: active, emphasis: emphasis, phase: beat?.phase ?? 0) }
                                .buttonStyle(.plain).disabled(!store.canEdit)
                                .accessibilityLabel("第 \(index + 1) 拍")
                                .accessibilityValue(emphasis.displayName + (active ? "，目前" : ""))
                                .accessibilityHint("點一下切換為\(emphasis.next.displayName)，播放中於下一小節生效")
                                .accessibilityIdentifier("beatControl.\(index)")
                        } else {
                            beatLabel(index, active: active, emphasis: emphasis, phase: beat?.phase ?? 0)
                                .accessibilityElement(children: .ignore).accessibilityLabel("第 \(index + 1) 拍")
                                .accessibilityValue(active ? "目前" : "")
                        }
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
                   audio.ladderBars == 0, let beat, !soundMatches(beat.configuration, store.configuration) {
                    Text("設定將在下一拍或下一小節生效")
                        .font(.caption)
                        .foregroundStyle(BeatLabStyle.muted)
                        .accessibilityIdentifier("pendingConfiguration")
                }
            }
            .padding(interactive ? 8 : 0)
            .background(interactive && store.configuration.screenPulseEnabled && !reduceMotion && beat != nil && (beat?.phase ?? 1) < 0.12
                        ? BeatLabStyle.rewardSoft : Color.clear, in: RoundedRectangle(cornerRadius: 20))
            .onChange(of: beat?.number) { number in
                guard interactive, number != nil, store.configuration.hapticsEnabled,
                      audio.isPlaying, beat?.muted == false, UIDevice.current.userInterfaceIdiom == .phone else { return }
                feedback.impactOccurred(intensity: beat?.configuration.beatEmphases[beat?.index ?? 0] == .accent ? 1 : 0.5)
                feedback.prepare()
            }
        }
        .accessibilityIdentifier("beatVisualizer")
    }
    private func beatLabel(_ index: Int, active: Bool, emphasis: BeatEmphasis, phase: Double) -> some View {
        VStack(spacing: 6) {
            Text("\(index + 1)").font(.system(.largeTitle, design: .rounded).bold())
            Image(systemName: emphasis == .accent ? "speaker.wave.3.fill" : emphasis == .muted ? "speaker.slash.fill" : "speaker.wave.1.fill")
                .font(.caption).accessibilityHidden(true)
            if interactive { Text(emphasis.displayName).font(.caption.weight(.semibold)) }
            Capsule().fill(active ? BeatLabStyle.onAccent : Color.clear).frame(height: 4)
                .accessibilityHidden(true)
        }
        .foregroundStyle(active ? BeatLabStyle.onAccent : BeatLabStyle.ink)
        .frame(maxWidth: .infinity, minHeight: 80).padding(.vertical, 8)
        .background(active ? Color.accentColor : BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(emphasis == .accent && !active ? Color.accentColor : Color.clear, lineWidth: 2))

    }
    private func pendulum(beat: MetronomeAudio.DisplayBeat?) -> some View {
        let angle = beat.map { cos(Double.pi * (Double($0.number % 2) + $0.phase)) * 30 } ?? 0
        return ZStack(alignment: .bottom) {
            HStack(spacing: 20) { ForEach(0..<7, id: \.self) { _ in Rectangle().fill(BeatLabStyle.line).frame(width: 2, height: 12) } }
            VStack(spacing: 0) {
                Circle().fill(Color.accentColor).frame(width: 12, height: 12)
                Rectangle().fill(Color.accentColor).frame(width: 3, height: 72)
            }.rotationEffect(.degrees(reduceMotion ? 0 : angle), anchor: .bottom)
        }.frame(height: 105).frame(maxWidth: .infinity).accessibilityHidden(true)
    }
    private func soundMatches(_ lhs: MetronomeConfiguration, _ rhs: MetronomeConfiguration) -> Bool {
        lhs.tempo == rhs.tempo && lhs.timeSignature == rhs.timeSignature && lhs.subdivision == rhs.subdivision &&
        lhs.beatEmphases == rhs.beatEmphases && lhs.clickTimbre == rhs.clickTimbre
    }
    private var fallbackConfiguration: MetronomeConfiguration {
        guard practice.phase == .playing || practice.phase == .preparing else { return store.configuration }
        let bpm = practice.isCalibrating ? 60 : practice.selected?.bpm ?? 60
        return (try? MetronomeConfiguration(tempo: Tempo(bpm: bpm), timeSignature: .fourFour,
                    subdivision: .quarter, accentEnabled: true)) ?? store.configuration
    }
}
