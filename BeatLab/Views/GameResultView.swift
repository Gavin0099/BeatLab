import SwiftUI
import BeatLabCore

struct GameResultView: View {
    let celebration: AnyView
    let title: String
    let summary: TimingSummary
    let stars: Int
    let best: Int
    let comparison: Bool
    let saved: Bool
    let saveFailed: Bool
    let advice: String
    let retry: () -> Void
    let next: (() -> Void)?
    let retrySave: () -> Void
    let discard: () -> Void
    let journey: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            celebration
            Text(title).font(.system(.title, design: .rounded).bold()).multilineTextAlignment(.center)
                .accessibilityIdentifier("practiceSummary")
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.largeTitle).foregroundStyle(index < stars ? BeatLabStyle.rhythmYellow : BeatLabStyle.muted)
                }
            }.accessibilityElement(children: .ignore).accessibilityLabel("這次得到 \(stars) 顆星")
                .accessibilityIdentifier("practiceStars")
            Text(comparison ? "比較試玩 · 星星不保存" : saveFailed ? "成績等待保存" : saved ? (stars > 0 ? "星星已保存 · 最佳 \(best) 星" : "這次已記錄，再挑戰一次") : "這次沒有保存")
                .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
            ViewThatFits(in: .horizontal) {
                HStack { stats }
                VStack { stats }
            }.padding(16).background(BeatLabStyle.surface, in: RoundedRectangle(cornerRadius: 20))
            Text(advice).multilineTextAlignment(.center).font(.headline)
            if saveFailed {
                Button("重試保存", action: retrySave).buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("retryProgressSave")
                Button("不保存，離開結果", action: discard).frame(minHeight: 44).accessibilityIdentifier("discardProgress")
            } else {
                if let next {
                    Button(comparison ? "試玩下一段" : "挑戰下一關", action: next).buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("nextLesson")
                }
                Button("再挑戰一次", action: retry).buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("retryLesson")
                Button("回到關卡", action: journey).buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("returnToJourney")
            }
        }.foregroundStyle(BeatLabStyle.ink).padding(.vertical, 16)
    }
    @ViewBuilder private var stats: some View {
        metric("命中", "\(summary.matched.count)/\(summary.targetCount)")
        metric("漏拍", "\(summary.missedCount)")
        metric("多打", "\(summary.extraCount)")
    }
    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(label).font(.subheadline).foregroundStyle(BeatLabStyle.muted)
        }.frame(maxWidth: .infinity).accessibilityElement(children: .combine)
    }
}
