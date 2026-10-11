import SwiftUI
import BeatLabCore

struct GameHUD: View {
    let lesson: Lesson
    let number: Int
    let snapshot: RhythmGameSnapshot?
    let elapsed: Double
    let comparison: Bool
    let pause: () -> Void
    let exit: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                if textSize.isAccessibilitySize {
                    Text("\(number)").font(.headline).accessibilityLabel("第 \(number) 關")
                        .accessibilityIdentifier("activeLessonNumber")
                    Text("\(lesson.bpm) BPM").font(.subheadline.bold()).monospacedDigit().lineLimit(1)
                } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(textSize.isAccessibilitySize ? "第 \(number) 關" : "第 \(number) 關 · \(comparison ? "比較試玩" : "節奏冒險")")
                        .font(.headline).accessibilityIdentifier("activeLessonNumber")
                    Text("\(lesson.bpm) BPM").font(.subheadline.bold()).monospacedDigit()
                }
                }
                Spacer(minLength: 0)
                Button(action: pause) { Image(systemName: "pause.fill").font(.system(size: 20, weight: .bold)).frame(width: 44, height: 44) }
                    .accessibilityLabel("暫停").accessibilityIdentifier("pausePractice")
                Button(action: exit) {
                    if textSize.isAccessibilitySize { Image(systemName: "xmark").font(.system(size: 20, weight: .bold)).frame(width: 44, height: 44) }
                    else { Text("退出").font(.subheadline.bold()).frame(minWidth: 44, minHeight: 44) }
                }.accessibilityLabel("退出").accessibilityIdentifier("stopPractice")
            }
            ProgressView(value: min(1, max(0, elapsed / max(snapshot?.duration ?? 1, 1))))
                .tint(BeatLabStyle.accent).accessibilityLabel("練習進度")
            Group {
                if textSize.isAccessibilitySize {
                    Text("命中 \(snapshot?.accepted.count ?? 0) / \(snapshot?.targets.count ?? 0)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityValue("精準連擊 \(snapshot?.perfectStreak ?? 0)")
                        .accessibilityIdentifier("jumpMatches")
                }
                else { HStack(spacing: 10) { stats } }
            }.font(.caption.bold()).monospacedDigit().lineLimit(1)
        }.foregroundStyle(BeatLabStyle.ink)
    }
    @ViewBuilder private var stats: some View {
        Text("命中 \(snapshot?.accepted.count ?? 0) / \(snapshot?.targets.count ?? 0)")
            .frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("jumpMatches")
        Text("精準連擊 \(snapshot?.perfectStreak ?? 0)")
            .frame(maxWidth: .infinity, alignment: textSize.isAccessibilitySize ? .leading : .trailing)
    }
}
