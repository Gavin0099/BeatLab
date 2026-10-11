import SwiftUI
import SpriteKit
import BeatLabCore

struct PracticeComparisonView: View {
    let theme: RunnerTheme
    let exit: () -> Void
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var appPhase
    @State private var falling = FallingRhythmScene(size: CGSize(width: 340, height: 300))
    @State private var runner = RunnerRhythmScene(size: CGSize(width: 340, height: 180))
    @State private var pressed: Stroke?
    @State private var releaseTask: Task<Void, Never>?
    private var scene: FallingRhythmScene { practice.presentation == .falling ? falling : runner }
    private var feedback: String {
        if practice.phase == .paused { return "休息一下，準備好再繼續" }
        if practice.isResuming, let count = practice.resumeCountdown { return "先聽 \(count) 拍，準備接回來" }
        if let lesson = practice.selected, practice.elapsed < 4 * 60 / Double(lesson.bpm), !practice.isResuming {
            return "先聽 \(min(4,max(1,4-Int(practice.elapsed * Double(lesson.bpm)/60)))) 拍，準備敲"
        }
        if let snapshot = practice.gameSnapshot,
           let missedTarget = snapshot.targets.last(where: { snapshot.missed(at: practice.elapsed).contains($0.id) }),
           missedTarget.time + snapshot.alignment + TimingSession.matchingWindow > (practice.latestHit?.inputTime ?? 0) {
            return "漏了一拍，接著下一拍"
        }
        if let hit = practice.latestHit {
            return hit.grade == .perfect ? "Perfect · 剛剛好！" : hit.grade == .early ? "早了一點，再跟上" : hit.grade == .late ? "晚了一點，再跟上" : "多打一下，聽下一拍"
        }
        if let snapshot = practice.gameSnapshot, !snapshot.missed(at: practice.elapsed).isEmpty { return "漏了一拍，接著下一拍" }
        return "音符到黃線，就敲一下"
    }
    var body: some View {
        GeometryReader { geometry in
            if let lesson = practice.selected {
                VStack(spacing: 10) {
                    GameHUD(lesson: lesson, number: (practice.lessons.firstIndex { $0.id == lesson.id } ?? 0) + 1,
                            snapshot: practice.gameSnapshot, elapsed: practice.elapsed, comparison: practice.isComparison,
                            pause: { practice.pause(audio: audio) }, exit: exit)
                    stage.frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityIdentifier("rhythmGameStage")
                    Text(feedback).font(textSize.isAccessibilitySize ? .subheadline.bold() : .headline)
                        .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("jumpCue")
                    HStack(spacing: 12) { pad(.left, lesson: lesson); pad(.right, lesson: lesson) }
                        .frame(height: textSize.isAccessibilitySize ? 116 : 92)
                }.padding(.horizontal, 16).padding(.vertical, 8)
                    .frame(maxWidth: 760).frame(maxWidth: .infinity)
                    .background(BeatLabStyle.canvas)
                    .overlay { if practice.phase == .paused { pausePanel } }
            }
        }
        .onAppear { configureScene() }
        .onChange(of: practice.presentation) { _ in configureScene() }
        .onChange(of: reduceMotion) { _ in configureScene() }
        .onChange(of: practice.pressSerial) { _ in
            pressed = practice.pressedStroke; releaseTask?.cancel()
            releaseTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { return }; pressed = nil
            }
        }
        .onChange(of: audio.status) { message in
            if practice.phase == .paused, message != nil { practice.cancel(audio: audio, message: "音訊已變更，請重新開始。") }
        }
        .onChange(of: appPhase) { value in
            if value != .active, practice.isActive { practice.cancel(audio: audio, message: "練習已停止，請重新開始。") }
        }
        .onDisappear { releaseTask?.cancel() }
    }
    private func configureScene() {
        for scene in [falling, runner] {
            scene.scaleMode = .resizeFill; scene.reduced = reduceMotion
            scene.snapshot = { [weak practice] in practice?.gameSnapshot }
            scene.elapsed = { [weak practice] in practice?.presentationElapsed(at: PracticeStore.now()) ?? 0 }
        }
    }
    private var stage: some View {
        GeometryReader { g in
            VStack(spacing: 0) {
                EggMissionScene(theme: theme, elapsed: practice.elapsed, accepted: practice.gameSnapshot?.accepted ?? [],
                                presentationElapsed: { practice.presentationElapsed(at: $0) },
                                acceptedAction: practice.gameRoute?.latestAccepted, latestAction: practice.latestHit,
                                route: practice.gameRoute, platformJourney: true)
                    .frame(height: 220)
                    .scaleEffect(min(1, max(0.4, g.size.height * (practice.presentation == .falling ? 0.36 : 0.62) / 220)))
                    .frame(height: g.size.height * (practice.presentation == .falling ? 0.36 : 0.62))
                    .clipped().accessibilityIdentifier("eggMissionScene")
                SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
                    .background(BeatLabStyle.accentSoft.opacity(0.6))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(practice.presentation == .falling ? "左、右節奏軌道，音符到固定黃線時敲擊" : "音符由右接近，抵達黃線時敲擊")
                    .accessibilityIdentifier("rhythmPlayfield")
            }.clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(alignment: .topLeading) {
                    Text(practice.presentation.title).font(.caption.bold()).padding(8)
                        .background(BeatLabStyle.rewardSoft, in: Capsule()).padding(8)
                }
        }
    }
    private func pad(_ stroke: Stroke, lesson: Lesson) -> some View {
        let both = lesson.pattern.steps.contains(.left)
        let identifier = stroke == .left ? "practiceTapPad.left" : both ? "practiceTapPad.right" : "practiceTapPad"
        return ZStack {
            RoundedRectangle(cornerRadius: 24).fill(stroke == .left ? BeatLabStyle.rewardSoft : BeatLabStyle.reward)
            RoundedRectangle(cornerRadius: 24).stroke(pressed == stroke ? BeatLabStyle.accent : .clear, lineWidth: 4)
            VStack(spacing: 2) {
                Text(stroke == .left ? "左手" : "右手").font(.headline)
                Text(stroke == .left ? "L" : "R").font(.system(.title2, design: .rounded).bold())
            }.foregroundStyle(BeatLabStyle.ink).allowsHitTesting(false).accessibilityHidden(true)
            TapPad(feedback: feedback, label: stroke == .left ? "左手 L 跟拍區" : "右手 R 跟拍區", identifier: identifier) { time, accessibility in
                practice.tap(at: time, accessibility: accessibility, stroke: stroke)
            }
        }.frame(maxWidth: .infinity).opacity(practice.phase == .paused ? 0.4 : 1)
    }
    private var pausePanel: some View {
        ZStack {
            BeatLabStyle.canvas.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("休息一下").font(.title.bold())
                Text("已打過的拍點會保留。先聽四拍，再接著敲。").multilineTextAlignment(.center)
                Button("繼續", action: { practice.resume(audio: audio) }).buttonStyle(BLPrimaryButtonStyle()).accessibilityIdentifier("resumePractice")
                Button("重新開始") {
                    guard let lesson = practice.selected else { return }
                    let comparison = practice.isComparison, variant = practice.presentation
                    practice.cancel(audio: audio)
                    #if DEBUG
                    if comparison { practice.startComparison(lesson, presentation: variant, audio: audio); return }
                    #endif
                    practice.start(lesson, audio: audio, eggMission: true)
                }.buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("restartPractice")
                Button("退出", action: exit).frame(minHeight: 44).accessibilityIdentifier("exitPausedPractice")
            }.padding(24).frame(maxWidth: 480)
        }.accessibilityIdentifier("practicePaused")
    }
}
