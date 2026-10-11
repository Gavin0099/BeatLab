import SwiftUI
import SpriteKit
import BeatLabCore

/// The native trial uses the same audio transport, matcher and UIKit timestamps.
struct DrummerStageView: View {
    @EnvironmentObject private var practice: PracticeStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var scene = DrummerRhythmScene(size: CGSize(width: 340, height: 450))
    private var cue: String {
        if practice.phase == .paused { return "已暫停" }
        if practice.isResuming { return "先聽 \(practice.resumeCountdown ?? 4) 拍" }
        if practice.elapsed < 4 { return "先聽 \(max(1,4-Int(practice.elapsed))) 拍" }
        let snapshot = practice.gameSnapshot
        if let target = snapshot?.targets.last(where: { snapshot?.missed(at: practice.elapsed).contains($0.id) == true }),
           target.time + (snapshot?.alignment ?? 0) + TimingSession.matchingWindow > (practice.latestHit?.inputTime ?? 0) { return "漏拍 · 接下一拍" }
        switch practice.latestHit?.grade {
        case .perfect: return "Perfect"
        case .early: return "早了一點"
        case .late: return "晚了一點"
        case .extra: return "多按一下"
        case nil: return "到鼓面就敲"
        }
    }
    var body: some View {
        VStack(spacing: 8) {
        if textSize.isAccessibilitySize {
            Text(cue).font(.subheadline.bold()).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
                .foregroundStyle(BeatLabStyle.ink).accessibilityIdentifier("jumpCue")
        }
        ZStack(alignment: .bottom) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("恐龍鼓手舞台；音符沿左、右軌道抵達固定鼓面時敲擊")
                .accessibilityIdentifier("drummerPlayfield")
            if !textSize.isAccessibilitySize {
            Text(cue).font(.caption.bold()).multilineTextAlignment(.center)
                .frame(width: 106, height: 44).padding(.bottom, 106)
                .foregroundStyle(BeatLabStyle.ink).allowsHitTesting(false)
                .accessibilityIdentifier("jumpCue")
            }
            HStack(spacing: 0) {
                pad(.left)
                pad(.right)
            }.frame(height: 104)
        }
        .background(BeatLabStyle.canvas)
        }
        .accessibilityElement(children: .contain).accessibilityIdentifier("rhythmGameStage")
        .onAppear { configure() }
        .onChange(of: reduced) { _ in configure() }
        .onChange(of: textSize) { _ in configure() }
    }
    private func pad(_ stroke: Stroke) -> some View {
        TapPad(feedback: cue, label: stroke == .left ? "左手 L 鼓面" : "右手 R 鼓面",
               identifier: stroke == .left ? "practiceTapPad.left" : "practiceTapPad.right") { time, accessible in
            practice.tap(at: time, accessibility: accessible, stroke: stroke)
        }.frame(maxWidth: .infinity).disabled(practice.phase == .paused)
    }
    private func configure() {
        scene.scaleMode = .resizeFill
        scene.reduced = reduced; scene.showActor = !textSize.isAccessibilitySize
        scene.snapshot = { [weak practice] in practice?.gameSnapshot }
        scene.elapsed = { [weak practice] in practice?.presentationElapsed(at: PracticeStore.now()) ?? 0 }
        scene.pressedStroke = { [weak practice] in practice?.pressedStroke }
    }
}

/// Prototype-only HUD: tempo is supporting information, not the visual focus.
struct DrummerHUD: View {
    let lesson: Lesson
    let snapshot: RhythmGameSnapshot?
    let elapsed: Double
    let pause: () -> Void
    let exit: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(textSize.isAccessibilitySize ? "第 3 關" : "第 3 關 · 鼓手舞台")
                    .font(.headline).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("activeLessonNumber")
                Spacer(minLength: 0)
                Button(action: pause) { Image(systemName: "pause.fill").frame(width: 44, height: 44) }
                    .accessibilityLabel("暫停").accessibilityIdentifier("pausePractice")
                Button(action: exit) { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel("退出").accessibilityIdentifier("stopPractice")
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(textSize.isAccessibilitySize ? "\(snapshot?.accepted.count ?? 0) / \(snapshot?.targets.count ?? 0)" : "命中 \(snapshot?.accepted.count ?? 0) / \(snapshot?.targets.count ?? 0)")
                    .font(textSize.isAccessibilitySize ? .headline : .caption.bold()).monospacedDigit()
                    .accessibilityLabel("命中 \(snapshot?.accepted.count ?? 0) / \(snapshot?.targets.count ?? 0)")
                    .accessibilityValue("精準連擊 \(snapshot?.perfectStreak(at: elapsed) ?? 0)")
                    .accessibilityIdentifier("jumpMatches")
                Spacer(minLength: 0)
                Text("\(lesson.bpm) BPM").font(.caption).monospacedDigit().fixedSize()
            }
            ProgressView(value: min(1,max(0,elapsed/max(snapshot?.duration ?? 1,1))))
                .tint(BeatLabStyle.accent).accessibilityLabel("練習進度")
        }.foregroundStyle(BeatLabStyle.ink)
    }
}
