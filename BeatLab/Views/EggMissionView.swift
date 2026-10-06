import SwiftUI
import UIKit
import BeatLabCore

enum EggPose: Int { case runA, runB, ready, jump, catchEgg, celebrate, egg, nest, rock }

/// Crop and decode existing source regions once, never from the frame callback.
/// Character frames share source scale and a registered foot baseline.
private enum EggSpriteAssets {
    static let bounds: [CGRect] = [
        CGRect(x: 21, y: 17, width: 393, height: 452),
        CGRect(x: 450, y: 32, width: 387, height: 440),
        CGRect(x: 883, y: 90, width: 358, height: 365),
        CGRect(x: 26, y: 482, width: 401, height: 398),
        CGRect(x: 464, y: 525, width: 390, height: 383),
        CGRect(x: 894, y: 491, width: 345, height: 417),
        CGRect(x: 113, y: 954, width: 212, height: 258),
        CGRect(x: 435, y: 968, width: 397, height: 248),
        CGRect(x: 877, y: 950, width: 351, height: 260)
    ]
    static let images: [Image] = {
        let atlas = UIImage(named: "EggMissionAtlas")?.cgImage
        return bounds.map { region in
            guard let cell = atlas?.cropping(to: region) else { return Image("EggMissionAtlas") }
            return Image(decorative: cell, scale: 1, orientation: .up)
        }
    }()
}

struct EggSprite: View {
    let pose: EggPose
    var body: some View {
        Canvas { context, size in
            let source = EggSpriteAssets.bounds[pose.rawValue].size
            let scale = min(size.width / source.width, size.height / source.height)
            let rect = CGRect(x: (size.width - source.width * scale) / 2,
                              y: (size.height - source.height * scale) / 2,
                              width: source.width * scale, height: source.height * scale)
            context.draw(EggSpriteAssets.images[pose.rawValue], in: rect)
        }.accessibilityHidden(true)
    }
}

/// Cosmetic state only. Targets, matching, score and saving remain in BeatLabCore.
enum EggMissionPresentation {
    static func pose(elapsed: Double, hitAge: Double?, grade: TimingGrade?, recovering: Bool, reduceMotion: Bool) -> EggPose {
        guard elapsed.isFinite, elapsed >= 0, elapsed < 1000 else { return .ready }
        if let hitAge, (0..<0.48).contains(hitAge), let grade { return grade == .extra ? .ready : .jump }
        if recovering { return .catchEgg }
        if elapsed < 4 || reduceMotion { return .ready }
        return Int(elapsed * 5) % 2 == 0 ? .runA : .runB
    }
    static func hop(hitAge: Double?, grade: TimingGrade?, reduceMotion: Bool) -> CGFloat {
        guard !reduceMotion, let age = hitAge, (0..<0.48).contains(age), let grade else { return 0 }
        return CGFloat(sin(.pi * age / 0.48)) * (grade == .extra ? 12 : 74)
    }
    static func missed(elapsed: Double, accepted: Set<Int>) -> Int? {
        guard elapsed.isFinite else { return nil }
        // Existing matcher .180 + maximum alignment .250; never flag an open target.
        let expired = elapsed - 4 - (TimingSession.matchingWindow + 0.250)
        guard expired >= 0, expired < 16 else { return nil }
        let id = Int(floor(expired))
        return (0..<16).contains(id) && !accepted.contains(id) && expired - Double(id) < 0.48 ? id : nil
    }
}

/// Finite follow-through, purely visual. No animation queues or collision score.
struct EggMotion {
    let height: CGFloat
    let scaleX: CGFloat
    let scaleY: CGFloat
    let angle: Double
    let landing: CGFloat
    let backgroundX: CGFloat

    static func sample(elapsed: Double, age: Double?, grade: TimingGrade?, reduceMotion: Bool) -> EggMotion {
        let time = elapsed.isFinite ? min(20.18, max(0, elapsed)) : 0
        let validAge = age.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let airborne = validAge.map { $0 < 0.48 && grade != nil } ?? false
        let landing = validAge.map { (0.48..<0.64).contains($0) && grade != nil ? sin(.pi * ($0 - 0.48) / 0.16) : 0 } ?? 0
        let p = airborne ? validAge! / 0.48 : 0
        return EggMotion(height: reduceMotion ? 0 : CGFloat(sin(.pi * p)) * (grade == .extra ? 12 : 74),
                         scaleX: reduceMotion ? 1 : 1 + CGFloat(landing) * 0.10,
                         scaleY: reduceMotion ? 1 : 1 - CGFloat(landing) * 0.12,
                         angle: reduceMotion ? 0 : -0.12 * sin(.pi * p),
                         landing: reduceMotion ? 0 : CGFloat(landing),
                         backgroundX: reduceMotion ? -12 : -CGFloat(min(16, max(0, time - 4))) * 1.5)
    }
    static func action(accepted: TimingHit?, latest: TimingHit?, hostTime: Double) -> TimingHit? {
        if let accepted, hostTime.isFinite, hostTime >= accepted.inputTime {
            if hostTime - accepted.inputTime < 0.64 { return accepted }
            // A press during flight already got text/audio feedback. Do not
            // replay its old extra bounce when the accepted landing finishes.
            if let latest, latest.grade == .extra,
               latest.inputTime < accepted.inputTime + 0.64 { return nil }
        }
        return latest
    }
}

struct EggMissionScene: View {
    var elapsed: Double
    var accepted: Set<Int> = []
    var latestGrade: TimingGrade?
    var hitAge: Double?
    var finishedPassed: Bool? = nil
    var preparing = false
    var presentationElapsed: ((Double) -> Double)? = nil
    var acceptedAction: TimingHit? = nil
    var latestAction: TimingHit? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let ink = Color(red: 0.08, green: 0.25, blue: 0.18)

    var body: some View {
        ZStack(alignment: .top) {
            // A display schedule only: all sound/targets/grades remain elsewhere.
            TimelineView(.animation(minimumInterval: 1.0 / 60,
                                    paused: reduceMotion || preparing || finishedPassed != nil || presentationElapsed == nil)) { _ in
                let hostTime = PracticeStore.now()
                let action = EggMotion.action(accepted: acceptedAction, latest: latestAction, hostTime: hostTime)
                let displayTime = presentationElapsed?(hostTime) ?? elapsed
                let displayAge = action.map { max(0, hostTime - $0.inputTime) } ?? hitAge
                EggSceneCanvas(elapsed: displayTime, accepted: accepted,
                               grade: action?.grade ?? latestGrade, hitAge: displayAge,
                               finishedPassed: finishedPassed, preparing: preparing, reduceMotion: reduceMotion)
            }
            HStack(spacing: 6) {
                EggSprite(pose: .egg).frame(width: 22, height: 30)
                Text(preparing ? "把蛋帶回家" : finishedPassed == nil ? "前往溫暖的巢" : "蛋安全接住了")
                    .font(.system(.subheadline, design: .rounded).bold())
                Spacer(minLength: 4)
                EggSprite(pose: .nest).frame(width: 38, height: 30)
            }.padding(10).background(Color(red: 1, green: 0.98, blue: 0.88), in: Capsule())
                .padding(12).foregroundStyle(ink)
        }.clipShape(RoundedRectangle(cornerRadius: 26))
            .accessibilityElement(children: .ignore).accessibilityLabel("恐龍送蛋回巢")
            .accessibilityValue(finishedPassed.map { $0 ? "任務通過" : "需要再試一次" } ?? "已跨過 \(accepted.count) 個障礙")
            .accessibilityIdentifier("eggMissionScene")
    }
}

private struct EggSceneCanvas: View {
    let elapsed: Double
    let accepted: Set<Int>
    let grade: TimingGrade?
    let hitAge: Double?
    let finishedPassed: Bool?
    let preparing: Bool
    let reduceMotion: Bool

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let ground = h * 0.86, playerX = w * 0.27, stride = w * 0.31
            let position = max(-4, elapsed - 4)
            let moving = reduceMotion ? floor(position) : position
            let recovering = EggMissionPresentation.missed(elapsed: elapsed, accepted: accepted) != nil
            let pose = finishedPassed.map { $0 ? EggPose.celebrate : .catchEgg }
                ?? (preparing ? .ready : EggMissionPresentation.pose(elapsed: elapsed, hitAge: hitAge, grade: grade, recovering: recovering, reduceMotion: reduceMotion))
            let motion = EggMotion.sample(elapsed: elapsed, age: preparing || finishedPassed != nil ? nil : hitAge,
                                          grade: grade, reduceMotion: reduceMotion)
            let hop = min(motion.height, h * 0.25)
            let characterSize = min(180, max(118, h * 0.42))
            context.draw(Image("RunnerIsland"), in: CGRect(x: motion.backgroundX, y: 0, width: w + 24, height: h))
            context.fill(Path(CGRect(x: 0, y: ground - 6, width: w, height: 12)), with: .color(Color(red: 0.65, green: 0.82, blue: 0.45)))
            context.fill(Path(CGRect(x: 0, y: ground + 6, width: w, height: h - ground)), with: .color(Color(red: 0.87, green: 0.69, blue: 0.42)))
            // Wrapped details disappear beyond the edge; no visible loop reset.
            let offset = preparing || finishedPassed != nil || reduceMotion ? 0 : CGFloat(max(0, position)) * stride
            for i in -2..<8 {
                let period = w + 180
                let raw = CGFloat(i) * 90 - offset
                let x = (raw.truncatingRemainder(dividingBy: period) + period).truncatingRemainder(dividingBy: period) - 90
                let rect = CGRect(x: x, y: ground + 24 + CGFloat(abs(i) % 3) * 7, width: 14, height: 5)
                context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.78, green: 0.58, blue: 0.34)))
            }
            if !preparing && finishedPassed == nil {
                for id in 0..<16 {
                    let x = playerX + CGFloat(Double(id) - moving) * stride
                    guard x > -70 && x < w + 70 else { continue }
                    if accepted.contains(id) {
                        context.draw(Text("✦").font(.title).foregroundColor(Color(red: 0.95, green: 0.64, blue: 0.07)), at: CGPoint(x: x, y: ground - 30))
                    } else { draw(.rock, in: &context, x: x, foot: ground + 5, size: 54) }
                }
            }
            let nestX = preparing || finishedPassed != nil ? w * 0.76 : playerX + CGFloat(16 - moving) * stride
            if nestX < w + 100 { draw(.nest, in: &context, x: nestX, foot: ground + 7, size: 70) }
            let shadowWidth = 82 * (1 - hop / 180)
            context.fill(Path(ellipseIn: CGRect(x: playerX - shadowWidth / 2, y: ground, width: shadowWidth, height: 10)),
                         with: .color(Color(red: 0.08, green: 0.25, blue: 0.18).opacity(0.18 - Double(hop / 74) * 0.07)))
            let bob: CGFloat = !reduceMotion && !preparing && finishedPassed == nil && elapsed >= 4 && hop == 0 && !recovering
                ? CGFloat(sin(elapsed * .pi * 10)) * 2 : 0
            var player = context
            player.translateBy(x: playerX, y: ground + 5 - hop - bob)
            player.rotate(by: .radians(motion.angle))
            player.scaleBy(x: motion.scaleX, y: motion.scaleY)
            if !reduceMotion, !preparing, finishedPassed == nil, let age = hitAge,
               (0.48..<0.64).contains(age), grade != nil {
                let blend = (age - 0.48) / 0.16
                var previous = player; previous.opacity = 1 - blend
                draw(grade == .extra ? .ready : .jump, in: &previous, x: 0, foot: 0, size: characterSize)
                player.opacity = blend
                draw(pose, in: &player, x: 0, foot: 0, size: characterSize)
            } else if !reduceMotion, pose == .runA || pose == .runB {
                let fraction = (elapsed * 5).truncatingRemainder(dividingBy: 1)
                let blend = min(1, max(0, (fraction - 0.75) / 0.25))
                var current = player; current.opacity = 1 - blend
                draw(pose, in: &current, x: 0, foot: 0, size: characterSize)
                player.opacity = blend
                draw(pose == .runA ? .runB : .runA, in: &player, x: 0, foot: 0, size: characterSize)
            } else { draw(pose, in: &player, x: 0, foot: 0, size: characterSize) }
            if motion.landing > 0 {
                for i in 0..<3 {
                    let rect = CGRect(x: playerX - 30 - CGFloat(i) * 15, y: ground - CGFloat(i) * 3,
                                      width: 12 + motion.landing * 8, height: 7)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.95, green: 0.83, blue: 0.60).opacity(Double(motion.landing) * 0.7)))
                }
            }
            if grade == .perfect, let age = hitAge, (0..<0.48).contains(age), !preparing, finishedPassed == nil {
                context.draw(Text("✦").font(.largeTitle).foregroundColor(Color(red: 0.97, green: 0.67, blue: 0.07)),
                             at: CGPoint(x: playerX + 54, y: ground - characterSize - hop + 24))
            }
        }.clipped().accessibilityHidden(true)
    }
    private func draw(_ pose: EggPose, in context: inout GraphicsContext, x: CGFloat, foot: CGFloat, size: CGFloat) {
        let source = EggSpriteAssets.bounds[pose.rawValue].size
        let scale = pose.rawValue < 6 ? size / 452 : size / source.height
        context.draw(EggSpriteAssets.images[pose.rawValue], in: CGRect(x: x - source.width * scale / 2, y: foot - source.height * scale,
                                                                     width: source.width * scale, height: source.height * scale))
    }
}

struct EggMissionView: View {
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @Environment(\.dynamicTypeSize) private var textSize
    let accepted: Set<Int>
    let streak: Int
    let stop: () -> Void
    @State private var acceptedAction: TimingHit?
    private let ink = Color(red: 0.08, green: 0.25, blue: 0.18)
    private var age: Double? { practice.latestHit.map { max(0, PracticeStore.now() - $0.inputTime) } }
    private var cue: String {
        if practice.elapsed < 4 { return "先聽 \(max(1, 4 - Int(practice.elapsed))) 拍，準備跳" }
        if let age, age < 0.48, let grade = practice.latestHit?.grade {
            switch grade {
            case .perfect: return "漂亮！蛋亮起來了"
            case .early: return "跳過了，下一拍稍等一下"
            case .late: return "跳過了，下一拍早一點"
            case .extra: return "多打一下，再跟上"
            }
        }
        return EggMissionPresentation.missed(elapsed: practice.elapsed, accepted: accepted) == nil ? "石頭到腳下，跟鼓聲跳！" : "接住了！下一拍再跳"
    }
    var body: some View {
        GeometryReader { geometry in
            ViewThatFits(in: .vertical) {
                content(sceneHeight: max(160, geometry.size.height - 330))
                ScrollView { content(sceneHeight: 280) }
            }.padding(.horizontal, 16).padding(.vertical, 8)
                .frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
        }.onChange(of: practice.latestHit) { hit in
            if let hit, hit.targetID != nil { acceptedAction = hit }
        }
    }
    private func content(sceneHeight: CGFloat) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("第 1 關 · 節奏跑酷").font(.headline).accessibilityIdentifier("activeLessonNumber")
                    Text("恐龍陪你跟拍").font(.caption).foregroundStyle(BeatLabStyle.muted).accessibilityIdentifier("activeCompanion")
                }
                Spacer()
                Text("60 BPM").font(.subheadline.monospacedDigit())
            }
            ProgressView(value: min(1, max(0, (practice.elapsed - 4) / 16)))
                .tint(BeatLabStyle.success).accessibilityLabel("回巢進度")
            EggMissionScene(elapsed: practice.elapsed, accepted: accepted,
                            presentationElapsed: { practice.presentationElapsed(at: $0) },
                            acceptedAction: acceptedAction, latestAction: practice.latestHit)
                .frame(height: sceneHeight)
            ZStack {
                Text("跳過了，下一拍稍等一下").hidden().accessibilityHidden(true)
                Text(cue).accessibilityIdentifier("jumpCue")
            }.font(.system(.headline, design: .rounded)).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { beat in
                    Capsule().fill(Int(max(0, practice.elapsed)) % 4 == beat ? BeatLabStyle.success : BeatLabStyle.line)
                        .frame(height: 6)
                }
            }.accessibilityElement(children: .ignore).accessibilityLabel("四拍跟鼓聲")
                .accessibilityValue("第 \(Int(max(0, practice.elapsed)) % 4 + 1) 拍，右手")
                .accessibilityIdentifier("rhythmLane")
            HStack {
                Text("跨過 \(accepted.count) / 16 個障礙").accessibilityIdentifier("jumpMatches")
                Spacer(minLength: 4)
                Text(streak >= 2 ? "連續 \(streak) 拍漂亮！" : "把蛋帶回家")
            }.font(.caption.bold())
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(HomeBrand.hero)
                Label("跳！", systemImage: "arrow.up").font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(ink).allowsHitTesting(false).accessibilityHidden(true)
                TapPad(feedback: "跳，\(cue)") { time, accessible in practice.tap(at: time, accessibility: accessible) }
            }.frame(height: textSize.isAccessibilitySize ? 100 : 76)
            Button(action: stop) { Label("停止挑戰", systemImage: "stop.fill").frame(maxWidth: .infinity, minHeight: 44) }
                .accessibilityIdentifier("stopPractice")
        }.fixedSize(horizontal: false, vertical: true)
    }
}
