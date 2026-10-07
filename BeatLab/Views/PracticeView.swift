import SwiftUI
import BeatLabCore

struct PracticeView: View {
    var preparationRequest: Int = 0
    @EnvironmentObject private var store: ConfigurationStore
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var confirmReset = false
    @State private var confirmDiscard = false
    @State private var showLessons = false
    @State private var showSettings = false
    @State private var showCompanions = false
    @State private var companion: AdventureCompanion = .dinosaur
    @State private var jump = RhythmJumpPresentation()
    @State private var reward = RhythmRewardPresentation()
    @State private var hopHeight: CGFloat = 0
    @State private var hopTask: Task<Void, Never>?
    @State private var showingJourney = true
    @State private var chapter = 0
    @State private var hasAppeared = false
    @AccessibilityFocusState private var resultFocused: Bool

    private var phaseContent: some View {
        Group {
        if practice.phase == .playing && !practice.isCalibrating, let lesson = practice.selected {
            if practice.isEggMission {
                EggMissionView(accepted: jump.accepted, streak: reward.perfectStreak, stop: {
                    practice.cancel(audio: audio, message: "這次挑戰已停止，沒有計入成績。"); showingJourney = true
                }, theme: missionTheme)
            } else {
            runnerChallenge(lesson)
            }
        } else {
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
                                Button("取消這次練習") { practice.cancel(audio: audio); showingJourney = true }.buttonStyle(BLSecondaryButtonStyle())
                            }
                        }
                    case .playing:
                        playingPanel
                    case .finished:
                        if let summary = practice.summary { resultPanel(summary) }
                    case .idle:
                        if showingJourney { journeyPanel }
                        else { lessonPreview }
                    }
                }.padding(20).frame(maxWidth: BeatLabStyle.maxWidth, alignment: .leading).frame(maxWidth: .infinity)
            }
            .onChange(of: practice.phase) { phase in
                if reduceMotion { proxy.scrollTo("practiceTop", anchor: .top) }
                else { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("practiceTop", anchor: .top) } }
                resultFocused = phase == .finished
                hopTask?.cancel(); hopTask = nil; hopHeight = 0
                if phase == .preparing || phase == .idle { jump = RhythmJumpPresentation(); reward = RhythmRewardPresentation() }
            }
            .onChange(of: practice.selected?.id) { _ in
                proxy.scrollTo("practiceTop", anchor: .top)
            }
        }
        }
        }
    }
    var body: some View {
        phaseContent.background(BeatLabStyle.canvas).foregroundStyle(BeatLabStyle.ink)
        .onChange(of: practice.phase) { phase in
            hopTask?.cancel(); hopTask = nil; hopHeight = 0
            if phase == .preparing || phase == .idle { jump = RhythmJumpPresentation(); reward = RhythmRewardPresentation() }
            resultFocused = phase == .finished
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if practice.phase == .playing && practice.isCalibrating && !textSize.isAccessibilitySize {
                tapPanel.padding(.horizontal, 20).padding(.vertical, 12)
                    .frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
                    .background(BeatLabStyle.canvas)
            }
        }
        .navigationTitle("練習").navigationBarTitleDisplayMode(.inline)
        .toolbar(practice.phase == .playing && practice.isEggMission ? .hidden : .visible, for: .navigationBar)
        .sheet(isPresented: $showLessons) { lessonBrowser }
        .sheet(isPresented: $showSettings) { practiceSettings }
        .sheet(isPresented: $showCompanions) { companionPicker }
        .toolbar {
            if practice.phase == .idle {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: { BLToolbarIcon(symbol: "gearshape") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("練習設定")
                        .accessibilityIdentifier("practiceSettings")
                }
            }
        }
        .onAppear {
            guard !hasAppeared else { return }; hasAppeared = true
            showingJourney = practice.selected == nil
        }
        .onChange(of: practice.latestHit) { hit in recordPresentation(hit) }
        .onChange(of: reduceMotion) { enabled in
            if enabled { hopTask?.cancel(); hopHeight = 0 }
        }
        .onDisappear { hopTask?.cancel(); hopTask = nil; hopHeight = 0 }
        .onChange(of: preparationRequest) { _ in showingJourney = false }
        .confirmationDialog("重設會清除星星、解鎖與對齊設定。節拍器設定會保留。", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("清除課程進度", role: .destructive) { practice.resetProgress(); showingJourney = true }
        }
        .confirmationDialog("這次成績還沒有保存。確定要離開結果嗎？", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("不保存，離開結果", role: .destructive) { practice.discardUnsavedResult(); showingJourney = true }
        }
    }

    private func recordPresentation(_ hit: TimingHit?) {
        guard let hit, let lesson = practice.selected, !practice.isCalibrating else { return }
        let matched = jump.record(hit, pattern: lesson.pattern, bars: lesson.bars)
        reward.record(hit, accepted: matched, pattern: lesson.pattern)
        hopTask?.cancel(); hopHeight = 0
        guard !reduceMotion, !practice.isEggMission else { return }
        hopTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.12)) { hopHeight = matched ? (hit.grade == .perfect ? -60 : -44) : -12 }
            try? await Task.sleep(nanoseconds: 130_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.18)) { hopHeight = 0 }
        }
    }

    private var completed: Int {
        practice.lessons.filter { (practice.progress.results[$0.id]?.stars ?? 0) > 0 }.count
    }
    private let chapters = ["大拍起步", "分拍與留白", "節奏高手"]
    private var chapterRange: Range<Int> { chapter == 0 ? 0..<2 : chapter == 1 ? 2..<6 : 6..<10 }
    private var journeyPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            adventureWelcome
            if let lesson = practice.recommended {
                BLCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(completed == practice.lessons.count ? "再練一次" : "下一個挑戰")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentColor)
                        Text("第 \(lessonNumber(lesson)) 關 · \(lesson.shortTitle)").font(.title2.bold())
                        Text(lesson.instruction).foregroundStyle(BeatLabStyle.muted)
                        Button { openPreparation(lesson) } label: { Label("準備挑戰", systemImage: "play") }
                            .buttonStyle(BLPrimaryButtonStyle()).disabled(!practice.canPractice)
                            .accessibilityIdentifier("prepareRecommended")
                    }
                }
            } else {
                BLStatusMessage(text: "課程暫時無法載入，可以先使用自由節拍器。", symbol: "music.note")
            }
            ViewThatFits(in: .horizontal) {
                HStack {
                    Label("節奏旅程", systemImage: "map.fill").font(.headline).fixedSize()
                    Spacer()
                    journeyProgress.fixedSize()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Label("節奏旅程", systemImage: "map.fill").font(.headline)
                    journeyProgress
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) { chapterButtons }
                VStack(alignment: .leading, spacing: 6) { chapterButtons }
            }
            VStack(spacing: 0) {
                AdventureScene(world: chapter, companion: companion).frame(height: 132).clipped()
                VStack(alignment: .leading, spacing: 6) {
                    Text(worldNames[chapter]).font(.system(.title2, design: .rounded).bold())
                        .accessibilityIdentifier("adventureDestination")
                    Text(worldMissions[chapter]).font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                VStack(spacing: 0) {
                    ForEach(Array(practice.lessons.enumerated()).filter { chapterRange.contains($0.offset) }, id: \.element.id) { index, lesson in
                        journeyNode(lesson, index: index)
                        if index != min(chapterRange.upperBound, practice.lessons.count) - 1 {
                            AdventureTrail(reversed: index % 2 != 0)
                                .stroke(BeatLabStyle.line, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 9]))
                                .frame(height: 30).padding(.horizontal, 52).accessibilityHidden(true)
                        }
                    }
                }.padding(.horizontal, 12).padding(.bottom, 20)
            }.background(BeatLabStyle.surface, in: RoundedRectangle(cornerRadius: 28))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            adventureStickers
            Button { showLessons = true } label: { Label("查看全部關卡", systemImage: "list.number") }
                .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("browseLessons")
        }
    }
    private let worldNames = ["起拍小島", "回聲森林", "星光舞台"]
    private var journeyProgress: some View {
        Text("\(completed) / \(practice.lessons.count) 關完成")
            .font(.subheadline.monospacedDigit()).foregroundStyle(BeatLabStyle.muted)
            .accessibilityIdentifier("journeyProgress")
    }
    private let worldMissions = ["跟著夥伴，找到第一個大拍。", "穿過森林，聽見拍子之間的空間。", "走上舞台，把你的節奏打出來！"]
    private let worldSymbols = ["sun.max.fill", "leaf.fill", "sparkles"]
    private func earnedWorld(_ index: Int) -> Bool {
        let range = index == 0 ? 0..<2 : index == 1 ? 2..<6 : 6..<10
        let lessons = practice.lessons.enumerated().filter { range.contains($0.offset) }
        return lessons.count == range.count && lessons.allSatisfy { (practice.progress.results[$0.element.id]?.stars ?? 0) > 0 }
    }
    private var adventureWelcome: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("一起跟拍冒險").font(BeatLabStyle.TypeScale.label).foregroundStyle(HomeBrand.heroInk)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { welcomeWords; GameCompanion(companion: companion).frame(width: 130, height: 140) }
                VStack(alignment: .leading, spacing: 8) { welcomeWords; GameCompanion(companion: companion).frame(width: 130, height: 140).frame(maxWidth: .infinity) }
            }
            Button { showCompanions = true } label: { Label("換個夥伴", systemImage: "person.crop.circle.badge.checkmark") }
                .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("chooseCompanion")
        }.padding(20).background(HomeBrand.hero, in: RoundedRectangle(cornerRadius: BeatLabStyle.Radius.card))
            .foregroundStyle(HomeBrand.heroInk)
    }
    private var welcomeWords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(completed == practice.lessons.count && completed > 0 ? "你是節奏探險家！" : "出發，找大拍！")
                .font(.system(.title, design: .rounded).weight(.black)).accessibilityAddTraits(.isHeader)
            Text("\(companion.title)準備好了！").font(.subheadline.bold()).accessibilityIdentifier("adventureCompanion")
            Text(completed > 0 ? "下一站，讓更多拍子亮起來！" : "一起把小島的拍子喚醒吧。")
                .font(.subheadline.weight(.medium)).fixedSize(horizontal: false, vertical: true)
        }
    }
    private var companionPicker: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("誰陪你一起打鼓？").font(.system(.title, design: .rounded).bold()).accessibilityAddTraits(.isHeader)
                    Text("選喜歡的夥伴，一起去冒險。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    ForEach(AdventureCompanion.allCases, id: \.self) { option in
                        Button { companion = option; showCompanions = false } label: {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 18) { GameCompanion(companion: option).frame(width: 86, height: 100); companionWords(option) }
                                VStack(alignment: .leading, spacing: 12) { GameCompanion(companion: option).frame(width: 110, height: 120); companionWords(option) }
                            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                                .background(companion == option ? BeatLabStyle.accentSoft : BeatLabStyle.surface, in: RoundedRectangle(cornerRadius: 24))
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("companion.\(option.rawValue)")
                            .accessibilityLabel("選擇\(option.title)").accessibilityValue(companion == option ? "已選擇" : "可選擇")
                    }
                }.padding(20).frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
            }.background(BeatLabStyle.canvas).foregroundStyle(BeatLabStyle.ink)
                .navigationTitle("選擇夥伴").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showCompanions = false }.frame(minHeight: 44) } }
        }
    }
    private func companionWords(_ option: AdventureCompanion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(option.title, systemImage: companion == option ? "checkmark.circle.fill" : "circle")
                .font(.system(.title2, design: .rounded).bold())
            if !textSize.isAccessibilitySize {
                Text(option.invitation).font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var adventureStickers: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("我的冒險徽章", systemImage: "seal.fill").font(.headline)
            Text("完成一個篇章，就能點亮它的徽章。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) { stickerItems }
                VStack(alignment: .leading, spacing: 16) { stickerItems }
            }
        }.padding(20).background(BeatLabStyle.surface, in: RoundedRectangle(cornerRadius: 24))
    }
    private var stickerItems: some View {
        ForEach(0..<3, id: \.self) { index in
            VStack(spacing: 8) {
                Image(systemName: earnedWorld(index) ? worldSymbols[index] : "lock.fill")
                    .font(.title2).foregroundStyle(earnedWorld(index) ? BeatLabStyle.reward : BeatLabStyle.muted)
                    .frame(width: 64, height: 64)
                    .background(earnedWorld(index) ? BeatLabStyle.rewardSoft : BeatLabStyle.canvas, in: RoundedRectangle(cornerRadius: 22))
                    .rotationEffect(.degrees(index == 1 ? 6 : -6)).accessibilityHidden(true)
                Text(worldNames[index]).font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                Text(earnedWorld(index) ? "已獲得" : "等待點亮").font(.caption).foregroundStyle(BeatLabStyle.muted)
            }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
                .accessibilityLabel("\(worldNames[index])徽章")
                .accessibilityValue(earnedWorld(index) ? "已獲得" : "完成篇章後獲得")
                .accessibilityIdentifier("adventureSticker.\(index)")
        }
    }
    private var chapterButtons: some View {
        ForEach(chapters.indices, id: \.self) { index in
            Button { chapter = index } label: {
                Text(chapters[index]).font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 10)
                    .foregroundStyle(chapter == index ? Color.accentColor : BeatLabStyle.muted)
                    .background(chapter == index ? BeatLabStyle.accentSoft : BeatLabStyle.canvas, in: RoundedRectangle(cornerRadius: 12))
            }.buttonStyle(.plain).accessibilityAddTraits(chapter == index ? .isSelected : [])
                .accessibilityIdentifier("journeyChapter.\(index)")
        }
    }
    private func lessonNumber(_ lesson: Lesson) -> Int {
        (practice.lessons.firstIndex(where: { $0.id == lesson.id }) ?? 0) + 1
    }
    private func openPreparation(_ lesson: Lesson) {
        practice.select(lesson); showingJourney = false
    }
    private func journeyNode(_ lesson: Lesson, index: Int) -> some View {
        let unlocked = practice.unlocked(lesson)
        let stars = practice.progress.results[lesson.id]?.stars ?? 0
        let current = lesson.id == practice.recommended?.id && stars == 0
        let badge = ZStack {
                    Ellipse().fill(stars > 0 ? BeatLabStyle.rewardSoft : BeatLabStyle.accentSoft)
                        .frame(width: 90, height: 30).offset(y: 34)
                    Circle().fill(stars > 0 ? BeatLabStyle.rewardSoft : current ? Color.accentColor : BeatLabStyle.canvas)
                    if unlocked { Text(String(format: "%02d", index + 1)).font(.system(.title2, design: .rounded).bold()) }
                    else { Image(systemName: "lock.fill").font(.title3) }
                }.frame(width: 78, height: 78)
                    .foregroundStyle(stars > 0 ? BeatLabStyle.reward : current ? BeatLabStyle.onAccent : BeatLabStyle.muted)
                    .overlay(Circle().strokeBorder(current ? BeatLabStyle.accentSoft : Color.clear, lineWidth: 4))
        let details = VStack(alignment: .leading, spacing: 6) {
                    Text(lesson.shortTitle).font(.headline).foregroundStyle(BeatLabStyle.ink)
                    Text(unlocked ? "\(stars > 0 ? "已完成" : "準備挑戰") · \(lesson.bpm) BPM" : "完成第 \(index) 關解鎖")
                        .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { star in
                            Image(systemName: star < stars ? "star.fill" : "star")
                                .foregroundStyle(star < stars ? BeatLabStyle.reward : BeatLabStyle.muted)
                        }
                        if current { Text("出發！").font(.caption.bold()).foregroundStyle(Color.accentColor).padding(.leading, 4) }
                    }.font(.caption).accessibilityHidden(true)
                }.fixedSize(horizontal: false, vertical: true)
        return Button { openPreparation(lesson) } label: {
            Group {
                if textSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 16) { badge; details }
                } else {
                    HStack(spacing: 16) { badge; details }
                }
            }.padding(.vertical, 12).padding(.horizontal, 8)
                .frame(maxWidth: textSize.isAccessibilitySize ? .infinity : 360, alignment: .leading)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!unlocked || !practice.canPractice)
            .frame(maxWidth: .infinity, alignment: index % 2 == 0 ? .leading : .trailing)
            .accessibilityIdentifier("journeyLesson.\(lesson.id)")
            .accessibilityLabel("第 \(index + 1) 關，\(lesson.shortTitle)")
            .accessibilityValue(unlocked ? stars > 0 ? "已完成，\(stars) 顆星" : "可開始" : "完成第 \(index) 關後解鎖")
    }

    private var practiceSettings: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BLCard {
                        VStack(alignment: .leading, spacing: 14) {
                            BLSectionHeading(title: "顯示模式", subtitle: "入門專心跟拍；標準可以看細節、挑戰速度。")
                            BLModePicker()
                        }
                    }
                    if practice.mode == .standard { calibrationPanel }
                    DisclosureGroup("目前自由節拍器設定") {
                        ConfigurationSummary(configuration: store.configuration).padding(.top, 12)
                    }.foregroundStyle(BeatLabStyle.muted)
                }.padding(20).frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
            }.background(BeatLabStyle.canvas)
                .navigationTitle("練習設定").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showSettings = false }.frame(minHeight: 44) } }
        }
    }

    private var lessonPreview: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button { showingJourney = true } label: { Label("關卡", systemImage: "arrow.left") }
                .frame(minHeight: 44).accessibilityIdentifier("backToJourney")
            if let lesson = practice.selected ?? practice.recommended {
                if missionEligible(lesson) {
                    missionPreparation(lesson)
                } else {
                BLCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("第 \(lessonNumber(lesson)) 關 · 下一個節奏，由你打出來").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentColor)
                            .accessibilityIdentifier("preparedLessonNumber")
                        Text(lesson.shortTitle).font(.system(.title, design: .rounded).bold())
                        Text(lesson.instruction).font(.title3).foregroundStyle(BeatLabStyle.muted)
                        BLPill(title: "\(max(lesson.bpm, practice.practiceBPM)) BPM · \(lesson.bars) 小節", symbol: "metronome")
                        if practice.mode == .standard {
                            Stepper("挑戰速度：\(max(lesson.bpm, practice.practiceBPM)) BPM", value: Binding(
                                get: { max(lesson.bpm, practice.practiceBPM) }, set: { practice.setPracticeBPM($0) }
                            ), in: lesson.bpm...240, step: 5)
                        }
                        HStack(spacing: 12) {
                            GameCompanion(companion: companion).frame(width: 96, height: 110)
                            Text("我先打 4 拍，\n接著就換你囉！").font(.system(.title3, design: .rounded).bold())
                                .fixedSize(horizontal: false, vertical: true)
                        }.frame(maxWidth: .infinity).padding(12)
                            .background(BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 22))
                        RhythmLane(pattern: lesson.pattern, elapsed: 0, bpm: lesson.bpm, isPlaying: false)
                        strokeLegend
                        Text("先聽 4 拍。石頭到達腳下時，跟著拍子按「跳！」。休止格沒有石頭，先等一下。R/L 是手別提示，不辨識使用哪隻手。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                        Button { startLesson(lesson) } label: { Label("開始挑戰", systemImage: "play.fill") }
                            .buttonStyle(BLPrimaryButtonStyle()).disabled(!practice.canPractice).accessibilityIdentifier("startLesson")
                    }
                }
                }
                Button { showLessons = true } label: { Label("看看 10 個節奏挑戰", systemImage: "list.number") }
                    .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("browseLessons")
            } else {
                BLStatusMessage(text: "課程暫時無法載入。請重新開啟 App，或先使用自由節拍器。", symbol: "music.note")
            }
        }
    }

    private var missionTheme: RunnerTheme { RunnerTheme(rawValue: companion.rawValue) ?? .dinosaur }
    private func missionEligible(_ lesson: Lesson) -> Bool {
        lesson.id == "first-beat" && max(lesson.bpm, practice.practiceBPM) == 60
    }
    private func startLesson(_ lesson: Lesson) {
        practice.start(lesson, audio: audio, eggMission: missionEligible(lesson))
    }
    private func missionPreparation(_ lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("第 1 關 · 找到大拍").font(.subheadline.bold()).foregroundStyle(BeatLabStyle.muted)
                .accessibilityIdentifier("preparedLessonNumber")
            Text(missionTheme.mission).font(.system(.title, design: .rounded).bold())
            EggMissionScene(theme: missionTheme, elapsed: 0, preparing: true, platformJourney: true).frame(height: 260)
            Text("先聽 4 拍，再跟鼓聲按一下，跳到亮起的下一座小島。")
                .font(.title3.bold()).fixedSize(horizontal: false, vertical: true)
            Text("用右手跟拍 · 60 BPM · 約 20 秒").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
            Text("漏拍會跌下去，再接回原來的小島。準備好，下一拍再跳；多打不會前進。")
                .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
            if practice.mode == .standard {
                Stepper("挑戰速度：\(practice.practiceBPM) BPM", value: Binding(
                    get: { practice.practiceBPM }, set: { practice.setPracticeBPM($0) }
                ), in: lesson.bpm...240, step: 5)
            }
            Button { startLesson(lesson) } label: { Label("帶\(missionTheme.item)出發！", systemImage: "play.fill") }
                .buttonStyle(BLPrimaryButtonStyle()).disabled(!practice.canPractice).accessibilityIdentifier("startLesson")
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
            ViewThatFits(in: .horizontal) {
                HStack { challengeHeading; Spacer(); Text("\(bpm) BPM").monospacedDigit() }
                VStack(alignment: .leading, spacing: 6) { challengeHeading; Text("\(bpm) BPM").monospacedDigit() }
            }.font(.subheadline).foregroundStyle(BeatLabStyle.muted)
            Text(started ? "換你了，跟上節奏！" : "先聽 \(max(1, 4 - Int(practice.elapsed * Double(bpm) / 60))) 拍，再開始")
                .font(.system(.title2, design: .rounded).bold()).accessibilityIdentifier("practicePrompt")
            if !practice.isCalibrating {
                Text("\(companion.title)陪你跟拍").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    .accessibilityIdentifier("activeCompanion")
            }
            if practice.isCalibrating {
                ProgressView(value: fraction).accessibilityLabel("本次練習進度").accessibilityValue("\(Int(fraction * 100))%")
            } else {
                let bars = practice.selected?.bars ?? 4
                let done = max(0, Int((practice.elapsed - countIn) * Double(bpm) / 240))
                Text(started ? "第 \(min(bars, done + 1)) / \(bars) 小節" : "先聽 4 拍")
                    .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                HStack(spacing: 6) {
                    ForEach(0..<bars, id: \.self) { bar in
                        Capsule().fill(bar < done ? Color.accentColor : BeatLabStyle.line).frame(height: 5)
                    }
                }.accessibilityElement(children: .ignore).accessibilityLabel("挑戰進度")
                    .accessibilityValue("\(min(bars, done)) / \(bars) 小節完成")
            }
            BLCard {
                VStack(spacing: 16) {
                    if practice.isCalibrating { BeatVisualizer() }
                    if let lesson = practice.selected, !practice.isCalibrating {
                        RhythmLane(pattern: lesson.pattern, elapsed: practice.elapsed, bpm: lesson.bpm, isPlaying: true)
                        strokeLegend
                    }
                }
            }
            if textSize.isAccessibilitySize { tapPanel }
        }
    }
    private var challengeHeading: some View {
        Text(practice.isCalibrating ? "跟拍對齊" : "第 \(practice.selected.map(lessonNumber) ?? 1) 關 · \(practice.selected?.shortTitle ?? "跟拍練習")")
            .fixedSize(horizontal: false, vertical: true)
    }
    private var tapPanel: some View {
        let bpm = practice.isCalibrating ? 60 : practice.selected?.bpm ?? 60
        let started = practice.elapsed >= 4 * 60.0 / Double(bpm)
        return VStack(spacing: 10) {
            if !practice.isCalibrating, let lesson = practice.selected {
                jumpStage(lesson)
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(feedbackFill)
                    VStack(spacing: 4) {
                        Text(started ? feedback : "先聽 4 拍").font(.system(.title3, design: .rounded).bold())
                        Text("點一下，跳一格").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    }.padding(14).multilineTextAlignment(.center).accessibilityHidden(true).allowsHitTesting(false)
                    TapPad(feedback: started ? feedback : "先聽 4 拍，再開始") { time, accessible in practice.tap(at: time, accessibility: accessible) }
                }.frame(height: textSize.isAccessibilitySize ? 140 : 86)
            } else {
            ZStack {
                Circle().fill(feedbackFill)
                Circle().strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 8).padding(8)
                Circle().strokeBorder(feedbackColor.opacity(0.18), style: StrokeStyle(lineWidth: 2, dash: [4, 10])).padding(23)
                VStack(spacing: 10) {
                    if practice.isCalibrating { Image(systemName: feedbackSymbol).font(.largeTitle) }
                    else { GameCompanion(companion: companion, celebrating: started && practice.latestHit?.grade == .perfect).frame(width: 74, height: 76) }
                    Text(started ? feedback : "先聽拍子").font(.system(.title2, design: .rounded).bold()).multilineTextAlignment(.center)
                    Text(started ? "螢幕鼓墊" : "聲音會帶你開始")
                        .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                }.padding(24).foregroundStyle(feedbackColor).allowsHitTesting(false).accessibilityHidden(true)
                TapPad(feedback: started ? feedback : "先聽 4 拍，再開始") { time, accessible in practice.tap(at: time, accessibility: accessible) }
            }.aspectRatio(1, contentMode: .fit).frame(maxWidth: textSize.isAccessibilitySize ? 320 : 240)
            }
            Button { practice.cancel(audio: audio, message: "這次挑戰已停止，沒有計入成績。"); showingJourney = true } label: {
                Label("停止挑戰", systemImage: "stop.fill")
            }.buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("stopPractice")
            Text("停止後，這次不計成績。").font(.caption).foregroundStyle(BeatLabStyle.muted)
        }
    }
    private func runnerChallenge(_ lesson: Lesson) -> some View {
        GeometryReader { geometry in
            // One composition owns the available height. A short viewport or
            // large text scrolls everything together, never beneath an inset.
            let stageHeight = max(140, min(360, geometry.size.height - 430))
            ViewThatFits(in: .vertical) {
                runnerContent(lesson, stageHeight: stageHeight)
                ScrollView { runnerContent(lesson, stageHeight: 220) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
        }
    }
    private func runnerContent(_ lesson: Lesson, stageHeight: CGFloat) -> some View {
        let countIn = 4 * 60.0 / Double(lesson.bpm)
        let started = practice.elapsed >= countIn
        let fraction = min(1, max(0, (practice.elapsed - countIn) / (Double(lesson.bars * 4) * 60 / Double(lesson.bpm))))
        return VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("第 \(lessonNumber(lesson)) 關 · 節奏跑酷").font(.headline)
                        .accessibilityIdentifier("activeLessonNumber")
                    Text("\(companion.title)陪你跟拍").font(.caption).foregroundStyle(BeatLabStyle.muted)
                        .accessibilityIdentifier("activeCompanion")
                }
                Spacer()
                Text("\(lesson.bpm) BPM").font(.subheadline.monospacedDigit()).foregroundStyle(BeatLabStyle.muted)
            }
            ProgressView(value: fraction).tint(BeatLabStyle.success)
                .accessibilityLabel("距離終點").accessibilityValue("\(Int(fraction * 100))%")
            Text(started ? (recoveryStep != nil ? "站穩，聽下一拍再跳！" : "石頭到腳下，跟拍跳！") : "先聽 \(max(1, 4 - Int(practice.elapsed * Double(lesson.bpm) / 60))) 拍")
                .font(.system(.headline, design: .rounded)).accessibilityIdentifier("jumpCue")
            runnerStage(lesson).frame(height: stageHeight)
            // R/L/rest stay visible close to the jump control.
            runnerRhythm(lesson)
            ViewThatFits(in: .horizontal) {
                HStack { crossingCount; Spacer(); comboLabel }
                VStack(spacing: 4) { crossingCount; comboLabel }
            }
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color(red: 1, green: 0.84, blue: 0.43))
                HStack(spacing: 16) {
                    Image(systemName: "arrow.up").font(.title2.bold())
                    VStack(spacing: 4) {
                        Text("跳！").font(.system(.title2, design: .rounded).bold())
                        Text(started ? feedback : "聽完 4 拍再跳").font(.subheadline)
                    }
                }.padding(12).foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.21))
                    .accessibilityHidden(true).allowsHitTesting(false)
                TapPad(feedback: started ? "跳，\(feedback)" : "先聽 4 拍，再跳") { time, accessible in
                    practice.tap(at: time, accessibility: accessible)
                }
            }.frame(height: textSize.isAccessibilitySize ? 144 : 80)
            Button { practice.cancel(audio: audio, message: "這次挑戰已停止，沒有計入成績。"); showingJourney = true } label: {
                Label("停止挑戰", systemImage: "stop.fill").frame(maxWidth: .infinity, minHeight: 44)
            }.accessibilityIdentifier("stopPractice")
        }.fixedSize(horizontal: false, vertical: true)
    }
    private func runnerRhythm(_ lesson: Lesson) -> some View {
        let cue = RhythmJumpPresentation.cueStep(elapsed: practice.elapsed, pattern: lesson.pattern, bpm: lesson.bpm, bars: lesson.bars)
        let currentBeat = cue.map { ($0 % lesson.pattern.steps.count) / lesson.pattern.stepsPerBeat }
        return HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { beat in
                let strokes = Array(lesson.pattern.steps[(beat * lesson.pattern.stepsPerBeat)..<((beat + 1) * lesson.pattern.stepsPerBeat)])
                VStack(spacing: 4) {
                    Text("\(beat + 1)").font(.caption.monospacedDigit())
                    Text(strokes.map { $0 == .rest ? "—" : $0.rawValue }.joined(separator: " "))
                        .font(.system(.subheadline, design: .monospaced).bold())
                        .minimumScaleFactor(0.7).lineLimit(1)
                }.frame(maxWidth: .infinity, minHeight: 44).padding(.vertical, 4)
                    .foregroundStyle(currentBeat == beat ? Color.white : Color(red: 0.16, green: 0.28, blue: 0.22))
                    .background(currentBeat == beat ? Color(red: 0.24, green: 0.47, blue: 0.36) : Color(red: 0.86, green: 0.92, blue: 0.87), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("第 \(beat + 1) 拍，" + strokes.map { $0 == .rest ? "休止" : $0 == .right ? "右手" : "左手" }.joined(separator: "，"))
                    .accessibilityValue(currentBeat == beat ? "目前" : "")
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("rhythmLane")
    }
    private func jumpStage(_ lesson: Lesson) -> some View {
        runnerStage(lesson).frame(height: 178)
    }
    private func runnerStage(_ lesson: Lesson) -> some View {
        let position = RhythmRunnerPresentation.position(elapsed: practice.elapsed, bpm: lesson.bpm, stepsPerBeat: lesson.pattern.stepsPerBeat)
        let steps = RhythmRunnerPresentation.visibleSteps(position: position, pattern: lesson.pattern, bars: lesson.bars)
        return GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let ground = h * 0.78
            let stride = w * 0.25
            let playerX = w * 0.25
            let characterHeight = min(110, h * 0.52)
            let displayedHop = max(hopHeight, -(ground - characterHeight - 12))
            ZStack(alignment: .topLeading) {
                Image("RunnerIsland").resizable().frame(width: w, height: h)
                    .accessibilityHidden(true)
                Ellipse().fill(Color.white.opacity(0.5)).frame(width: 88, height: 16)
                    .position(x: playerX, y: ground + 6)
                ForEach(steps, id: \.self) { step in
                    let x = playerX + CGFloat(Double(step) - (reduceMotion ? floor(position) : position)) * stride
                    let cleared = jump.accepted.contains(step)
                    VStack(spacing: 3) {
                        if cleared {
                            Image(systemName: "star.fill").font(.title2)
                                .foregroundStyle(Color(red: 0.42, green: 0.28, blue: 0.02))
                        } else {
                            Text(lesson.pattern.steps[step % lesson.pattern.steps.count].rawValue)
                                .font(.caption.bold()).foregroundStyle(Color(red: 0.16, green: 0.28, blue: 0.22))
                            Image(systemName: "mountain.2.fill").font(.system(size: 32))
                                .foregroundStyle(x < playerX - stride * 0.6 ? Color(red: 0.65, green: 0.35, blue: 0.29) : Color(red: 0.39, green: 0.46, blue: 0.42))
                        }
                    }.position(x: x, y: ground - 23)
                }
                let finishX = playerX + CGFloat(Double(lesson.pattern.steps.count * lesson.bars) - (reduceMotion ? floor(position) : position)) * stride
                Image(systemName: "flag.checkered").font(.system(size: 38))
                    .foregroundStyle(Color(red: 0.16, green: 0.28, blue: 0.22)).position(x: finishX, y: ground - 38)
                Ellipse().fill(Color.black.opacity(0.15)).frame(width: 64, height: 12).position(x: playerX, y: ground + 5)
                if hopHeight < -20 && practice.latestHit?.grade == .perfect {
                    Image(systemName: "sparkles").font(.title).foregroundStyle(HomeBrand.heroInk)
                        .position(x: playerX + 48, y: ground - 72)
                }
                GameCompanion(companion: companion, celebrating: hopHeight < -20 && practice.latestHit?.grade == .perfect)
                    .frame(width: characterHeight * 0.93, height: characterHeight)
                    .position(x: playerX, y: ground - characterHeight / 2 + displayedHop)
            }.clipShape(RoundedRectangle(cornerRadius: 24))
        }.accessibilityElement(children: .contain)
    }
    private var recoveryStep: Int? {
        guard let lesson = practice.selected else { return nil }
        let position = RhythmRunnerPresentation.position(elapsed: practice.elapsed, bpm: lesson.bpm, stepsPerBeat: lesson.pattern.stepsPerBeat)
        return RhythmRewardPresentation.recoveryStep(position: position, bpm: lesson.bpm, pattern: lesson.pattern, bars: lesson.bars, accepted: jump.accepted)
    }
    private var crossingCount: some View {
        Text("跨過 \(jump.accepted.count) 個障礙 · 休止格先等一下")
            .font(.caption).foregroundStyle(BeatLabStyle.muted).accessibilityIdentifier("jumpMatches")
    }
    private var comboLabel: some View {
        Label(recoveryStep != nil ? "這拍沒跨過，再跟上！" : reward.perfectStreak > 1 ? "連續剛剛好 ×\(reward.perfectStreak)" : "跟上下一拍！", systemImage: "star.fill")
            .font(.caption.bold()).foregroundStyle(BeatLabStyle.accent)
            .accessibilityIdentifier("runnerCombo")
    }
    private var feedback: String {
        guard let hit = practice.latestHit else { return "點這裡跟拍" }
        switch hit.grade {
        case .early: return "早了一點"
        case .perfect: return "剛剛好！"
        case .late: return "晚了一點"
        case .extra: return "多打一下，再跟上"
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
                VStack(spacing: 20) {
                    if let lesson = practice.selected, !practice.isCalibrating {
                        Text("第 \(lessonNumber(lesson)) 關 · \(lesson.shortTitle)")
                            .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    }
                    if practice.isCalibrating {
                        Image(systemName: "ear.badge.checkmark").font(.system(size: 38))
                            .foregroundStyle(Color.accentColor).padding(24)
                            .background(BeatLabStyle.accentSoft, in: Circle()).accessibilityHidden(true)
                    } else {
                        if practice.isEggMission {
                            EggMissionScene(theme: missionTheme, elapsed: 20, accepted: practice.runnerRoute?.accepted ?? [], finishedPassed: practice.stars > 0, route: practice.runnerRoute, platformJourney: true)
                                .frame(height: textSize.isAccessibilitySize ? 280 : 220)
                        } else {
                            AdventureFinish(companion: companion, celebrating: practice.stars > 0).frame(height: 170)
                        }
                        if let selected = practice.selected, let index = practice.lessons.firstIndex(where: { $0.id == selected.id }),
                           practice.resultSaved && practice.stars > 0 && [1, 5, 9].contains(index) {
                            Label("\(worldNames[index == 1 ? 0 : index == 5 ? 1 : 2])徽章已點亮！", systemImage: "seal.fill")
                                .font(.headline).foregroundStyle(BeatLabStyle.reward)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text(resultTitle).font(.system(.title, design: .rounded).bold())
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("practiceSummary")
                        .accessibilityFocused($resultFocused).accessibilityAddTraits(.isHeader)
                    if !practice.isCalibrating {
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: index < practice.stars ? "star.fill" : "star")
                                    .font(.title).foregroundStyle(BeatLabStyle.reward)
                            }
                        }.accessibilityElement(children: .ignore).accessibilityLabel(practice.needsSaveRetry ? "這次 \(practice.stars) 顆星等待保存" : "這次得到 \(practice.stars) 顆星")
                            .accessibilityIdentifier("practiceStars")
                        Text(resultAdvice(summary)).foregroundStyle(BeatLabStyle.muted).multilineTextAlignment(.center)
                    }
                    Text("漏拍 \(summary.missedCount) 下 · 多打 \(summary.extraCount) 下")
                        .font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { scoreStats(summary) }
                        VStack(alignment: .leading, spacing: 12) { scoreStats(summary) }
                    }
                    if practice.needsSaveRetry {
                        BLStatusMessage(text: "成績尚未保存，星星與解鎖還沒更新。")
                        Button("重試保存") { practice.retrySave() }.buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("retryProgressSave")
                        Button("不保存，離開結果", role: .destructive) { confirmDiscard = true }.frame(minHeight: 44).accessibilityIdentifier("discardProgress")
                    } else if practice.isCalibrating {
                        Button("回到課程") {
                            if let lesson = practice.recommended { practice.select(lesson) }
                        }.buttonStyle(BLPrimaryButtonStyle())
                    } else if let lesson = practice.selected {
                        if let next = nextLesson, practice.resultSaved {
                            Button { openPreparation(next) } label: { Label("挑戰下一關", systemImage: "arrow.right") }
                                .buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("nextLesson")
                            Button("再練一次") { startLesson(lesson) }.buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("retryLesson")
                        } else {
                            Button { startLesson(lesson) } label: { Label("再挑戰一次", systemImage: "arrow.clockwise") }
                                .buttonStyle(BLPrimaryButtonStyle()).disabled(!practice.canPractice).accessibilityIdentifier("retryLesson")
                        }
                    }
                }
            }
            if practice.mode == .standard { technicalSummary(summary) }
            if !practice.needsSaveRetry {
                Button { if let lesson = practice.selected ?? practice.recommended { practice.select(lesson) }; showingJourney = true } label: { Label("回到關卡", systemImage: "map") }
                    .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("returnToJourney")
            }
        }
    }
    private var resultTitle: String {
        if practice.isCalibrating {
            if practice.needsSaveRetry { return "對齊算好了，等待保存" }
            return practice.calibrationSaved ? "對齊完成" : "對齊需要再試一次"
        }
        if practice.needsSaveRetry { return "星星等待保存" }
        if practice.isEggMission { return practice.stars > 0 ? missionTheme.passed : missionTheme.retry }
        if practice.stars > 0 && completed == practice.lessons.count { return "十關完成，節奏由你掌握" }
        return practice.stars > 0 ? "跑到終點，挑戰成功！" : "還沒通過，再跑一次！"
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
        metric("剛剛好", "\(summary.matched.filter { $0.grade == .perfect }.count)/\(summary.targetCount)")
    }
    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title2, design: .rounded).bold()).monospacedDigit()
            Text(title).font(.subheadline).foregroundStyle(BeatLabStyle.muted)
        }.frame(maxWidth: .infinity).padding(14)
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
                Button("開始對齊練習") { showSettings = false; showingJourney = false; practice.startCalibration(audio: audio) }
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
            openPreparation(lesson); showLessons = false
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

// Art reacts to practice state but never owns targets, input or time.
private enum AdventureCompanion: String, CaseIterable {
    case cat, robot, dinosaur
    var title: String { self == .cat ? "貓咪" : self == .robot ? "機器人" : "恐龍" }
    var artwork: String { self == .cat ? "AdventureCat" : self == .robot ? "AdventureRobot" : "AdventureDinosaur" }
    var invitation: String {
        switch self {
        case .cat: return "伸出小肉球，一起找到大拍。"
        case .robot: return "節奏任務啟動！一起把每一下打穩。"
        case .dinosaur: return "踏出咚咚腳步，探索新的節奏。"
        }
    }
}

private struct GameCompanion: View {
    let companion: AdventureCompanion
    var celebrating = false
    var resultScene = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(companion == .dinosaur ? "HomeDinosaur" : companion.artwork)
                .resizable().scaledToFit()
            if celebrating && companion == .cat {
                Image("AdventureCatCelebration").resizable().scaledToFit()
                    .frame(maxWidth: resultScene ? 60 : 32).rotationEffect(.degrees(12))
            } else if celebrating && companion == .robot {
                Image(systemName: "sparkles").font(resultScene ? .title : .caption).foregroundStyle(BeatLabStyle.reward)
            }
        }.scaleEffect(celebrating && !reduceMotion ? 1.05 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: celebrating)
            .accessibilityHidden(true).allowsHitTesting(false)
    }
}

private struct AdventureTrail: Shape {
    var reversed = false
    func path(in rect: CGRect) -> Path {
        Path { path in
            let start = reversed ? rect.width * 0.75 : rect.width * 0.25
            let end = reversed ? rect.width * 0.25 : rect.width * 0.75
            path.move(to: CGPoint(x: start, y: 0))
            path.addCurve(to: CGPoint(x: end, y: rect.height),
                          control1: CGPoint(x: start, y: rect.height * 0.7),
                          control2: CGPoint(x: end, y: rect.height * 0.3))
        }
    }
}

private struct AdventureScene: View {
    let world: Int
    let companion: AdventureCompanion
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            ZStack {
                (world == 0 ? BeatLabStyle.accentSoft : world == 1 ? BeatLabStyle.successSoft : BeatLabStyle.rewardSoft)
                Circle().fill(Color(red: 1, green: 0.78, blue: 0.36)).frame(width: 50, height: 50).position(x: w * 0.78, y: 36)
                Ellipse().fill(Color.white.opacity(0.65)).frame(width: 80, height: 22).position(x: w * 0.21, y: 28)
                Ellipse().fill(Color.white.opacity(0.4)).frame(width: 60, height: 18).position(x: w * 0.59, y: 16)
                Ellipse().fill(Color.accentColor.opacity(0.13)).frame(width: w * 1.25, height: 110).position(x: w * 0.26, y: 128)
                Ellipse().fill(Color.accentColor.opacity(0.22)).frame(width: w * 0.85, height: 74).position(x: w * 0.83, y: 138)
                if world == 1 {
                    ForEach(0..<3, id: \.self) { index in
                        VStack(spacing: -6) {
                            Image(systemName: "tree.fill").font(.system(size: CGFloat(48 + index * 10))).foregroundStyle(BeatLabStyle.success)
                            Capsule().fill(BeatLabStyle.success).frame(width: 5, height: 14)
                        }.position(x: w * (0.16 + Double(index) * 0.32), y: 74)
                    }
                } else if world == 2 {
                    RoundedRectangle(cornerRadius: 12).fill(Color.accentColor).frame(width: w * 0.65, height: 20).position(x: w * 0.5, y: 115)
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "sparkle").font(.system(size: CGFloat(20 + index * 6))).foregroundStyle(Color.accentColor)
                            .position(x: w * (0.18 + Double(index) * 0.32), y: index == 1 ? 24 : 55)
                    }
                } else {
                    Image(systemName: "flag.fill").font(.system(size: 46)).foregroundStyle(Color.accentColor).position(x: w * 0.23, y: 77)
                    Image(systemName: "music.note").font(.system(size: 25)).foregroundStyle(Color.accentColor).rotationEffect(.degrees(15)).position(x: w * 0.67, y: 70)
                }
                GameCompanion(companion: companion).frame(width: 84, height: 94).position(x: w * 0.48, y: 84)
            }
        }.accessibilityHidden(true).allowsHitTesting(false)
    }
}

private struct AdventureFinish: View {
    let companion: AdventureCompanion
    let celebrating: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var body: some View {
        ZStack {
            Circle().fill(celebrating ? BeatLabStyle.rewardSoft : BeatLabStyle.accentSoft).frame(width: 154, height: 154)
            if celebrating {
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: index % 2 == 0 ? "star.fill" : "sparkle")
                        .font(.system(size: index % 2 == 0 ? 14 : 10)).foregroundStyle(index % 2 == 0 ? BeatLabStyle.reward : Color.accentColor)
                        .offset(x: CGFloat(cos(Double(index) * .pi / 4)) * 90,
                                y: CGFloat(sin(Double(index) * .pi / 4)) * 68)
                }
            }
            GameCompanion(companion: companion, celebrating: celebrating, resultScene: true).frame(width: 160, height: 150)
        }.frame(maxWidth: .infinity).scaleEffect(appeared || reduceMotion ? 1 : 0.9)
            .onAppear {
                if reduceMotion { appeared = true }
                else { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appeared = true } }
            }.accessibilityHidden(true).allowsHitTesting(false)
    }
}

/// Transient rendering of already-judged hits; never owns musical targets or stars.
struct RhythmJumpPresentation {
    private(set) var accepted: Set<Int> = []
    private(set) var landedStep = -1
    mutating func record(_ hit: TimingHit, pattern: RhythmPattern, bars: Int) -> Bool {
        guard hit.grade != .extra, let id = hit.targetID, id >= 0,
              id < pattern.steps.count * bars, !pattern.steps.isEmpty,
              pattern.steps[id % pattern.steps.count] != .rest,
              accepted.insert(id).inserted else { return false }
        landedStep = max(landedStep, id)
        return true
    }
    static func cueStep(elapsed: Double, pattern: RhythmPattern, bpm: Int, bars: Int) -> Int? {
        guard elapsed.isFinite, bpm > 0, pattern.stepsPerBeat > 0, !pattern.steps.isEmpty, bars > 0 else { return nil }
        let position = (elapsed - 4 * 60 / Double(bpm)) * Double(bpm * pattern.stepsPerBeat) / 60
        guard position >= 0 else { return nil }
        return min(pattern.steps.count * bars - 1, Int(position))
    }
    func displayStep(cue: Int?) -> Int {
        // Camera/safety catch follows the next cue; unlit tiles earn nothing.
        max(landedStep, (cue ?? 0) - 1)
    }
}

/// Cosmetic feedback derived from accepted hits. Does not change grades or progress.
struct RhythmRewardPresentation {
    private(set) var perfectStreak = 0
    // A conservative display deadline covers the existing matching window and
    // maximum permitted calibration offset; this is never a score decision.
    static func recoveryStep(position: Double, bpm: Int, pattern: RhythmPattern, bars: Int, accepted: Set<Int>) -> Int? {
        guard position.isFinite, bpm > 0, pattern.stepsPerBeat > 0,
              !pattern.steps.isEmpty, bars > 0 else { return nil }
        let total = pattern.steps.count * bars
        guard position >= 0, position < Double(total + 5) else { return nil }
        let deadline = position - (TimingSession.matchingWindow + 0.250) * Double(bpm * pattern.stepsPerBeat) / 60
        guard deadline > 0 else { return nil }
        let end = min(total - 1, Int(ceil(deadline)) - 1)
        guard let step = (0...end).last(where: { pattern.steps[$0 % pattern.steps.count] != .rest }),
              !accepted.contains(step) else { return nil }
        return step
    }
    private var lastTarget: Int?
    mutating func record(_ hit: TimingHit, accepted: Bool, pattern: RhythmPattern) {
        guard accepted, hit.grade == .perfect, let id = hit.targetID,
              !pattern.steps.isEmpty, id >= 0 else {
            perfectStreak = 0; lastTarget = nil; return
        }
        let previous = (0..<id).last { pattern.steps[$0 % pattern.steps.count] != .rest }
        perfectStreak = lastTarget == previous ? perfectStreak + 1 : 1
        lastTarget = id
    }
}

/// Camera geometry only: all target IDs and judgments belong to TimingSession.
struct RhythmRunnerPresentation {
    static func position(elapsed: Double, bpm: Int, stepsPerBeat: Int) -> Double {
        guard elapsed.isFinite, bpm > 0, stepsPerBeat > 0 else { return -4 }
        return (elapsed - 4 * 60 / Double(bpm)) * Double(bpm * stepsPerBeat) / 60
    }
    static func visibleSteps(position: Double, pattern: RhythmPattern, bars: Int) -> [Int] {
        guard position.isFinite, !pattern.steps.isEmpty, bars > 0 else { return [] }
        let total = pattern.steps.count * bars
        guard position >= -5, position < Double(total + 5) else { return [] }
        let lower = max(0, Int(floor(position)) - 1)
        let upper = min(total, max(0, Int(floor(position)) + 5))
        guard lower < upper else { return [] }
        return (lower..<upper).filter { pattern.steps[$0 % pattern.steps.count] != .rest }
    }
}
