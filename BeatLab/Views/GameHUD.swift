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
                VStack(alignment: .leading, spacing: 2) {
                    Text(textSize.isAccessibilitySize ? "第 \(number) 關" : "第 \(number) 關 · \(comparison ? "比較試玩" : "節奏冒險")")
                        .font(.headline).accessibilityIdentifier("activeLessonNumber")
                    Text("\(lesson.bpm) BPM").font(.subheadline.bold()).monospacedDigit()
                }
                Spacer(minLength: 0)
                Button(action: pause) { Image(systemName: "pause.fill").frame(width: 44, height: 44) }
                    .accessibilityLabel("暫停").accessibilityIdentifier("pausePractice")
                Button("退出", action: exit).font(.subheadline.bold()).frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("stopPractice")
            }
            ProgressView(value: min(1, max(0, elapsed / max(snapshot?.duration ?? 1, 1))))
                .tint(BeatLabStyle.accent).accessibilityLabel("練習進度")
            HStack(spacing: 10) {
                Text("命中 \(snapshot?.accepted.count ?? 0) / \(snapshot?.targets.count ?? 0)")
                    .accessibilityIdentifier("jumpMatches")
                Spacer(minLength: 0)
                Text("精準連擊 \(snapshot?.perfectStreak ?? 0)")
            }.font(.caption.bold()).monospacedDigit()
        }.foregroundStyle(BeatLabStyle.ink)
    }
}
