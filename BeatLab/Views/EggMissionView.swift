import SwiftUI
import BeatLabCore

enum EggPose: Int { case runA, runB, ready, jump, catchEgg, celebrate, egg, nest, rock }

struct EggSprite: View {
    let pose: EggPose
    var body: some View {
        Canvas { context, size in
            let xs: [CGFloat] = [0, 440, 880, 1254], ys: [CGFloat] = [0, 478, 933, 1254]
            let col = pose.rawValue % 3, row = pose.rawValue / 3
            let width = xs[col + 1] - xs[col], height = ys[row + 1] - ys[row]
            let scale = min(size.width / width, size.height / height)
            let x = (size.width - width * scale) / 2 - xs[col] * scale
            let y = (size.height - height * scale) / 2 - ys[row] * scale
            let cell = CGRect(x: (size.width - width * scale) / 2, y: (size.height - height * scale) / 2,
                              width: width * scale, height: height * scale)
            context.clip(to: Path(cell))
            context.draw(Image("EggMissionAtlas"), in: CGRect(x: x, y: y, width: 1254 * scale, height: 1254 * scale))
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

struct EggMissionScene: View {
    var elapsed: Double
    var accepted: Set<Int> = []
    var latestGrade: TimingGrade?
    var hitAge: Double?
    var finishedPassed: Bool? = nil
    var preparing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let ink = Color(red: 0.08, green: 0.25, blue: 0.18)

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = geometry.size.height
            let ground = h * 0.86, playerX = w * 0.27, stride = w * 0.31
            let position = max(-4, elapsed - 4)
            let movingPosition = reduceMotion ? floor(position) : position
            let recovering = EggMissionPresentation.missed(elapsed: elapsed, accepted: accepted) != nil
            let pose = finishedPassed.map { $0 ? EggPose.celebrate : .catchEgg }
                ?? (preparing ? .ready : EggMissionPresentation.pose(elapsed: elapsed, hitAge: hitAge, grade: latestGrade, recovering: recovering, reduceMotion: reduceMotion))
            let hop = finishedPassed == nil && !preparing ? EggMissionPresentation.hop(hitAge: hitAge, grade: latestGrade, reduceMotion: reduceMotion) : 0
            let characterSize = min(180, max(118, h * 0.42))
            ZStack(alignment: .topLeading) {
                Image("RunnerIsland").resizable()
                    .frame(width: w + 24, height: h).offset(x: reduceMotion ? -12 : -CGFloat(max(0, position).truncatingRemainder(dividingBy: 8)) * 3)
                    .frame(width: w, height: h, alignment: .leading).clipped()
                Rectangle().fill(Color(red: 0.65, green: 0.82, blue: 0.45))
                    .frame(width: w, height: 12).position(x: w / 2, y: ground)
                Rectangle().fill(Color(red: 0.87, green: 0.69, blue: 0.42))
                    .frame(width: w, height: h - ground).position(x: w / 2, y: ground + (h - ground) / 2 + 6)
                if !preparing && finishedPassed == nil {
                    ForEach(0..<16, id: \.self) { id in
                        let x = playerX + CGFloat(Double(id) - movingPosition) * stride
                        if x > -70 && x < w + 70 {
                            if accepted.contains(id) {
                                Image(systemName: "sparkle").font(.title).foregroundStyle(Color(red: 0.95, green: 0.64, blue: 0.07))
                                    .position(x: x, y: ground - 34)
                            } else {
                                EggSprite(pose: .rock).frame(width: 74, height: 64).position(x: x, y: ground - 24)
                            }
                        }
                    }
                }
                let nestX = preparing || finishedPassed != nil ? w * 0.76 : playerX + CGFloat(16 - movingPosition) * stride
                if nestX < w + 100 {
                    EggSprite(pose: .nest).frame(width: 126, height: 84).position(x: nestX, y: ground - 25)
                }
                Ellipse().fill(ink.opacity(0.18)).frame(width: 82, height: 13).position(x: playerX, y: ground + 1)
                EggSprite(pose: pose).frame(width: characterSize, height: characterSize)
                    .position(x: playerX, y: ground - characterSize / 2 + 8 - min(hop, h * 0.25))
                if latestGrade == .perfect, let age = hitAge, age < 0.48, !preparing, finishedPassed == nil {
                    Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Color(red: 0.97, green: 0.67, blue: 0.07))
                        .position(x: playerX + 54, y: ground - characterSize - min(hop, h * 0.25) + 32)
                }
                HStack(spacing: 6) {
                    EggSprite(pose: .egg).frame(width: 22, height: 30)
                    Text(preparing ? "把蛋帶回家" : finishedPassed == nil ? "前往溫暖的巢" : "蛋安全接住了")
                        .font(.system(.subheadline, design: .rounded).bold())
                    Spacer(minLength: 4)
                    EggSprite(pose: .nest).frame(width: 38, height: 30)
                }.padding(10).background(Color(red: 1, green: 0.98, blue: 0.88), in: Capsule())
                    .padding(12).foregroundStyle(ink)
            }.frame(width: w, height: h).clipped()
        }.clipShape(RoundedRectangle(cornerRadius: 26))
            .accessibilityElement(children: .ignore).accessibilityLabel("恐龍送蛋回巢")
            .accessibilityValue(finishedPassed.map { $0 ? "任務通過" : "需要再試一次" } ?? "已跨過 \(accepted.count) 個障礙")
            .accessibilityIdentifier("eggMissionScene")
    }
}

struct EggMissionView: View {
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @Environment(\.dynamicTypeSize) private var textSize
    let accepted: Set<Int>
    let streak: Int
    let stop: () -> Void
    @State private var hitElapsed: Double?
    private let ink = Color(red: 0.08, green: 0.25, blue: 0.18)
    private var age: Double? { hitElapsed.map { max(0, practice.elapsed - $0) } }
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
                content(sceneHeight: max(160, geometry.size.height - 306))
                ScrollView { content(sceneHeight: 280) }
            }.padding(.horizontal, 16).padding(.vertical, 8)
                .frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
        }.onChange(of: practice.latestHit) { _ in hitElapsed = practice.elapsed }
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
            EggMissionScene(elapsed: practice.elapsed, accepted: accepted, latestGrade: practice.latestHit?.grade, hitAge: age)
                .frame(height: sceneHeight)
            Text(cue).font(.system(.headline, design: .rounded)).multilineTextAlignment(.center)
                .accessibilityIdentifier("jumpCue").fixedSize(horizontal: false, vertical: true)
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
