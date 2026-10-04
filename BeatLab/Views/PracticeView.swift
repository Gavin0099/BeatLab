import SwiftUI
import BeatLabCore

struct PracticeView: View {
    @EnvironmentObject private var store: ConfigurationStore
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var confirmReset = false
    @State private var confirmDiscard = false
    @State private var showLessons = false
    @ScaledMetric(relativeTo: .title) private var padHeight = 180.0
    @AccessibilityFocusState private var resultFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Color.clear.frame(height: 0).id("practiceTop")
                    if let notice = practice.notice {
                        BLStatusMessage(text: notice, symbol: "info.circle.fill")
                        if practice.progressVersionConflict {
                            Button("重設本機課程進度", role: .destructive) { confirmReset = true }.frame(minHeight: 44)
                        }
                    }
                    switch practice.phase {
                    case .preparing:
                        BLCard {
                            VStack(spacing: 20) {
                                ProgressView("準備拍子，馬上開始…").frame(maxWidth: .infinity)
                                Button("取消這次練習") { practice.cancel(audio: audio) }.buttonStyle(BLSecondaryButtonStyle())
                            }
                        }
                    case .playing:
                        playingPanel
                    case .finished:
                        if let summary = practice.summary { resultPanel(summary) }
                    case .idle:
                        lessonPreview
                    }
                    if practice.phase == .idle {
                        BLCard {
                            VStack(alignment: .leading, spacing: 14) {
                                BLSectionHeading(title: "顯示模式", subtitle: "入門專心跟拍；標準可以看細節、挑戰速度。")
                                BLModePicker()
                            }
                        }
                        if practice.mode == .standard { calibrationPanel }
                        DisclosureGroup("目前自由節拍器設定") {
                            ConfigurationSummary(configuration: store.configuration).padding(.top, 12)
                        }.font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    }
                }.padding(20).frame(maxWidth: BeatLabStyle.maxWidth, alignment: .leading).frame(maxWidth: .infinity)
            }
            .onChange(of: practice.phase) { phase in
                if reduceMotion { proxy.scrollTo("practiceTop", anchor: .top) }
                else { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("practiceTop", anchor: .top) } }
                resultFocused = phase == .finished
            }
            .onChange(of: practice.selected?.id) { _ in proxy.scrollTo("practiceTop", anchor: .top) }
        }
        .background(BeatLabStyle.canvas).foregroundStyle(BeatLabStyle.ink)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if practice.phase == .playing && !textSize.isAccessibilitySize {
                tapPanel.padding(.horizontal, 20).padding(.vertical, 12)
                    .frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
                    .background(BeatLabStyle.canvas)
            }
        }
        .navigationTitle("練習").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLessons) { lessonBrowser }
        .confirmationDialog("重設會清除星星、解鎖與對齊設定。節拍器設定會保留。", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("清除課程進度", role: .destructive) { practice.resetProgress() }
        }
        .confirmationDialog("這次成績還沒有保存。確定要離開結果嗎？", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("不保存，離開結果", role: .destructive) { practice.discardUnsavedResult() }
        }
    }

    private var lessonPreview: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let lesson = practice.selected ?? practice.recommended {
                BLCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("準備好了就出發").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentColor)
                        Text(lesson.shortTitle).font(.system(.title, design: .rounded).bold())
                        Text(lesson.instruction).font(.title3).foregroundStyle(BeatLabStyle.muted)
                        BLPill(title: "\(max(lesson.bpm, practice.practiceBPM)) BPM · \(lesson.bars) 小節", symbol: "metronome")
                        if practice.mode == .standard {
                            Stepper("挑戰速度：\(max(lesson.bpm, practice.practiceBPM)) BPM", value: Binding(
                                get: { max(lesson.bpm, practice.practiceBPM) }, set: { practice.setPracticeBPM($0) }
                            ), in: lesson.bpm...240, step: 5)
                        }
                        RhythmLane(pattern: lesson.pattern, elapsed: 0, bpm: lesson.bpm, isPlaying: false)
                        strokeLegend
                        Text("先聽 4 拍。看到「換你了」，再點跟拍區。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                        Button { practice.start(lesson, audio: audio) } label: { Label("開始跟拍", systemImage: "play.fill") }
                            .buttonStyle(BLPrimaryButtonStyle()).disabled(!practice.canPractice).accessibilityIdentifier("startLesson")
                    }
                }
                Button { showLessons = true } label: { Label("看看 10 個節奏挑戰", systemImage: "list.number") }
                    .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("browseLessons")
            } else {
                BLStatusMessage(text: "課程暫時無法載入。請重新開啟 App，或先使用自由節拍器。", symbol: "music.note")
            }
        }
    }

    private var strokeLegend: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { Text("R 右手"); Text("L 左手"); Text("— 休息") }
            VStack(alignment: .leading, spacing: 6) { Text("R 右手"); Text("L 左手"); Text("— 休息") }
        }.font(.subheadline.weight(.semibold)).foregroundStyle(BeatLabStyle.muted)
    }

    private var playingPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            let bpm = practice.isCalibrating ? 60 : practice.selected?.bpm ?? 60
            let countIn = 4 * 60.0 / Double(bpm)
            let started = practice.elapsed >= countIn
            let beats = practice.isCalibrating ? 20 : (practice.selected?.bars ?? 4) * 4
            let fraction = min(1, max(0, (practice.elapsed - countIn) / (Double(beats) * 60 / Double(bpm))))
            Text(practice.isCalibrating ? "跟拍對齊" : practice.selected?.shortTitle ?? "跟拍練習")
                .font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text(started ? "換你了，跟上節奏！" : "先聽 \(max(1, 4 - Int(practice.elapsed * Double(bpm) / 60))) 拍，再開始")
                .font(.headline).foregroundStyle(Color.accentColor).accessibilityIdentifier("practicePrompt")
            ProgressView(value: fraction).accessibilityLabel("本次練習進度").accessibilityValue("\(Int(fraction * 100))%")
            BLCard {
                VStack(spacing: 16) {
                    BeatVisualizer()
                    if let lesson = practice.selected, !practice.isCalibrating {
                        RhythmLane(pattern: lesson.pattern, elapsed: practice.elapsed, bpm: lesson.bpm, isPlaying: true)
                    }
                }
            }
            if textSize.isAccessibilitySize { tapPanel }
        }
    }
    private var tapPanel: some View {
        let bpm = practice.isCalibrating ? 60 : practice.selected?.bpm ?? 60
        let started = practice.elapsed >= 4 * 60.0 / Double(bpm)
        return VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(feedbackFill)
                RoundedRectangle(cornerRadius: 28).strokeBorder(feedbackColor, lineWidth: 2)
                VStack(spacing: 10) {
                    Image(systemName: feedbackSymbol).font(.largeTitle)
                    Text(started ? feedback : "先聽拍子").font(.system(.title, design: .rounded).bold())
                    Text(started ? "跟著格子，點這裡" : "聲音會帶你開始")
                        .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                }.foregroundStyle(feedbackColor).allowsHitTesting(false).accessibilityHidden(true)
                TapPad(feedback: started ? feedback : "先聽 4 拍，再開始") { time, accessible in practice.tap(at: time, accessibility: accessible) }
            }.frame(minHeight: padHeight)
            Button { practice.cancel(audio: audio, message: "這次練習已停止，沒有計入成績。準備好後再開始。") } label: {
                Label("停止練習", systemImage: "stop.fill")
            }.buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("stopPractice")
            Text("停止後，這次不計成績。").font(.caption).foregroundStyle(BeatLabStyle.muted)
        }
    }
    private var feedback: String {
        guard let hit = practice.latestHit else { return "點這裡" }
        switch hit.grade {
        case .early: return "早了一點"
        case .perfect: return "剛剛好！"
        case .late: return "晚了一點"
        case .extra: return "下一格，再跟上"
        }
    }
    private var feedbackColor: Color { practice.latestHit?.grade == .perfect ? BeatLabStyle.success : Color.accentColor }
    private var feedbackFill: Color { practice.latestHit?.grade == .perfect ? BeatLabStyle.successSoft : BeatLabStyle.accentSoft }
    private var feedbackSymbol: String {
        switch practice.latestHit?.grade {
        case .perfect: return "checkmark.circle.fill"
        case .early: return "arrow.backward.circle"
        case .late: return "arrow.forward.circle"
        case .extra: return "arrow.clockwise.circle"
        case nil: return "hand.tap.fill"
        }
    }
    private func resultPanel(_ summary: TimingSummary) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            BLCard {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: practice.isCalibrating ? "ear.badge.checkmark" : practice.stars > 0 ? "star.circle.fill" : "hand.thumbsup.fill")
                        .font(.system(size: 44)).foregroundStyle(practice.stars > 0 ? BeatLabStyle.reward : Color.accentColor)
                        .accessibilityHidden(true)
                    Text(resultTitle).font(.system(.title, design: .rounded).bold())
                        .accessibilityFocused($resultFocused).accessibilityAddTraits(.isHeader)
                    if !practice.isCalibrating {
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: index < practice.stars ? "star.fill" : "star")
                                    .font(.title).foregroundStyle(BeatLabStyle.reward)
                            }
                        }.accessibilityElement(children: .ignore).accessibilityLabel("這次得到 \(practice.stars) 顆星")
                        Text(resultAdvice(summary)).foregroundStyle(BeatLabStyle.muted)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { scoreStats(summary) }
                        VStack(alignment: .leading, spacing: 12) { scoreStats(summary) }
                    }
                    if practice.needsSaveRetry {
                        BLStatusMessage(text: "成績尚未保存，星星與解鎖還沒更新。")
                        Button("重試保存") { practice.retrySave() }.buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("retryProgressSave")
                        Button("不保存，離開結果", role: .destructive) { confirmDiscard = true }.frame(minHeight: 44)
                    } else if practice.isCalibrating {
                        Button("回到課程") {
                            if let lesson = practice.recommended { practice.select(lesson) }
                        }.buttonStyle(BLPrimaryButtonStyle())
                    } else if let lesson = practice.selected {
                        if let next = nextLesson, practice.resultSaved {
                            Button { practice.select(next) } label: { Label("挑戰下一關", systemImage: "arrow.right") }
                                .buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("nextLesson")
                            Button("再練一次") { practice.start(lesson, audio: audio) }.buttonStyle(BLSecondaryButtonStyle())
                        } else {
                            Button { practice.start(lesson, audio: audio) } label: { Label("再練一次", systemImage: "arrow.clockwise") }
                                .buttonStyle(BLPrimaryButtonStyle()).disabled(!practice.canPractice)
                        }
                    }
                }
            }.accessibilityIdentifier("practiceSummary")
            if practice.mode == .standard { technicalSummary(summary) }
            if !practice.needsSaveRetry {
                Button { showLessons = true } label: { Label("回到課程列表", systemImage: "list.number") }
                    .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("browseLessons")
            }
        }
    }
    private var resultTitle: String {
        if practice.isCalibrating {
            if practice.needsSaveRetry { return "對齊算好了，等待保存" }
            return practice.calibrationSaved ? "對齊完成" : "對齊需要再試一次"
        }
        return practice.stars > 0 ? "做到了！節奏跟上了" : "完成一次，就是進步"
    }
    private var nextLesson: Lesson? {
        guard practice.stars > 0, let selected = practice.selected,
              let index = practice.lessons.firstIndex(where: { $0.id == selected.id }), index + 1 < practice.lessons.count else { return nil }
        let next = practice.lessons[index + 1]
        return practice.unlocked(next) ? next : nil
    }
    private func resultAdvice(_ summary: TimingSummary) -> String {
        if practice.stars > 0 {
            if !practice.resultSaved { return "這次挑戰通過了，保存後就能保留星星。" }
            if practice.selected?.id == practice.lessons.last?.id { return "十個挑戰完成了！可以再練一次，讓每一下更穩。" }
            return "星星已保存。準備好，就試試下一個節奏。"
        }
        if summary.extraCount > summary.missedCount { return "看到 — 先休息，跟著 R/L 再點。" }
        if summary.missedCount > 0 { return "先把每個大拍跟上，再慢慢加細節。" }
        return "下次試著把每一下都打得更均勻。"
    }
    @ViewBuilder
    private func scoreStats(_ summary: TimingSummary) -> some View {
        metric("跟上的拍", "\(summary.matched.count)/\(summary.targetCount)")
        metric("剛剛好", "\(Int(summary.perfectRate * 100))%")
    }
    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(.title2, design: .rounded).bold()).monospacedDigit()
            Text(title).font(.subheadline).foregroundStyle(BeatLabStyle.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .background(BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .combine)
    }
    private func technicalSummary(_ summary: TimingSummary) -> some View {
        BLCard {
            DisclosureGroup("查看這次練習細節") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("漏拍 \(summary.missedCount) · 多打 \(summary.extraCount)")
                    if practice.calibrated, let mae = summary.meanAbsoluteError,
                       let signed = summary.meanSignedError, let spread = summary.standardDeviation {
                        Text(String(format: "對齊後估計\n平均誤差 %.0f ms\n偏差 %+.0f ms\n穩定度 %.0f ms", mae * 1000, signed * 1000, spread * 1000))
                        Text("這是跟拍對齊估計，會包含你的跟拍習慣。")
                    } else { Text("這個音訊輸出尚未對齊，先看命中與漏拍。") }
                    if let json = practice.diagnosticJSON {
                        ShareLink(item: json) { Label("匯出這次練習資料", systemImage: "square.and.arrow.up") }.frame(minHeight: 44)
                    }
                }.font(.subheadline).foregroundStyle(BeatLabStyle.muted).padding(.top, 14)
            }.font(.headline)
        }
    }
    private var calibrationPanel: some View {
        BLCard {
            VStack(alignment: .leading, spacing: 14) {
                BLSectionHeading(title: "讓聲音與手指更對齊", subtitle: "先聽 4 拍，再跟 20 拍。使用喇叭或有線耳機。")
                Text("這是跟拍估計，包含你的習慣；換音訊輸出後需重做。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                Button("開始對齊練習") { practice.startCalibration(audio: audio) }
                    .buttonStyle(BLSecondaryButtonStyle()).disabled(!practice.canPractice).accessibilityIdentifier("startCalibration")
            }
        }
    }
    private var lessonBrowser: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BLSectionHeading(title: "一步一步，找到節奏", subtitle: "完成前一關，就能解鎖下一個挑戰。R/L 是手別提示，不辨識你用了哪隻手。")
                    VStack(spacing: 0) {
                        ForEach(Array(practice.lessons.enumerated()), id: \.element.id) { index, lesson in
                            lessonRow(lesson, index: index)
                            if index + 1 < practice.lessons.count { Divider().padding(.leading, 70) }
                        }
                    }.background(BeatLabStyle.surface, in: RoundedRectangle(cornerRadius: 24))
                }.padding(20).frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
            }.background(BeatLabStyle.canvas)
                .navigationTitle("節奏挑戰").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showLessons = false }.frame(minHeight: 44) } }
        }
    }
    private func lessonRow(_ lesson: Lesson, index: Int) -> some View {
        let unlocked = practice.unlocked(lesson)
        let stars = practice.progress.results[lesson.id]?.stars ?? 0
        return Button {
            guard unlocked else { return }
            practice.select(lesson); showLessons = false
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(unlocked ? BeatLabStyle.accentSoft : BeatLabStyle.canvas)
                    if unlocked { Text(String(format: "%02d", index + 1)).font(.headline.monospacedDigit()) }
                    else { Image(systemName: "lock.fill") }
                }.frame(width: 44, height: 44).foregroundStyle(unlocked ? Color.accentColor : BeatLabStyle.muted)
                VStack(alignment: .leading, spacing: 6) {
                    Text(lesson.shortTitle).font(.headline).foregroundStyle(BeatLabStyle.ink)
                    Text(unlocked ? "\(lesson.bpm) BPM · \(stars > 0 ? "已完成" : "準備開始")" : "完成第 \(index) 關後解鎖")
                        .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    if stars > 0 {
                        Text(String(repeating: "★", count: stars)).foregroundStyle(BeatLabStyle.reward)
                        if practice.mode == .standard, let best = practice.progress.results[lesson.id] {
                            Text("最佳 \(best.bestBPM) BPM").font(.caption).foregroundStyle(BeatLabStyle.muted)
                        }
                    }
                }
                Spacer(minLength: 0)
                if unlocked { Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(BeatLabStyle.muted) }
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!unlocked).accessibilityIdentifier("lesson.\(lesson.id)")
            .accessibilityLabel("第 \(index + 1) 關，\(lesson.shortTitle)")
            .accessibilityValue(unlocked ? stars > 0 ? "已完成，\(stars) 顆星" : "可開始" : "完成第 \(index) 關後解鎖")
    }
}
