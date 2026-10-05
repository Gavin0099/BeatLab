import SwiftUI
import BeatLabCore

struct HomeView: View {
    @EnvironmentObject private var store: ConfigurationStore
    @EnvironmentObject private var practice: PracticeStore
    @Environment(\.dynamicTypeSize) private var typeSize
    let openMetronome: () -> Void
    let openPractice: () -> Void

    private var completed: Int {
        practice.lessons.filter { (practice.progress.results[$0.id]?.stars ?? 0) > 0 }.count
    }
    private var allCompleted: Bool { completed > 0 && completed == practice.lessons.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                adventure
                if let notice = practice.notice {
                    Text(notice).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(HomeBrand.surface, in: RoundedRectangle(cornerRadius: 18))
                }
                journey
                metronome
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 48)
            .frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
        }
        .background(HomeBrand.canvas).foregroundStyle(HomeBrand.ink).tint(HomeBrand.forest)
        .navigationTitle("拍拍冒險").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(HomeBrand.canvas, for: .navigationBar)
    }

    private var adventure: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            welcomeCaption.font(.caption.weight(.semibold))
                            Spacer(minLength: 0)
                            mascot.frame(width: 88, height: 100)
                        }
                        welcomeTitle
                    }
                } else {
                    HStack(alignment: .center, spacing: 0) {
                        VStack(alignment: .leading, spacing: 10) {
                            welcomeCaption.font(.subheadline.weight(.semibold))
                            welcomeTitle
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        mascot.frame(width: 156, height: 188)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 14) {
                if let lesson = practice.recommended {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("第 \(lessonNumber(lesson)) 關 · \(allCompleted ? "再次挑戰" : "今天的冒險")")
                                .font(.caption.weight(.semibold))
                            lessonTitle(lesson)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            Text(String(format: "%02d", lessonNumber(lesson)))
                                .font(.system(.title2, design: .rounded).weight(.heavy)).monospacedDigit()
                                .padding(12).background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                                .accessibilityLabel("第 \(lessonNumber(lesson)) 關")
                            VStack(alignment: .leading, spacing: 4) {
                                Text(allCompleted ? "再挑戰這一關" : "今天的冒險").font(.caption.weight(.semibold))
                                lessonTitle(lesson)
                            }.fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Text(lesson.instruction).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { lessonDetails(lesson) }
                        VStack(alignment: .leading, spacing: 8) { lessonDetails(lesson) }
                    }
                    Button { practice.select(lesson); openPractice() } label: {
                        Label(allCompleted ? "再來一次" : "開始冒險", systemImage: "play.fill")
                    }
                    .buttonStyle(HomeAdventureButtonStyle()).disabled(!practice.canPractice)
                    .accessibilityIdentifier("dailyPractice")
                    if !practice.canPractice {
                        Text("課程暫時無法使用，可以先用自由節拍器。").font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("課程暫時無法載入，先用節拍器找到舒服的速度。")
                        .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.26))
        }
        .foregroundStyle(HomeBrand.heroInk)
        .background(HomeBrand.hero, in: RoundedRectangle(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var welcomeCaption: some View {
        Text(allCompleted ? "十個挑戰，全都做到了！" : "恐龍陪你，找到節奏")
            .fixedSize(horizontal: false, vertical: true)
    }
    private var welcomeTitle: some View {
        Text(allCompleted ? "再出發，\n更穩一點！" : "拍拍，\n一起冒險！")
            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
            .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
    }
    private var mascot: some View {
        Image("HomeDinosaur").resizable().scaledToFit().accessibilityHidden(true)
    }
    private func lessonNumber(_ lesson: Lesson) -> Int {
        (practice.lessons.firstIndex(where: { $0.id == lesson.id }) ?? 0) + 1
    }
    private func lessonTitle(_ lesson: Lesson) -> some View {
        Text(lesson.shortTitle).font(.system(.title2, design: .rounded).bold())
            .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("homeRecommendedLesson")
    }

    @ViewBuilder
    private func lessonDetails(_ lesson: Lesson) -> some View {
        Label("\(lesson.bpm) BPM", systemImage: "metronome")
        Label("\(lesson.bars) 小節", systemImage: "music.note.list")
    }

    private var journey: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack { journeyTitle; Spacer(); journeyCount }
                VStack(alignment: .leading, spacing: 4) { journeyTitle; journeyCount }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(Array(practice.lessons.enumerated()), id: \.element.id) { index, lesson in
                    let done = (practice.progress.results[lesson.id]?.stars ?? 0) > 0
                    let current = lesson.id == practice.recommended?.id
                    VStack(spacing: 4) {
                        Image(systemName: done ? "checkmark" : current ? "flag.fill" : "lock.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("\(index + 1)").font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .foregroundStyle(done || current ? HomeBrand.canvas : HomeBrand.muted)
                    .background(done || current ? HomeBrand.forest : HomeBrand.surface, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("冒險足跡").accessibilityValue("已完成 \(completed) 關，共 \(practice.lessons.count) 關")
            if let id = practice.progress.lastLessonID,
               let last = practice.lessons.first(where: { $0.id == id }), practice.unlocked(last) {
                Button { practice.select(last); openPractice() } label: {
                    Label("繼續練習：\(last.shortTitle)", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold)).padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.disabled(!practice.canPractice)
            } else {
                Text("完成一關，就向前一步。").font(.subheadline).foregroundStyle(HomeBrand.muted)
            }
        }
    }
    private var journeyTitle: some View { Text("冒險足跡").font(.title3.bold()).accessibilityAddTraits(.isHeader) }
    private var journeyCount: some View {
        Text("\(completed) / \(practice.lessons.count) 關").font(.subheadline.weight(.semibold)).monospacedDigit()
            .foregroundStyle(HomeBrand.muted)
    }

    private var metronome: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: openMetronome) {
                HStack(spacing: 12) {
                    Image(systemName: "metronome.fill").font(.title2).accessibilityHidden(true)
                    Text("自由節拍器").font(.title3.bold())
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.up.right").font(.headline).accessibilityHidden(true)
                }
                .padding(.vertical, 10).frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityIdentifier("openMetronome")
            ConfigurationSummary(configuration: store.configuration)
                .foregroundStyle(HomeBrand.muted)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeBrand.surface, in: RoundedRectangle(cornerRadius: 24))
    }
}

extension Lesson {
    var shortTitle: String {
        let parts = title.split(separator: " ", maxSplits: 1)
        return parts.count == 2 && Int(parts[0]) != nil ? String(parts[1]) : title
    }
}
