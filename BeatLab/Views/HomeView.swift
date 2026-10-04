import SwiftUI
import BeatLabCore

struct HomeView: View {
    @EnvironmentObject private var store: ConfigurationStore
    @EnvironmentObject private var practice: PracticeStore
    let openMetronome: () -> Void
    let openPractice: () -> Void

    private var completed: Int {
        practice.lessons.filter { (practice.progress.results[$0.id]?.stars ?? 0) > 0 }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BLSectionHeading(title: completed == practice.lessons.count && completed > 0
                    ? "十個挑戰，全部做到了！" : "今天，找到你的節奏", subtitle: "一小段練習，從舒服的速度開始。")

                if let notice = practice.notice { BLStatusMessage(text: notice) }
                if let lesson = practice.recommended {
                    BLCard {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Text(completed == 0 ? "從第一拍開始" : completed == practice.lessons.count ? "再練一次，更穩一點" : "今天練這個")
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentColor)
                                Spacer()
                                Image(systemName: "hand.tap.fill").font(.title2).foregroundStyle(Color.accentColor).accessibilityHidden(true)
                            }
                            Text(lesson.shortTitle).font(.system(.title, design: .rounded).bold()).foregroundStyle(BeatLabStyle.ink)
                            Text(lesson.instruction).foregroundStyle(BeatLabStyle.muted)
                            ViewThatFits(in: .horizontal) {
                                HStack { BLPill(title: "\(lesson.bpm) BPM", symbol: "metronome"); BLPill(title: "\(lesson.bars) 小節", symbol: "music.note.list") }
                                VStack(alignment: .leading) { BLPill(title: "\(lesson.bpm) BPM", symbol: "metronome"); BLPill(title: "\(lesson.bars) 小節", symbol: "music.note.list") }
                            }
                            Button {
                                practice.select(lesson); openPractice()
                            } label: { Label("開始今天的練習", systemImage: "play.fill") }
                            .buttonStyle(BLPrimaryButtonStyle()).disabled(!practice.canPractice).accessibilityIdentifier("dailyPractice")
                            if !practice.canPractice { Text("課程暫時無法使用，可以先用自由節拍器。").font(.subheadline).foregroundStyle(BeatLabStyle.muted) }
                        }
                    }
                } else {
                    BLStatusMessage(text: "課程暫時無法載入，先用節拍器找到舒服的速度。", symbol: "music.note")
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("我的節奏旅程").font(.headline)
                        Spacer()
                        Text("\(completed) / \(practice.lessons.count) 關").font(.subheadline.monospacedDigit()).foregroundStyle(BeatLabStyle.muted)
                    }
                    ProgressView(value: Double(completed), total: Double(max(1, practice.lessons.count)))
                        .accessibilityLabel("已完成課程").accessibilityValue("\(completed) 關，共 \(practice.lessons.count) 關")
                    if let id = practice.progress.lastLessonID,
                       let last = practice.lessons.first(where: { $0.id == id }), practice.unlocked(last) {
                        Button { practice.select(last); openPractice() } label: {
                            Label("繼續練習：\(last.shortTitle)", systemImage: "arrow.clockwise")
                        }.buttonStyle(BLSecondaryButtonStyle()).disabled(!practice.canPractice)
                    } else {
                        Text("完成一關，就能解鎖下一個節奏。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    }
                }

                BLCard {
                    VStack(alignment: .leading, spacing: 16) {
                        BLSectionHeading(title: "自由節拍器", subtitle: "先聽拍子，也可以跟著打。")
                        ConfigurationSummary(configuration: store.configuration)
                        Button(action: openMetronome) { Label("打開節拍器", systemImage: "metronome") }
                            .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("openMetronome")
                    }
                }
            }
            .padding(20).frame(maxWidth: BeatLabStyle.maxWidth, alignment: .leading).frame(maxWidth: .infinity)
        }
        .background(BeatLabStyle.canvas).foregroundStyle(BeatLabStyle.ink)
        .navigationTitle("BeatLab").navigationBarTitleDisplayMode(.inline)
    }
}

extension Lesson {
    var shortTitle: String {
        let parts = title.split(separator: " ", maxSplits: 1)
        return parts.count == 2 && Int(parts[0]) != nil ? String(parts[1]) : title
    }
}
