import SwiftUI
import BeatLabCore

struct RhythmLane: View {
    let pattern: RhythmPattern
    let elapsed: Double
    let bpm: Int
    let isPlaying: Bool
    @Environment(\.dynamicTypeSize) private var textSize

    private var active: Int {
        let position = (elapsed - 4 * 60 / Double(bpm)) * Double(bpm * pattern.stepsPerBeat) / 60
        return position >= 0 ? Int(position) % pattern.steps.count : -1
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if pattern.stepsPerBeat == 1 && !textSize.isAccessibilitySize {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { beat in
                        VStack(spacing: 6) {
                            Text("\(beat + 1)").font(.caption.bold()).foregroundStyle(BeatLabStyle.muted)
                            note(beat)
                        }
                    }
                }
            } else {
                ForEach(0..<4, id: \.self) { beat in
                    HStack(alignment: .center, spacing: 10) {
                        Text("\(beat + 1)").font(.headline.monospacedDigit()).foregroundStyle(BeatLabStyle.muted)
                            .frame(minWidth: 20).accessibilityLabel("第 \(beat + 1) 拍")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: textSize.isAccessibilitySize ? min(2, pattern.stepsPerBeat) : pattern.stepsPerBeat), spacing: 6) {
                            ForEach(0..<pattern.stepsPerBeat, id: \.self) { division in note(beat * pattern.stepsPerBeat + division) }
                        }
                    }
                }
            }
        }.accessibilityIdentifier("rhythmLane")
    }
    private func note(_ index: Int) -> some View {
        let stroke = pattern.steps[index]
        let selected = isPlaying && index == active
        return VStack(spacing: 2) {
            Text(stroke == .rest ? "—" : stroke.rawValue).font(.system(.title3, design: .rounded).bold())
            Circle().fill(selected ? BeatLabStyle.onAccent : Color.clear).frame(width: 4, height: 4)
        }
        .foregroundStyle(selected ? BeatLabStyle.onAccent : stroke == .rest ? BeatLabStyle.muted : BeatLabStyle.ink)
        .frame(maxWidth: .infinity, minHeight: 44).padding(.vertical, 4)
        .background(selected ? Color.accentColor : stroke == .rest ? BeatLabStyle.canvas : BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
            stroke == .rest && !selected ? BeatLabStyle.line : Color.clear,
            style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("第 \(index / pattern.stepsPerBeat + 1) 拍，第 \(index % pattern.stepsPerBeat + 1) 格，\(stroke == .rest ? "休止" : stroke == .right ? "右手" : "左手")")
        .accessibilityValue(selected ? "目前" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
