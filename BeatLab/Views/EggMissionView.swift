import SwiftUI
import UIKit
import SpriteKit
import BeatLabCore

/// Cosmetic mission vocabulary and motion personality; never creates targets.
enum RunnerTheme: String, CaseIterable {
    case dinosaur, cat, robot
    var title: String { self == .cat ? "貓咪" : self == .robot ? "機器人" : "恐龍" }
    var mission: String { self == .cat ? "把魚送回雲端小屋" : self == .robot ? "把能源送回充電站" : "把恐龍蛋帶回家" }
    var destination: String { self == .cat ? "前往雲端小屋" : self == .robot ? "前往充電站" : "前往溫暖的巢" }
    var item: String { self == .cat ? "魚包裹" : self == .robot ? "能源" : "蛋" }
    var obstacle: String { self == .cat ? "雲丘" : self == .robot ? "電路障礙" : "石頭" }
    var passed: String { self == .cat ? "魚送到小屋了！" : self == .robot ? "能源送到充電站了！" : "蛋安全回到巢了！" }
    var retry: String { self == .dinosaur ? "蛋接住了，再試一次！" : "\(item)接住了，再試一次！" }
    var backdrop: String { self == .cat ? "RunnerCloud" : self == .robot ? "RunnerCircuit" : "RunnerIsland" }
    var atlas: String { self == .cat ? "CatMotionAtlas" : "RobotMotionAtlas" }
    var bobAmplitude: CGFloat { self == .cat ? 2.5 : self == .robot ? 1 : 2 }
    var bobFrequency: Double { self == .cat ? 8 : self == .robot ? 12 : 10 }
    var lean: CGFloat { self == .cat ? 0.7 : self == .robot ? 0.25 : 1 }
    var compression: CGFloat { self == .cat ? 1.2 : self == .robot ? 0.4 : 1 }
    var accent: UIColor { self == .cat ? UIColor(red: 0.76, green: 0.35, blue: 0.22, alpha: 1) : self == .robot ? UIColor(red: 0.10, green: 0.36, blue: 0.66, alpha: 1) : UIColor(red: 0.25, green: 0.56, blue: 0.40, alpha: 1) }
    var pad: UIColor { self == .cat ? UIColor(red: 1, green: 0.84, blue: 0.68, alpha: 1) : self == .robot ? UIColor(red: 0.60, green: 0.87, blue: 0.98, alpha: 1) : UIColor(red: 1, green: 0.86, blue: 0.44, alpha: 1) }
}

struct MissionProp: View {
    let theme: RunnerTheme
    let destination: Bool
    var body: some View {
        if theme == .dinosaur { EggSprite(pose: destination ? .nest : .egg) }
        else if let image = CompanionAtlas.pack(theme).images[destination ? 19 : 18] {
            Image(decorative: image, scale: 1).resizable().scaledToFit().accessibilityHidden(true)
        }
    }
}

enum EggPose: Int { case runA, runB, ready, jump, catchEgg, celebrate, egg, nest, rock }
/// Reviewed alpha-bounds, cached once. Generated PNGs stay unchanged.
private enum CompanionAtlas {
    struct Pack {
        let images: [CGImage?]
        let textures: [SKTexture]
        init(name: String, bounds: [CGRect]) {
            let atlas = UIImage(named: name)?.cgImage
            images = bounds.map { atlas?.cropping(to: $0) }
            textures = images.map { image in
                guard let image else { return SKTexture() }
                let texture = SKTexture(cgImage: image); texture.filteringMode = .linear; return texture
            }
        }
    }
    static let cat = Pack(name: "CatMotionAtlas", bounds: [
        CGRect(x: 17, y: 31, width: 236, height: 226),
        CGRect(x: 278, y: 31, width: 224, height: 235),
        CGRect(x: 522, y: 29, width: 233, height: 233),
        CGRect(x: 776, y: 32, width: 237, height: 235),
        CGRect(x: 12, y: 296, width: 242, height: 232),
        CGRect(x: 279, y: 295, width: 227, height: 226),
        CGRect(x: 523, y: 296, width: 230, height: 226),
        CGRect(x: 774, y: 294, width: 225, height: 234),
        CGRect(x: 19, y: 633, width: 233, height: 181),
        CGRect(x: 275, y: 547, width: 229, height: 229),
        CGRect(x: 532, y: 541, width: 230, height: 211),
        CGRect(x: 787, y: 570, width: 226, height: 243),
        CGRect(x: 16, y: 851, width: 232, height: 226),
        CGRect(x: 272, y: 851, width: 226, height: 223),
        CGRect(x: 535, y: 841, width: 215, height: 237),
        CGRect(x: 773, y: 881, width: 232, height: 196),
        CGRect(x: 26, y: 1107, width: 230, height: 196),
        CGRect(x: 256, y: 1087, width: 255, height: 218),
        CGRect(x: 552, y: 1175, width: 173, height: 106),
        CGRect(x: 773, y: 1104, width: 235, height: 203),
        CGRect(x: 22, y: 1387, width: 232, height: 102),
        CGRect(x: 330, y: 1348, width: 121, height: 137),
        CGRect(x: 539, y: 1371, width: 208, height: 128),
        CGRect(x: 804, y: 1396, width: 182, height: 103)
    ])
    static let robot = Pack(name: "RobotMotionAtlas", bounds: [
        CGRect(x: 44, y: 18, width: 175, height: 232),
        CGRect(x: 291, y: 17, width: 190, height: 235),
        CGRect(x: 558, y: 18, width: 175, height: 233),
        CGRect(x: 799, y: 17, width: 189, height: 236),
        CGRect(x: 49, y: 271, width: 174, height: 236),
        CGRect(x: 291, y: 270, width: 189, height: 239),
        CGRect(x: 540, y: 271, width: 192, height: 238),
        CGRect(x: 799, y: 270, width: 189, height: 238),
        CGRect(x: 27, y: 565, width: 189, height: 202),
        CGRect(x: 280, y: 521, width: 217, height: 239),
        CGRect(x: 562, y: 525, width: 178, height: 204),
        CGRect(x: 787, y: 521, width: 205, height: 237),
        CGRect(x: 27, y: 784, width: 202, height: 233),
        CGRect(x: 287, y: 822, width: 206, height: 195),
        CGRect(x: 563, y: 775, width: 162, height: 243),
        CGRect(x: 801, y: 834, width: 200, height: 185),
        CGRect(x: 30, y: 1063, width: 197, height: 198),
        CGRect(x: 283, y: 1029, width: 198, height: 232),
        CGRect(x: 560, y: 1095, width: 163, height: 141),
        CGRect(x: 786, y: 1122, width: 225, height: 136),
        CGRect(x: 28, y: 1344, width: 222, height: 144),
        CGRect(x: 321, y: 1315, width: 136, height: 154),
        CGRect(x: 529, y: 1346, width: 215, height: 158),
        CGRect(x: 786, y: 1367, width: 212, height: 96)
    ])
    static let backgrounds = Dictionary(uniqueKeysWithValues: RunnerTheme.allCases.map { ($0, SKTexture(imageNamed: $0.backdrop)) })
    static func pack(_ theme: RunnerTheme) -> Pack { theme == .cat ? cat : robot }
    static func background(_ theme: RunnerTheme) -> SKTexture? { backgrounds[theme] }
}

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
    static func recoveryBlend(elapsed: Double, accepted: Set<Int>, actionAge: Double?, reduceMotion: Bool) -> CGFloat {
        if let age = actionAge, age.isFinite, (0..<0.64).contains(age) { return 0 }
        guard let id = missed(elapsed: elapsed, accepted: accepted) else { return 0 }
        if reduceMotion { return 0.12 }
        let age = elapsed - Double(4 + id) - (TimingSession.matchingWindow + 0.250)
        return CGFloat(max(0, sin(.pi * age / 0.48))) * 0.18
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
        let landing = validAge.map { (0.48..<0.64).contains($0) && grade != nil ? pow(sin(.pi * ($0 - 0.48) / 0.16), 2) : 0 } ?? 0
        let p = airborne ? validAge! / 0.48 : 0
        let curve = 6.75 * p * pow(1 - p, 2)
        return EggMotion(height: reduceMotion ? 0 : CGFloat(curve) * (grade == .extra ? 12 : 74),
                         scaleX: reduceMotion ? 1 : 1 + CGFloat(landing) * 0.10,
                         scaleY: reduceMotion ? 1 : 1 - CGFloat(landing) * 0.12,
                         angle: reduceMotion ? 0 : -0.12 * curve,
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

/// Read-only adapter over an existing TimingSession. It never creates or judges notes.
struct RunnerRoute {
    let epoch: Double
    let journeyHits: [TimingHit]
    let targets: [TimingTarget]
    let relativeTimes: [Double]
    let hits: [TimingHit]
    let alignment: Double
    let duration: Double
    let beatDuration: Double
    let accepted: Set<Int>
    let latestAccepted: TimingHit?
    let grades: [Int: TimingGrade]
    init?(targets: [TimingTarget], hits: [TimingHit], epoch: Double, endTime: Double, alignment: Double) {
        guard epoch.isFinite, endTime.isFinite, alignment.isFinite, abs(alignment) <= 0.25,
              targets.count >= 2, Set(targets.map(\.id)).count == targets.count,
              targets.allSatisfy({ $0.time.isFinite && $0.time >= epoch && $0.stroke != .rest }),
              zip(targets, targets.dropFirst()).allSatisfy({ $0.time < $1.time }),
              let last = targets.last, endTime >= last.time else { return nil }
        self.targets = targets; self.hits = hits; self.alignment = alignment; self.epoch = epoch
        let ids = Set(targets.map(\.id))
        var seen = Set<Int>()
        journeyHits = hits.filter { hit in
            guard let id = hit.targetID, ids.contains(id), hit.grade != .extra,
                  hit.inputTime.isFinite, hit.inputTime >= epoch else { return false }
            return seen.insert(id).inserted
        }.sorted { $0.inputTime < $1.inputTime }
        accepted = Set(hits.compactMap(\.targetID))
        latestAccepted = hits.last { $0.targetID != nil }
        grades = Dictionary(hits.compactMap { hit in hit.targetID.map { ($0, hit.grade) } }, uniquingKeysWith: { first, _ in first })
        relativeTimes = targets.map { $0.time - epoch }
        beatDuration = targets[1].time - targets[0].time
        duration = endTime - epoch
    }
    func currentIndex(at elapsed: Double) -> Int? {
        guard elapsed.isFinite else { return nil }
        return relativeTimes.lastIndex { $0 <= elapsed }
    }
    func missed(at elapsed: Double) -> Int? {
        guard elapsed.isFinite else { return nil }
        return targets.indices.last { index in
            let age = elapsed - relativeTimes[index] - alignment - TimingSession.matchingWindow
            return age > 1e-10 && age < 0.48 && !accepted.contains(targets[index].id)
        }.map { targets[$0].id }
    }
    func recovery(at elapsed: Double, actionAge: Double?, reduced: Bool) -> CGFloat {
        if let actionAge, (0..<0.64).contains(actionAge) { return 0 }
        guard let id = missed(at: elapsed), let index = targets.firstIndex(where: { $0.id == id }) else { return 0 }
        if reduced { return 0.12 }
        let age = elapsed - relativeTimes[index] - alignment - TimingSession.matchingWindow
        return CGFloat(max(0, sin(.pi * age / 0.48))) * 0.18
    }
    func rockPosition(index: Int, elapsed: Double, marker: CGFloat, stride: CGFloat, reduced: Bool) -> CGFloat? {
        guard relativeTimes.indices.contains(index), elapsed.isFinite else { return nil }
        let travel = (relativeTimes[index] - elapsed) / beatDuration
        return marker + CGFloat(reduced ? ceil(travel) : travel) * stride
    }
    func obstacleAlpha(index: Int, elapsed: Double, reduced: Bool) -> CGFloat {
        guard relativeTimes.indices.contains(index), elapsed.isFinite,
              accepted.contains(targets[index].id), elapsed > relativeTimes[index] else { return 1 }
        return reduced ? 0 : CGFloat(max(0, 1 - (elapsed - relativeTimes[index]) / 0.25))
    }
}

/// Pure world motion from real accepted inputs. Never a collision or grade source.
struct PlatformJourneyFrame {
    let step: Double
    let camera: Double
    let jumpAge: Double?
    let fall: Double
    static func sample(route: RunnerRoute?, elapsed: Double, reduced: Bool) -> Self {
        guard let route, elapsed.isFinite, elapsed >= 0 else {
            return Self(step: 0, camera: 0, jumpAge: nil, fall: 0)
        }
        var step = 0.0, camera = 0.0
        var age: Double?
        for (index, hit) in route.journeyHits.enumerated() {
            let a = elapsed - (hit.inputTime - route.epoch)
            guard a >= 0 else { continue }
            step += reduced ? 1 : Double(EggAnimationFrame.ease(a / 0.48))
            let delta = max(0, Double(index + 1) - 1.3) - max(0, Double(index) - 1.3)
            camera += delta * (reduced ? 1 : Double(EggAnimationFrame.ease((a - 0.48) / 0.32)))
            age = a
        }
        var fall = 0.0
        if !reduced, age.map({ $0 >= 0.64 }) ?? true,
           let id = route.missed(at: elapsed), let index = route.targets.firstIndex(where: { $0.id == id }) {
            let a = elapsed - route.relativeTimes[index] - route.alignment - TimingSession.matchingWindow
            fall = sin(.pi * min(1, max(0, a / 0.48)))
        }
        return Self(step: step, camera: camera, jumpAge: age, fall: max(0, fall))
    }
}

struct EggMissionScene: View {
    var theme: RunnerTheme = .dinosaur
    var elapsed: Double
    var accepted: Set<Int> = []
    var latestGrade: TimingGrade?
    var hitAge: Double?
    var finishedPassed: Bool? = nil
    var preparing = false
    var presentationElapsed: ((Double) -> Double)? = nil
    var acceptedAction: TimingHit? = nil
    var latestAction: TimingHit? = nil
    var route: RunnerRoute? = nil
    var platformJourney = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var textSize
    private let ink = Color(red: 0.08, green: 0.25, blue: 0.18)
    private var sceneCaption: String {
        if textSize.isAccessibilitySize {
            if let passed = finishedPassed { return passed ? "送到了！" : "接住了！" }
            if preparing { return theme == .cat ? "帶魚出發" : theme == .robot ? "帶能源" : "帶蛋出發" }
            return theme == .cat ? "往小屋" : theme == .robot ? "往充電站" : "往家裡"
        }
        return preparing ? theme.mission : finishedPassed == nil ? theme.destination : finishedPassed == true ? theme.passed : "\(theme.item)安全接住了"
    }

    var body: some View {
        ZStack(alignment: .top) {
            EggSpriteSurface(state: EggSceneSnapshot(elapsed: elapsed, accepted: accepted,
                latestGrade: latestGrade, hitAge: hitAge, finishedPassed: finishedPassed, preparing: preparing,
                reduceMotion: reduceMotion, suspended: scenePhase != .active,
                presentationElapsed: presentationElapsed, acceptedAction: acceptedAction, latestAction: latestAction, theme: theme, route: route, platformJourney: platformJourney))
                .accessibilityHidden(true)
            if !platformJourney || preparing || finishedPassed != nil {
            HStack(spacing: 6) {
                MissionProp(theme: theme, destination: false).frame(width: 22, height: 30)
                Text(sceneCaption)
                    .font(.system(.subheadline, design: .rounded).bold())
                Spacer(minLength: 4)
                MissionProp(theme: theme, destination: true).frame(width: 38, height: 30)
            }.padding(10).background(Color(red: 1, green: 0.98, blue: 0.88), in: Capsule())
                .padding(12).foregroundStyle(ink)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 26))
            .accessibilityElement(children: .ignore).accessibilityLabel(theme.mission)
            .accessibilityValue(finishedPassed.map { $0 ? "任務通過" : "需要再試一次" } ?? (platformJourney ? "抵達 \(accepted.count) 座小島" : "已跨過 \(accepted.count) 個障礙"))
            .accessibilityIdentifier("eggMissionScene")
    }
}

struct EggAnimationFrame {
    static func ease(_ value: Double) -> CGFloat {
        let t = value.isFinite ? min(1, max(0, value)) : 0
        return CGFloat(t * t * (3 - 2 * t))
    }
    static func sample(elapsed: Double, age: Double?, reduceMotion: Bool) -> Int {
        guard !reduceMotion, elapsed.isFinite, elapsed >= 0, elapsed <= 20.18 else { return 14 }
        let phase = (max(0, elapsed - 4) * 16).truncatingRemainder(dividingBy: 8)
        let run = Int(phase)
        if let age, age.isFinite, (0..<0.48).contains(age) {
            return 8 + min(5, Int(age / 0.48 * 6))
        }
        if let age, age.isFinite, (0.48..<0.64).contains(age) {
            return age < 0.56 ? 13 : 15
        }
        return elapsed >= 4 ? run : 14
    }
}

/// Outcome affects only a cue that has already reached its scheduled crossing.
/// A matched early tap must never make an upcoming beat disappear.
enum EggBeatLane {
    static func obstacleAlpha(id: Int, elapsed: Double, matched: Bool, reduceMotion: Bool) -> CGFloat {
        guard matched, elapsed.isFinite, (0..<16).contains(id) else { return 1 }
        let age = elapsed - Double(4 + id)
        guard age > 0 else { return 1 }
        return reduceMotion ? 0 : CGFloat(max(0, 1 - age / 0.25))
    }
    static func markerAlpha(elapsed: Double, reduceMotion: Bool) -> CGFloat {
        guard !reduceMotion, elapsed.isFinite, (4..<20).contains(elapsed) else { return 0.45 }
        let phase = (elapsed - 4).truncatingRemainder(dividingBy: 1)
        return 0.45 + 0.55 * CGFloat(max(0, 1 - phase / 0.12))
    }
}

struct EggSceneSnapshot {
    var elapsed: Double = 0
    var accepted: Set<Int> = []
    var latestGrade: TimingGrade?
    var hitAge: Double?
    var finishedPassed: Bool?
    var preparing = false
    var reduceMotion = false
    var suspended = false
    var presentationElapsed: ((Double) -> Double)?
    var acceptedAction: TimingHit?
    var latestAction: TimingHit?
    var theme: RunnerTheme = .dinosaur
    var route: RunnerRoute? = nil
    var platformJourney = false
    var animate: Bool { !reduceMotion && !suspended && !preparing && finishedPassed == nil && presentationElapsed != nil }
}

private enum EggSceneTextures {
    static let journeyBackdrops: [RunnerTheme: SKTexture] = Dictionary(uniqueKeysWithValues: RunnerTheme.allCases.map { theme in
        guard let image = UIImage(named: theme.backdrop)?.cgImage,
              let sky = image.cropping(to: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height) * 0.74)) else {
            return (theme, SKTexture(imageNamed: theme.backdrop))
        }
        return (theme, SKTexture(cgImage: sky))
    })
    static let original: [SKTexture] = {
        let atlas = UIImage(named: "EggMissionAtlas")?.cgImage
        return EggSpriteAssets.bounds.map { bounds in
            guard let image = atlas?.cropping(to: bounds) else { return SKTexture() }
            let texture = SKTexture(cgImage: image); texture.filteringMode = .linear; return texture
        }
    }()
    static let animated: [SKTexture] = {
        guard let atlas = UIImage(named: "EggMotionAtlas")?.cgImage else { return (0..<16).map { _ in SKTexture() } }
        return (0..<16).map { i in
            let x0 = (Double(i % 4) * Double(atlas.width) / 4).rounded(.toNearestOrEven)
            let y0 = (Double(i / 4) * Double(atlas.height) / 4).rounded(.toNearestOrEven)
            let x1 = (Double(i % 4 + 1) * Double(atlas.width) / 4).rounded(.toNearestOrEven)
            let y1 = (Double(i / 4 + 1) * Double(atlas.height) / 4).rounded(.toNearestOrEven)
            guard let image = atlas.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)) else { return SKTexture() }
            let texture = SKTexture(cgImage: image); texture.filteringMode = .linear; return texture
        }
    }()
    // Reviewed eye registration from the unchanged generated PNG. Only runtime
    // anchors change; textures retain original alpha and pixels.
    static let floors: [CGFloat] = [306.000000, 303.547619, 299.666667, 304.812500, 313.850000, 314.032787, 312.607143, 314.522388, 302.476190, 299.638298, 302.062500, 302.023256, 290.000000, 289.000000, 292.000000, 288.000000]
    static let eyes: [CGPoint] = [.init(x: 207.292683, y: 94.000000), .init(x: 201.095238, y: 91.547619), .init(x: 201.222222, y: 87.666667), .init(x: 205.187500, y: 92.812500), .init(x: 205.850000, y: 101.850000), .init(x: 203.032787, y: 102.032787), .init(x: 203.428571, y: 100.607143), .init(x: 206.731343, y: 102.522388), .init(x: 204.380952, y: 90.476190), .init(x: 200.851064, y: 87.638298), .init(x: 201.583333, y: 90.062500), .init(x: 197.069767, y: 90.023256), .init(x: 207.909091, y: 102.054545), .init(x: 204.305556, y: 93.902778), .init(x: 205.015625, y: 97.000000), .init(x: 204.926829, y: 107.902439)]
}

/// Persistent scene graph. Input, sound, targets, grades and saves live elsewhere.
final class EggSpriteScene: SKScene {
    private var graphReady = false
    private var snapshot = EggSceneSnapshot()
    private(set) var theme: RunnerTheme = .dinosaur
    private let island = SKSpriteNode(texture: SKTexture(imageNamed: "RunnerIsland"))
    private let floor = SKSpriteNode(color: UIColor(red: 0.87, green: 0.69, blue: 0.42, alpha: 1), size: .zero)
    private let edge = SKSpriteNode(color: UIColor(red: 0.65, green: 0.82, blue: 0.45, alpha: 1), size: .zero)
    private let player = SKNode()
    private let first = SKSpriteNode()
    private let shadow = SKShapeNode(ellipseOf: CGSize(width: 82, height: 10))
    private let beatMarker = SKShapeNode(ellipseOf: CGSize(width: 48, height: 12))
    private let nest = SKSpriteNode(texture: EggSceneTextures.original[7])
    private var rocks: [SKSpriteNode] = [], rewards: [SKShapeNode] = [], pebbles: [SKShapeNode] = [], dust: [SKShapeNode] = []
    private var platforms: [SKSpriteNode] = [], platformTops: [SKShapeNode] = []
    private let nextBeat = SKLabelNode(fontNamed: "ArialRoundedMTBold")
    private let safety = SKShapeNode(ellipseOf: CGSize(width: 90, height: 22))
    private let glint: SKShapeNode
    private var characterSize: CGFloat = 118
    #if DEBUG
    private(set) var callbackCount = 0
    private var previousHost: Double?
    private var intervals = Array(repeating: 0.0, count: 256)
    private var work = Array(repeating: 0.0, count: 256)
    private var recorded = 0
    #endif

    override init(size: CGSize) {
        let path = CGMutablePath()
        let points = [CGPoint(x: 0, y: 14), .init(x: 3, y: 3), .init(x: 14, y: 0), .init(x: 3, y: -3),
                      .init(x: 0, y: -14), .init(x: -3, y: -3), .init(x: -14, y: 0), .init(x: -3, y: 3)]
        path.addLines(between: points); path.closeSubpath(); glint = SKShapeNode(path: path)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 1, green: 0.95, blue: 0.81, alpha: 1)
        island.name = "backdrop"; island.anchorPoint = .zero; island.zPosition = 0; addChild(island)
        floor.zPosition = 1; edge.zPosition = 2; addChild(floor); addChild(edge)
        shadow.fillColor = UIColor(red: 0.08, green: 0.25, blue: 0.18, alpha: 1); shadow.strokeColor = .clear; shadow.zPosition = 4; addChild(shadow)
        beatMarker.name = "beatMarker"; beatMarker.fillColor = .systemYellow; beatMarker.strokeColor = .clear
        beatMarker.zPosition = 8; addChild(beatMarker)
        player.name = "player"; player.zPosition = 6; addChild(player)
        first.name = "characterPrimary"; first.zPosition = 0
        player.addChild(first)
        nest.name = "destination"; nest.anchorPoint = CGPoint(x: 0.5, y: 0); nest.zPosition = 3; addChild(nest)
        for id in 0..<16 {
            let rock = SKSpriteNode(texture: EggSceneTextures.original[8]); rock.name = "rock\(id)"
            rock.anchorPoint = CGPoint(x: 0.5, y: 0); rock.zPosition = 3; addChild(rock); rocks.append(rock)
            let reward = SKShapeNode(path: path); reward.name = "reward\(id)"; reward.fillColor = .systemYellow; reward.strokeColor = .clear
            reward.zPosition = 3; addChild(reward); rewards.append(reward)
        }
        for index in 0...16 {
            let platform = SKSpriteNode(texture: EggSceneTextures.original[8])
            platform.name = "platform\(index)"; platform.anchorPoint = CGPoint(x: 0.5, y: 1)
            platform.zPosition = 3; platform.isHidden = true; addChild(platform); platforms.append(platform)
            let top = SKShapeNode(rectOf: CGSize(width: 72, height: 8), cornerRadius: 4)
            top.strokeColor = .clear; top.zPosition = 4; top.isHidden = true
            addChild(top); platformTops.append(top)
        }
        nextBeat.name = "nextLandingCue"; nextBeat.fontSize = 30; nextBeat.zPosition = 5
        nextBeat.isHidden = true; addChild(nextBeat)
        safety.name = "safetyCatch"; safety.strokeColor = .clear; safety.zPosition = 5
        safety.isHidden = true; addChild(safety)
        for _ in 0..<10 {
            let pebble = SKShapeNode(ellipseOf: CGSize(width: 14, height: 5)); pebble.fillColor = UIColor(red: 0.78, green: 0.58, blue: 0.34, alpha: 1)
            pebble.strokeColor = .clear; pebble.zPosition = 2; addChild(pebble); pebbles.append(pebble)
        }
        for _ in 0..<3 {
            let puff = SKShapeNode(ellipseOf: CGSize(width: 12, height: 7)); puff.fillColor = UIColor(red: 0.95, green: 0.83, blue: 0.60, alpha: 1)
            puff.strokeColor = .clear; puff.zPosition = 5; addChild(puff); dust.append(puff)
        }
        glint.fillColor = .systemYellow; glint.strokeColor = .clear; glint.zPosition = 7; addChild(glint)
        graphReady = true
        resizeNodes()
    }
    required init?(coder: NSCoder) { nil }
    override func didChangeSize(_ oldSize: CGSize) { resizeNodes(); render(at: PracticeStore.now()) }
    private func resizeNodes() {
        guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return }
        let ground = size.height * 0.14
        island.size = CGSize(width: size.width + 24, height: size.height)
        floor.size = CGSize(width: size.width, height: max(0, ground - 6)); floor.position = CGPoint(x: size.width / 2, y: floor.size.height / 2)
        edge.size = CGSize(width: size.width, height: 12); edge.position = CGPoint(x: size.width / 2, y: ground)
        characterSize = min(180, max(118, size.height * 0.42))
        if theme == .dinosaur {
            nest.size = CGSize(width: 70 * 397 / 248, height: 70)
            for rock in rocks { rock.size = CGSize(width: 54 * 351 / 260, height: 54) }
        } else {
            let pack = CompanionAtlas.pack(theme), destination = pack.textures[19].size(), obstacle = pack.textures[20].size()
            nest.size = CGSize(width: 70 * destination.width / max(1, destination.height), height: 70)
            for rock in rocks { rock.size = CGSize(width: 38 * obstacle.width / max(1, obstacle.height), height: 38) }
        }
    }
    func configure(_ state: EggSceneSnapshot) {
        if theme != state.theme { applyTheme(state.theme) }
        snapshot = state
        #if DEBUG
        if !state.animate { previousHost = nil }
        #endif
        render(at: PracticeStore.now())
        view?.isPaused = !state.animate
    }
    private func applyTheme(_ next: RunnerTheme) {
        theme = next
        island.texture = CompanionAtlas.background(next)
        if next == .dinosaur {
            nest.texture = EggSceneTextures.original[7]
            for rock in rocks { rock.texture = EggSceneTextures.original[8] }
            floor.color = UIColor(red: 0.87, green: 0.69, blue: 0.42, alpha: 1)
            edge.color = UIColor(red: 0.65, green: 0.82, blue: 0.45, alpha: 1)
        } else {
            let pack = CompanionAtlas.pack(next)
            nest.texture = pack.textures[19]
            for rock in rocks { rock.texture = pack.textures[20] }
            floor.color = next == .cat ? UIColor(red: 1, green: 0.96, blue: 0.91, alpha: 1) : UIColor(red: 0.33, green: 0.48, blue: 0.71, alpha: 1)
            edge.color = next == .cat ? UIColor(red: 1, green: 0.89, blue: 0.83, alpha: 1) : UIColor(red: 0.35, green: 0.79, blue: 0.93, alpha: 1)
        }
        for pebble in pebbles { pebble.fillColor = next.accent.withAlphaComponent(0.25) }
        for puff in dust { puff.fillColor = next.pad }
        beatMarker.fillColor = .systemYellow
        glint.fillColor = next == .robot ? .cyan : .systemYellow
        resizeNodes()
    }
    func detach() {
        snapshot.presentationElapsed = nil; snapshot.acceptedAction = nil; snapshot.latestAction = nil
        view?.isPaused = true
        #if DEBUG
        previousHost = nil
        #endif
    }
    override func update(_ currentTime: TimeInterval) {
        guard snapshot.animate else { return }
        // Framework currentTime is not transported into matching/audio clocks.
        let host = PracticeStore.now(); render(at: host)
        #if DEBUG
        let index = recorded % intervals.count
        if let previousHost { intervals[index] = max(0, host - previousHost); work[index] = max(0, PracticeStore.now() - host); recorded += 1 }
        previousHost = host; callbackCount += 1
        #endif
    }
    func render(at host: Double) {
        // SKScene can call didChangeSize from super.init before children exist.
        guard graphReady, size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return }
        let raw = snapshot.presentationElapsed?(host) ?? snapshot.elapsed
        let elapsed = raw.isFinite ? min(20.18, max(0, raw)) : 0
        if snapshot.platformJourney { renderJourney(elapsed: elapsed, host: host); return }
        island.texture = CompanionAtlas.background(theme)
        floor.isHidden = false; edge.isHidden = false
        pebbles.forEach { $0.isHidden = false }; rewards.forEach { $0.setScale(1) }
        characterSize = min(180, max(118, size.height * 0.42))
        platforms.forEach { $0.isHidden = true }; platformTops.forEach { $0.isHidden = true }
        nextBeat.isHidden = true; safety.isHidden = true
        let action = EggMotion.action(accepted: snapshot.acceptedAction, latest: snapshot.latestAction, hostTime: host)
        let age = snapshot.presentationElapsed == nil ? snapshot.hitAge : action.map { max(0, host - $0.inputTime) }
        let grade = snapshot.presentationElapsed == nil ? snapshot.latestGrade : action?.grade
        let reduced = snapshot.reduceMotion, stopped = snapshot.preparing || snapshot.finishedPassed != nil
        let motion = EggMotion.sample(elapsed: elapsed, age: stopped ? nil : age, grade: grade, reduceMotion: reduced)
        let w = size.width, h = size.height, ground = h * 0.14, x = w * 0.27, stride = w * 0.31
        let position = max(-4, elapsed - 4), moving = reduced ? position.rounded(.down) : position
        let recovery = stopped ? 0 : snapshot.route?.recovery(at: elapsed, actionAge: age, reduced: reduced) ?? 0
        island.position.x = motion.backgroundX
        let offset = stopped || reduced ? 0 : CGFloat(max(0, position)) * stride
        for (i, pebble) in pebbles.enumerated() {
            let period = w + 180, raw = CGFloat(i - 2) * 90 - offset
            pebble.position = CGPoint(x: (raw.truncatingRemainder(dividingBy: period) + period).truncatingRemainder(dividingBy: period) - 83,
                                      y: ground - 26 - CGFloat(i % 3) * 7)
        }
        for index in rocks.indices {
            let route = snapshot.route
            let px = route?.rockPosition(index: index, elapsed: elapsed, marker: x, stride: stride, reduced: reduced) ?? -100
            let target = route.flatMap { $0.targets.indices.contains(index) ? $0.targets[index] : nil }
            let visible = !stopped && target != nil && px > -70 && px < w + 70
            let matched = target.map { route?.accepted.contains($0.id) == true } ?? false
            let alpha = route?.obstacleAlpha(index: index, elapsed: elapsed, reduced: reduced) ?? 1
            rocks[index].alpha = alpha; rocks[index].isHidden = !visible || alpha == 0
            rocks[index].position = CGPoint(x: px, y: ground - 5)
            rewards[index].isHidden = !visible || !matched || elapsed < (route?.relativeTimes[index] ?? .infinity)
            rewards[index].position = CGPoint(x: px, y: ground + 75)
        }
        beatMarker.isHidden = stopped || snapshot.route == nil
        beatMarker.position = CGPoint(x: x, y: ground - 6)
        beatMarker.alpha = EggBeatLane.markerAlpha(elapsed: elapsed, reduceMotion: reduced)
        let routeEnd = snapshot.route?.relativeTimes.last.map { $0 + (snapshot.route?.beatDuration ?? 1) } ?? .infinity
        let nestX = stopped ? w * 0.76 : snapshot.route == nil ? w + 200 : x + CGFloat((routeEnd - elapsed) / (snapshot.route?.beatDuration ?? 1)) * stride
        nest.isHidden = nestX >= w + 100; nest.position = CGPoint(x: nestX, y: ground - 7)
        // Scale the whole trajectory to fit; clipping its top makes a flat,
        // abruptly changing flight on shorter screens.
        let hop = motion.height * min(1, h * 0.25 / (grade == .extra ? 12 : 74))
        shadow.position = CGPoint(x: x, y: ground - 5); shadow.xScale = 1 - hop / 180; shadow.alpha = 0.18 - hop / 74 * 0.07
        let running = !stopped && !reduced && elapsed >= 4 && hop == 0
        let gaitWeight = age.map { EggAnimationFrame.ease(($0 - 0.64) / 0.12) } ?? 1
        let bob = running ? CGFloat(sin(elapsed * .pi * theme.bobFrequency)) * theme.bobAmplitude * gaitWeight : 0
        player.position = CGPoint(x: x, y: ground - 5 + hop + bob)
        player.zRotation = -motion.angle * Double(theme.lean)
        player.xScale = 1 + (motion.scaleX - 1) * theme.compression
        player.yScale = 1 + (motion.scaleY - 1) * theme.compression
        first.color = .white; first.colorBlendFactor = recovery
        if let passed = snapshot.finishedPassed { setOriginal(first, passed ? 5 : 4) }
        else {
            setAnimated(first, EggAnimationFrame.sample(elapsed: snapshot.preparing ? 0 : elapsed, age: age, reduceMotion: reduced))
        }
        for (i, puff) in dust.enumerated() {
            puff.alpha = motion.landing * 0.7; puff.xScale = 1 + motion.landing * 2 / 3
            puff.position = CGPoint(x: x - 24 - CGFloat(i) * 15, y: ground + CGFloat(i) * 3)
        }
        glint.isHidden = grade != .perfect || age == nil || !(0..<0.48).contains(age!) || stopped
        glint.position = CGPoint(x: x + 54, y: ground + characterSize + hop - 24)
    }
    private func renderJourney(elapsed: Double, host: Double) {
        let route = snapshot.route, reduced = snapshot.reduceMotion
        let state = PlatformJourneyFrame.sample(route: route, elapsed: snapshot.preparing ? 0 : elapsed, reduced: reduced)
        let stopped = snapshot.preparing || snapshot.finishedPassed != nil
        let w = size.width, h = size.height, stride = w * 0.27, ground = h * 0.31
        let completed = snapshot.finishedPassed == true
        let step = completed ? 16 : state.step, camera = completed ? 14.7 : state.camera
        let origin = w * 0.20 - CGFloat(camera) * stride
        let activeFlight = !stopped && state.jumpAge.map { (0..<0.48).contains($0) } == true
        let age = state.jumpAge ?? 1
        let hop = activeFlight && !reduced ? CGFloat(sin(.pi * age / 0.48)) * min(78, h * 0.20) : 0
        let fall = stopped ? 0 : CGFloat(state.fall)
        let extraAge = route?.hits.last.flatMap { $0.grade == .extra ? elapsed - ($0.inputTime - (route?.epoch ?? 0)) : nil }
        let extra = !stopped && !reduced && !activeFlight && age >= 0.64 && extraAge.map { (0..<0.22).contains($0) } == true ? CGFloat(sin(.pi * extraAge! / 0.22)) : 0
        let x = origin + CGFloat(step) * stride + fall * stride * 0.30 + extra * 3
        let y = ground + hop - fall * min(64, h * 0.18)
        characterSize = min(132, max(90, h * 0.27))
        island.texture = EggSceneTextures.journeyBackdrops[theme]
        island.position = CGPoint(x: -CGFloat(camera) * 1.5, y: 0)
        floor.isHidden = true; edge.isHidden = true
        rocks.forEach { $0.isHidden = true }; rewards.forEach { $0.isHidden = true }
        pebbles.forEach { $0.isHidden = true }
        for index in platforms.indices {
            let px = origin + CGFloat(index) * stride
            let visible = px > -w * 0.2 && px < w * 1.2
            let platform = platforms[index], top = platformTops[index]
            platform.isHidden = !visible; top.isHidden = !visible
            platform.texture = theme == .dinosaur ? EggSceneTextures.original[8] : CompanionAtlas.pack(theme).textures[20]
            platform.size = CGSize(width: w * 0.19, height: min(72, w * 0.18))
            platform.position = CGPoint(x: px, y: ground - 4)
            platform.alpha = 1
            top.position = CGPoint(x: px, y: ground - 3); top.xScale = w * 0.19 / 72
            top.fillColor = theme.accent
            let landed = index > 0 && index <= Int((step + 1e-8).rounded(.down))
            if landed && index <= rewards.count {
                let reward = rewards[index - 1]
                reward.isHidden = !visible; reward.position = CGPoint(x: px, y: ground - 26)
                reward.setScale(0.5)
            }
        }
        let next = min(16, Int((step + 1e-8).rounded(.down)) + 1)
        let landingX = origin + CGFloat(next) * stride
        beatMarker.isHidden = completed || snapshot.finishedPassed == false
        beatMarker.position = CGPoint(x: landingX, y: ground + 1)
        beatMarker.alpha = EggBeatLane.markerAlpha(elapsed: elapsed, reduceMotion: reduced)
        nextBeat.isHidden = stopped || route == nil || activeFlight
        nextBeat.position = CGPoint(x: landingX, y: ground + 36)
        nextBeat.fontColor = theme.accent
        nextBeat.text = "♪"
        nextBeat.alpha = reduced ? 1 : beatMarker.alpha
        let endX = origin + 16 * stride
        nest.isHidden = endX > w + 60; nest.position = CGPoint(x: endX, y: ground)
        shadow.position = CGPoint(x: x, y: ground + 1)
        shadow.xScale = 0.75 - hop / 300; shadow.alpha = fall > 0 ? 0 : 0.20 - hop / 600
        player.position = CGPoint(x: x, y: y)
        player.zRotation = reduced ? 0 : Double(fall) * -0.25 * Double(theme.lean)
        let landing = !stopped && !reduced && (0.48..<0.64).contains(age) ? CGFloat(pow(sin(.pi * (age - 0.48) / 0.16), 2)) : 0
        player.xScale = 1 + landing * 0.08 * theme.compression
        player.yScale = 1 - landing * 0.10 * theme.compression
        first.color = .white; first.colorBlendFactor = 0
        if let passed = snapshot.finishedPassed { setOriginal(first, passed ? 5 : 4) }
        else { setAnimated(first, activeFlight ? EggAnimationFrame.sample(elapsed: elapsed, age: age, reduceMotion: reduced) : 14) }
        safety.isHidden = fall == 0
        safety.fillColor = theme.pad.withAlphaComponent(0.65)
        safety.position = CGPoint(x: x, y: y - 6); safety.alpha = fall
        for (index, puff) in dust.enumerated() {
            puff.alpha = landing * 0.6; puff.xScale = 1 + landing
            puff.position = CGPoint(x: x - 18 - CGFloat(index) * 12, y: ground + CGFloat(index) * 3)
        }
        let latest = route?.journeyHits.last
        glint.isHidden = latest?.grade != .perfect || !activeFlight
        glint.position = CGPoint(x: x + 36, y: y + characterSize - 20)
    }
    private func setOriginal(_ node: SKSpriteNode, _ index: Int) {
        if theme != .dinosaur { setAnimated(node, index == 5 ? 17 : 16); return }
        let texture = EggSceneTextures.original[index]
        if node.texture !== texture { node.texture = texture }
        let source = EggSpriteAssets.bounds[index].size
        node.anchorPoint = CGPoint(x: 0.5, y: 0); node.size = CGSize(width: source.width * characterSize / 452, height: source.height * characterSize / 452)
    }
    private func setAnimated(_ node: SKSpriteNode, _ index: Int) {
        if theme != .dinosaur {
            let texture = CompanionAtlas.pack(theme).textures[index], source = texture.size()
            if node.texture !== texture { node.texture = texture }
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            node.size = CGSize(width: source.width * characterSize / 240, height: source.height * characterSize / 240)
            return
        }
        let texture = EggSceneTextures.animated[index], source = texture.size(), eye = EggSceneTextures.eyes[index]
        if node.texture !== texture { node.texture = texture }
        guard source.width > 0, source.height > 0 else { node.size = .zero; return }
        node.anchorPoint = CGPoint(x: (eye.x - 40) / source.width, y: 1 - EggSceneTextures.floors[index] / source.height)
        node.size = CGSize(width: source.width * characterSize / 295, height: source.height * characterSize / 295)
    }
    #if DEBUG
    func diagnostics() -> [String: Double] {
        let count = min(recorded, intervals.count)
        let values = Array(intervals.prefix(count)).sorted(), costs = Array(work.prefix(count)).sorted()
        guard count > 0 else { return ["callbacks": Double(callbackCount)] }
        return ["callbacks": Double(callbackCount), "samples": Double(count), "callback_interval_median_seconds": values[count / 2],
                "callback_interval_p95_seconds": values[min(count - 1, Int(Double(count) * 0.95))], "render_work_p95_seconds": costs[min(count - 1, Int(Double(count) * 0.95))]]
    }
    #endif
}

private struct EggSpriteSurface: UIViewRepresentable {
    let state: EggSceneSnapshot
    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.isUserInteractionEnabled = false; view.accessibilityElementsHidden = true
        view.allowsTransparency = false; view.ignoresSiblingOrder = true; view.preferredFramesPerSecond = 60
        let scene = EggSpriteScene(size: CGSize(width: 1, height: 1)); view.presentScene(scene); scene.configure(state)
        return view
    }
    func updateUIView(_ view: SKView, context: Context) { (view.scene as? EggSpriteScene)?.configure(state) }
    static func dismantleUIView(_ view: SKView, coordinator: ()) {
        (view.scene as? EggSpriteScene)?.detach(); view.presentScene(nil)
    }
}

struct EggMissionView: View {
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @Environment(\.dynamicTypeSize) private var textSize
    let accepted: Set<Int>
    let streak: Int
    let stop: () -> Void
    var theme: RunnerTheme = .dinosaur
    private var route: RunnerRoute? { practice.runnerRoute }
    private let ink = Color(red: 0.08, green: 0.25, blue: 0.18)
    private var age: Double? { practice.latestHit.map { max(0, PracticeStore.now() - $0.inputTime) } }
    private var cue: String {
        guard let route else { return "準備拍點，馬上開始…" }
        if practice.elapsed < route.relativeTimes[0], practice.latestHit == nil { return "先聽 \(max(1, Int(ceil((route.relativeTimes[0] - practice.elapsed) / route.beatDuration)))) 拍，準備跳" }
        if let age, age < 0.48, let grade = practice.latestHit?.grade {
            switch grade {
            case .perfect: return "漂亮！\(theme.item)亮起來了"
            case .early: return "跳過了，下一拍稍等一下"
            case .late: return "跳過了，下一拍早一點"
            case .extra: return "多打一下，再跟上"
            }
        }
        return route.missed(at: practice.elapsed) == nil ? "跟鼓聲，跳到亮起的小島！" : "接回來了，下一拍再跳！"
    }
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                ScrollView {
                    VStack(spacing: 10) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("第 1 關 · 節奏跨島").font(.headline).accessibilityIdentifier("activeLessonNumber")
                                Text("\(theme.title)陪你跟拍").font(.caption).foregroundStyle(BeatLabStyle.muted).accessibilityIdentifier("activeCompanion")
                            }
                            Spacer(minLength: 6)
                            Text("60 BPM").font(.subheadline.monospacedDigit())
                        }
                        phraseRoute
                        EggMissionScene(theme: theme, elapsed: practice.elapsed, accepted: route?.accepted ?? [],
                            presentationElapsed: { practice.presentationElapsed(at: $0) },
                            acceptedAction: route?.latestAccepted, latestAction: practice.latestHit, route: route, platformJourney: true)
                            .frame(height: max(200, geometry.size.height - 258))
                            .overlay(alignment: .topLeading) {
                                HStack(spacing: 6) {
                                    MissionProp(theme: theme, destination: false).frame(width: 22, height: 24)
                                    Text(theme.mission).font(.caption.bold())
                                }.padding(9).foregroundStyle(ink).background(.regularMaterial, in: Capsule()).padding(12)
                            }
                        Text(cue).font(.subheadline.bold()).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("jumpCue")
                    }
                }
                HStack {
                    Text("抵達 \(route?.accepted.count ?? 0) / \(route?.targets.count ?? 0) 座小島").accessibilityIdentifier("jumpMatches")
                    Spacer(minLength: 4)
                    Text(streak >= 2 ? "連續 \(streak) 拍！" : "右手跟拍")
                }.font(.caption.bold())
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(Color(uiColor: theme.pad))
                    Label("跟鼓聲跳", systemImage: "arrow.up.right").font(.headline.bold())
                        .foregroundStyle(ink).allowsHitTesting(false).accessibilityHidden(true)
                    TapPad(feedback: "跳，\(cue)") { time, accessible in practice.tap(at: time, accessibility: accessible) }
                }.frame(height: 56)
                Button(action: stop) { Label("停止挑戰", systemImage: "stop.fill").font(.subheadline).frame(maxWidth: .infinity, minHeight: 44) }
                    .accessibilityIdentifier("stopPractice")
            }.padding(.horizontal, 12).padding(.vertical, 6)
                .frame(maxWidth: BeatLabStyle.maxWidth).frame(maxWidth: .infinity)
        }
    }
    private var phraseRoute: some View {
        let current = route?.currentIndex(at: practice.elapsed)
        let bar = (current ?? 0) / 4
        return HStack(spacing: 8) {
            Text(current == nil ? "聽 4 拍" : "\(bar + 1)/4 小節").font(.caption.bold())
            Spacer(minLength: 2)
            ForEach(0..<4, id: \.self) { slot in
                let index = bar * 4 + slot
                let target = route.flatMap { $0.targets.indices.contains(index) ? $0.targets[index] : nil }
                let matched = target.flatMap { route?.grades[$0.id] } != nil
                let expired = target.map { _ in practice.elapsed > (route?.relativeTimes[index] ?? .infinity) + (route?.alignment ?? 0) + TimingSession.matchingWindow } ?? false
                Image(systemName: matched ? "checkmark.circle.fill" : expired ? "arrow.uturn.backward.circle" : "music.note")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(matched ? Color(uiColor: theme.accent) : expired ? Color.orange : BeatLabStyle.ink)
                    .frame(width: 40, height: 36)
                    .background(current == index ? Color(uiColor: theme.pad) : Color.clear, in: Circle())
                    .accessibilityHidden(true)
            }
        }.padding(.horizontal, 10).padding(.vertical, 3)
            .background(BeatLabStyle.surface, in: Capsule())
            .accessibilityElement(children: .ignore).accessibilityLabel("這一小節的四個拍點")
            .accessibilityValue(current.map { "第 \($0 % 4 + 1) 拍，右手；抵達 \(route?.accepted.count ?? 0) 座小島" } ?? "先聽四拍，再跟鼓聲跳")
            .accessibilityIdentifier("rhythmLane")
    }
}
