import SwiftUI
import UIKit
import SpriteKit
import BeatLabCore

/// Authored mission profiles only; other lessons and faster practice retain
/// their existing runner. This does not change catalog targets or unlock rules.
enum IslandLesson: Equatable {
    case first, alternating, eighth, eighthAlternating, quarterRest, eighthRest, sixteenth, sixteenthAlternating, offbeat, mixed
    var number: Int { switch self { case .first: return 1; case .alternating: return 2; case .eighth: return 3; case .eighthAlternating: return 4; case .quarterRest: return 5; case .eighthRest: return 6; case .sixteenth: return 7; case .sixteenthAlternating: return 8; case .offbeat: return 9; case .mixed: return 10 } }
    var bpm: Int { switch self { case .first,.eighth,.sixteenth: return 60; case .alternating,.eighthAlternating,.sixteenthAlternating: return 65; case .quarterRest,.eighthRest,.mixed: return 70; case .offbeat: return 75 } }
    var stepsPerBeat: Int { switch self { case .first,.alternating,.quarterRest: return 1; case .eighth,.eighthAlternating,.eighthRest,.offbeat: return 2; case .sixteenth,.sixteenthAlternating,.mixed: return 4 } }
    var pattern: [Stroke] {
        switch self {
        case .first: return [.right,.right,.right,.right]
        case .alternating: return [.right,.left,.right,.left]
        case .eighth: return Array(repeating:.right,count:8)
        case .eighthAlternating: return [.right,.left,.right,.left,.right,.left,.right,.left]
        case .quarterRest: return [.right,.rest,.right,.rest]
        case .eighthRest: return [.right,.left,.rest,.right,.rest,.left,.right,.rest]
        case .offbeat: return [.rest,.right,.rest,.left,.rest,.right,.rest,.left]
        case .sixteenth: return Array(repeating:.right,count:16)
        case .sixteenthAlternating: return (0..<16).map { $0%2 == 0 ? .right : .left }
        case .mixed: return [.right,.left,.rest,.right,.rest,.left,.right,.left,.rest,.right,.rest,.left,.right,.rest,.left,.rest]
        }
    }
    var usesBothHands: Bool { pattern.contains(.left) }
    var hasRests: Bool { pattern.contains(.rest) }
    var dense: Bool { stepsPerBeat > 1 }
    var title: String { switch self { case .first: return "節奏跨島"; case .alternating: return "左右接力跨島"; case .eighth: return "半拍小島"; case .eighthAlternating: return "半拍左右接力"; case .quarterRest: return "留白小島"; case .eighthRest: return "半拍與休息"; case .sixteenth: return "一拍四格"; case .sixteenthAlternating: return "四格左右接力"; case .offbeat: return "反拍跨島"; case .mixed: return "節奏小高手" } }
    var preparation: String { switch self { case .first: return "找到大拍"; case .alternating: return "左右輪流"; case .eighth: return "一拍兩下"; case .eighthAlternating: return "半拍左右輪流"; case .quarterRest: return "留白也是節奏"; case .eighthRest: return "八分與休止"; case .sixteenth: return "一拍四格"; case .sixteenthAlternating: return "十六分左右"; case .offbeat: return "反拍留白"; case .mixed: return "節奏小高手" } }
    var handInstruction: String { hasRests ? (usesBothHands ? "R 右手、L 左手；— 先聽拍" : "R 右手；— 先聽拍") : stepsPerBeat == 4 ? (usesBothHands ? "每拍右、左輪流四下" : "每拍用右手點四下") : dense ? (usesBothHands ? "每拍右、左各一下" : "每拍用右手點兩下") : (usesBothHands ? "右、左手輪流跟拍" : "用右手跟拍") }
    static func profile(_ lesson: Lesson) -> Self? {
        guard lesson.bars == 4 else { return nil }
        let profiles: [(String, Self)] = [("first-beat",.first),("quarter-hands",.alternating),("eighth",.eighth),("eighth-hands",.eighthAlternating),("quarter-rest",.quarterRest),("eighth-rest",.eighthRest),("sixteenth",.sixteenth),("sixteenth-hands",.sixteenthAlternating),("offbeat",.offbeat),("mixed",.mixed)]
        guard let profile = profiles.first(where: { $0.0 == lesson.id })?.1,
              lesson.bpm == profile.bpm, lesson.pattern.stepsPerBeat == profile.stepsPerBeat else { return nil }
        return lesson.pattern.steps == profile.pattern ? profile : nil
    }
}

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
    let grid: IslandRouteGrid?
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
        grid = IslandRouteGrid(targets: targets, epoch: epoch, endTime: endTime)
    }
    func currentIndex(at elapsed: Double) -> Int? {
        guard elapsed.isFinite else { return nil }
        // Absolute-host subtraction can put a fractional65BPM boundary a few
        // floating-point units ahead of its equivalent relative time.
        return relativeTimes.lastIndex { $0 <= elapsed + 1e-10 }
    }
    /// Musical cells include silence, while matcher targets contain notes only.
    func cellTarget(_ cell: Int) -> TimingTarget? { targets.first { $0.id == cell } }
    func isRest(at elapsed: Double) -> Bool {
        guard let cell = grid?.cellIndex(at: elapsed) else { return false }
        return cellTarget(cell) == nil
    }
    func countInRemaining(at elapsed: Double, stepsPerBeat: Int) -> Int? {
        guard let grid, elapsed.isFinite, elapsed >= 0, stepsPerBeat > 0,
              elapsed < grid.start - 1e-10,
              !journeyHits.contains(where: { $0.inputTime - epoch <= elapsed + 1e-10 }) else { return nil }
        return max(1,Int(ceil((grid.start-elapsed)/(grid.interval*Double(stepsPerBeat))-1e-10)))
    }
    /// Musical cue, independent of how many platforms the actor reached.
    /// A matched early press moves the prompt on; a miss cannot freeze R/L.
    func promptTarget(at elapsed: Double) -> TimingTarget? {
        guard elapsed.isFinite, elapsed >= 0, elapsed <= duration else { return nil }
        let played = Set(journeyHits.filter { $0.inputTime - epoch <= elapsed + 1e-10 }.compactMap(\.targetID))
        return targets.indices.first {
            !played.contains(targets[$0].id) && elapsed <= relativeTimes[$0] + alignment + TimingSession.matchingWindow + 1e-9
        }.map { targets[$0] }
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

/// Read-only grid validated against existing target IDs/times. Missing rest
/// cells are never synthesized as matcher targets. Invalid routes stay legacy.
struct IslandRouteGrid {
    let interval: Double
    let start: Double
    let steps: Int
    init?(targets: [TimingTarget], epoch: Double, endTime: Double) {
        guard targets.count >= 2, epoch.isFinite, endTime.isFinite,
              targets.allSatisfy({ $0.id >= 0 && $0.time.isFinite }),
              zip(targets, targets.dropFirst()).allSatisfy({ $0.id < $1.id }) else { return nil }
        let interval = (targets[1].time - targets[0].time) / Double(targets[1].id - targets[0].id)
        guard interval.isFinite, interval > 0 else { return nil }
        let start = targets[0].time - epoch - Double(targets[0].id) * interval
        let length = (endTime - epoch - TimingSession.matchingWindow - start) / interval
        guard start >= 0, length.isFinite, length >= 1, length <= 256,
              abs(length - length.rounded()) < 1e-6,
              targets.allSatisfy({ abs(($0.time - epoch) - (start + Double($0.id) * interval)) < 1e-6 }),
              targets.last!.id < Int(length.rounded()) else { return nil }
        self.interval = interval; self.start = start; steps = Int(length.rounded())
    }
    var isDense: Bool { interval < 0.60 }
    var flightDuration: Double { min(0.48, interval * 0.60) }
    func cellIndex(at elapsed: Double) -> Int? {
        guard elapsed.isFinite, elapsed >= start - 1e-10,
              elapsed <= start + Double(steps)*interval + TimingSession.matchingWindow + 1e-10 else { return nil }
        return min(steps-1,max(0,Int(floor((elapsed-start+1e-10)/interval))))
    }
}

/// Dense-only presentation: summing C2 accepted-input travel/arcs preserves
/// height and camera at another legal press. Input/judgment stays authoritative.
struct DenseJourneyFrame {
    let world: PlatformJourneyFrame
    let height: Double
    let poseAge: Double?
    let landing: Double
    let active: Bool
    static func sample(route: RunnerRoute?, elapsed: Double, reduced: Bool) -> Self? {
        guard let route, let grid = route.grid, grid.isDense else { return nil }
        guard elapsed.isFinite, (0...route.duration).contains(elapsed) else {
            return Self(world: .sample(route:nil,elapsed:0,reduced:true),height:0,poseAge:nil,landing:0,active:false)
        }
        let flight = grid.flightDuration, contact = min(0.10, grid.interval * 0.20)
        var step = 0.0, camera = 0.0, height = 0.0, weightedPhase = 0.0, landing = 0.0
        var latestAge: Double?
        for (index, hit) in route.journeyHits.enumerated() {
            let age = elapsed - (hit.inputTime - route.epoch)
            guard age >= 0 else { continue }
            latestAge = age
            let progress = reduced ? 1 : JourneyMotion.progress(age / flight)
            step += progress
            camera += (max(0, Double(index+1)-1.3) - max(0, Double(index)-1.3)) * progress
            if !reduced {
                let arc = JourneyMotion.arc(age / flight)
                height += arc; weightedPhase += arc * age / flight
                if (flight..<flight+contact).contains(age) { landing += pow(sin(.pi * (age-flight)/contact),2) }
            }
        }
        var recovery = JourneyRecovery.idle
        if !reduced {
            for index in route.targets.indices where !route.accepted.contains(route.targets[index].id) {
                let failure = route.relativeTimes[index] + route.alignment + TimingSession.matchingWindow
                var candidate = JourneyRecovery.sample(age: elapsed - failure)
                // A new accepted jump starts at zero; fade the existing fall
                // displacement instead of teleporting back to its platform.
                if let next = route.journeyHits.first(where: { $0.inputTime-route.epoch > failure && $0.inputTime-route.epoch <= elapsed }) {
                    let gain = 1-JourneyMotion.progress((elapsed-(next.inputTime-route.epoch))/min(0.10,flight))
                    candidate = JourneyRecovery(phase:candidate.phase,age:candidate.age,depth:candidate.depth*gain,drift:candidate.drift*gain,compression:candidate.compression*gain,pose:candidate.pose)
                }
                if candidate.depth > recovery.depth { recovery = candidate }
            }
        }
        let active = height > 1e-12
        let pose = active ? 0.48 * weightedPhase / height : latestAge.map { $0 < flight ? 0.48*$0/flight : $0 < flight+contact ? 0.48+0.16*($0-flight)/contact : 0.64+($0-flight-contact) }
        let world = PlatformJourneyFrame(step:step,camera:camera,jumpAge:pose,recovery:recovery)
        return Self(world:world,height:reduced ? 0 : tanh(height)/tanh(1),poseAge:pose,landing:reduced ? 0 : min(1,landing),active:active)
    }
    /// Reuse a fixed node pool, including the actual final island after16.
    static func platformIndex(slot: Int, camera: Double, total: Int) -> Int? {
        guard camera.isFinite, camera >= 0, total >= 0, slot >= 0 else { return nil }
        let index = max(0,Int(camera.rounded(.down))-2)+slot
        return index <= total ? index : nil
    }
}

/// Pure world motion from real accepted inputs. Never a collision or grade source.
struct PlatformJourneyFrame {
    let step: Double
    let camera: Double
    let jumpAge: Double?
    let recovery: JourneyRecovery
    var fall: Double { recovery.depth }
    static func sample(route: RunnerRoute?, elapsed: Double, reduced: Bool) -> Self {
        guard let route, elapsed.isFinite, elapsed >= 0 else {
            return Self(step: 0, camera: 0, jumpAge: nil, recovery: .idle)
        }
        var step = 0.0, camera = 0.0
        var age: Double?
        for (index, hit) in route.journeyHits.enumerated() {
            let a = elapsed - (hit.inputTime - route.epoch)
            guard a >= 0 else { continue }
            let progress = JourneyMotion.progress(a / 0.48)
            step += reduced ? 1 : progress
            let delta = max(0, Double(index + 1) - 1.3) - max(0, Double(index) - 1.3)
            camera += delta * (reduced ? 1 : progress)
            age = a
        }
        var recovery = JourneyRecovery.idle
        if !reduced, age.map({ $0 >= 0.64 }) ?? true,
           let index = route.targets.indices.last(where: {
               let a = elapsed - route.relativeTimes[$0] - route.alignment - TimingSession.matchingWindow
               return a > 1e-10 && a < 0.60 && !route.accepted.contains(route.targets[$0].id)
           }) {
            recovery = JourneyRecovery.sample(age: elapsed - route.relativeTimes[index] - route.alignment - TimingSession.matchingWindow)
        }
        return Self(step: step, camera: camera, jumpAge: age, recovery: recovery)
    }
}

/// A failed step is not a reversed jump. Descent gains speed, the catch brakes
/// it, then a visible carrier returns the actor. Read-only presentation at60BPM.
struct JourneyRecovery {
    enum Phase { case idle, falling, catching, returning }
    let phase: Phase
    let age: Double
    let depth: Double
    let drift: Double
    let compression: Double
    let pose: Int
    static let idle = Self(phase: .idle, age: 0, depth: 0, drift: 0, compression: 0, pose: 28)
    static func sample(age: Double) -> Self {
        guard age.isFinite, age > 0, age < 0.60 else { return .idle }
        if age < 0.24 {
            let p = age / 0.24
            return Self(phase: .falling, age: age, depth: 0.75 * p * p,
                        drift: 0.50 * JourneyMotion.progress(p), compression: 0,
                        pose: 18 + min(5, Int(age * 25)))
        }
        if age < 0.32 {
            let p = (age - 0.24) / 0.08
            return Self(phase: .catching, age: age, depth: 0.75 + 0.25 * (2 * p - p * p),
                        drift: 0.50, compression: sin(.pi * p),
                        pose: 24 + min(1, Int((age - 0.24) * 25)))
        }
        let progress = JourneyMotion.progress((age - 0.32) / 0.28)
        let pose = age < 0.36 ? 26 : (age < 0.40 ? 27 : 28)
        return Self(phase: .returning, age: age, depth: 1 - progress,
                    drift: 0.50 * (1 - progress), compression: 0, pose: pose)
    }
    var instruction: String? {
        switch phase {
        case .idle: return nil
        case .falling: return "沒跟上，準備接住！"
        case .catching: return "接住了，站穩一下！"
        case .returning: return "回到小島，聽下一拍！"
        }
    }
}

/// Endpoint-resting C2 travel curves. One opaque registered sprite remains.
/// These are presentation samples, never timing targets or input judgments.
enum JourneyMotion {
    static func progress(_ value: Double) -> Double {
        let p = value.isFinite ? min(1, max(0, value)) : 0
        return p * p * p * (10 + p * (-15 + 6 * p))
    }
    static func arc(_ value: Double) -> Double {
        guard value.isFinite, (0...1).contains(value) else { return 0 }
        return 64 * pow(value * (1 - value), 3)
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
                    .font(.system(textSize.isAccessibilitySize ? .caption : .subheadline, design: .rounded).bold())
                    .lineLimit(1)
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

/// Authored in-between poses; cadence is independent of display refresh and beats.
/// Missing art falls back to the preserved sparse pack, never to a blank player.
enum DenseCharacterAtlas {
    struct Pack {
        let textures: [SKTexture]
        let anchors: [CGPoint]
        let referenceHeight: CGFloat
        init(name: String, referenceHeight: CGFloat, anchors: [CGPoint]) {
            self.referenceHeight = referenceHeight; self.anchors = anchors
            guard referenceHeight > 0, anchors.count == 32, let image = UIImage(named: name)?.cgImage else { textures = []; return }
            textures = (0..<32).compactMap { index in
                let x0 = (Double(index % 8) * Double(image.width) / 8).rounded(.toNearestOrEven)
                let y0 = (Double(index / 8) * Double(image.height) / 4).rounded(.toNearestOrEven)
                let x1 = (Double(index % 8 + 1) * Double(image.width) / 8).rounded(.toNearestOrEven)
                let y1 = (Double(index / 8 + 1) * Double(image.height) / 4).rounded(.toNearestOrEven)
                guard let cell = image.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)) else { return nil }
                let texture = SKTexture(cgImage: cell); texture.filteringMode = .linear; return texture
            }
        }
        var isValid: Bool { textures.count == 32 && anchors.count == 32 && referenceHeight > 0 }
    }
    // Generated PNGs remain byte-identical; read-only alpha/head-mass registration.
    // Registered head/scale stays stable in flight; contact poses use actual foot baseline.
    static let packs: [RunnerTheme: Pack] = [
        .dinosaur: Pack(name: "DenseDinosaurMotion", referenceHeight: 189, anchors: [CGPoint(x: 121.4285, y: 205), CGPoint(x: 121.0003, y: 205), CGPoint(x: 120.6215, y: 205), CGPoint(x: 120.741, y: 205), CGPoint(x: 121.1707, y: 203), CGPoint(x: 120.6974, y: 204), CGPoint(x: 120.9337, y: 206), CGPoint(x: 120.6463, y: 205), CGPoint(x: 119.8498, y: 203), CGPoint(x: 120.0899, y: 203), CGPoint(x: 119.5937, y: 203), CGPoint(x: 120.3573, y: 203), CGPoint(x: 120.5284, y: 204), CGPoint(x: 119.9687, y: 203), CGPoint(x: 120.6517, y: 203), CGPoint(x: 120.1395, y: 203), CGPoint(x: 118.5186, y: 198), CGPoint(x: 119.137, y: 201), CGPoint(x: 118.4708, y: 202), CGPoint(x: 118.1722, y: 202), CGPoint(x: 120.1535, y: 202), CGPoint(x: 119.9798, y: 203), CGPoint(x: 120.5478, y: 204), CGPoint(x: 120.1491, y: 203), CGPoint(x: 120.048, y: 202), CGPoint(x: 120.4279, y: 203), CGPoint(x: 120.0393, y: 202), CGPoint(x: 120.3275, y: 201), CGPoint(x: 119.7939, y: 201), CGPoint(x: 119.5795, y: 201), CGPoint(x: 120.0733, y: 202), CGPoint(x: 119.4144, y: 202)]),
        .cat: Pack(name: "DenseCatMotion", referenceHeight: 194, anchors: [CGPoint(x: 118.9282, y: 212), CGPoint(x: 120.639, y: 212), CGPoint(x: 124.1791, y: 212), CGPoint(x: 125.8537, y: 212), CGPoint(x: 126.0232, y: 212), CGPoint(x: 123.3623, y: 211), CGPoint(x: 124.4837, y: 212), CGPoint(x: 122.2294, y: 212), CGPoint(x: 125.2264, y: 208), CGPoint(x: 121.5337, y: 208), CGPoint(x: 120.9444, y: 206), CGPoint(x: 121.7452, y: 206), CGPoint(x: 122.5345, y: 208), CGPoint(x: 122.2199, y: 207), CGPoint(x: 118.2766, y: 206), CGPoint(x: 117.8604, y: 207), CGPoint(x: 122.546, y: 205), CGPoint(x: 119.6753, y: 206), CGPoint(x: 117.9349, y: 201), CGPoint(x: 115.2497, y: 201), CGPoint(x: 121.0228, y: 208), CGPoint(x: 120.1415, y: 208), CGPoint(x: 120.7901, y: 206), CGPoint(x: 120.3608, y: 208), CGPoint(x: 116.6617, y: 203), CGPoint(x: 112.7894, y: 204), CGPoint(x: 120.3969, y: 203), CGPoint(x: 120.2308, y: 203), CGPoint(x: 117.5834, y: 203), CGPoint(x: 117.9329, y: 204), CGPoint(x: 119.34, y: 203), CGPoint(x: 116.8849, y: 203)]),
        .robot: Pack(name: "DenseRobotMotion", referenceHeight: 185, anchors: [CGPoint(x: 119.2793, y: 205), CGPoint(x: 120.8582, y: 205), CGPoint(x: 122.3635, y: 205), CGPoint(x: 123.4546, y: 205), CGPoint(x: 123.2228, y: 205), CGPoint(x: 121.7421, y: 205), CGPoint(x: 121.4395, y: 205), CGPoint(x: 121.2221, y: 205), CGPoint(x: 122.6622, y: 205), CGPoint(x: 120.8174, y: 205), CGPoint(x: 117.3791, y: 205), CGPoint(x: 117.277, y: 205), CGPoint(x: 123.369, y: 205), CGPoint(x: 124.1673, y: 205), CGPoint(x: 126.7748, y: 205), CGPoint(x: 125.0228, y: 205), CGPoint(x: 124.3694, y: 202), CGPoint(x: 124.1064, y: 204), CGPoint(x: 128.22, y: 203), CGPoint(x: 126.727, y: 203), CGPoint(x: 125.337, y: 203), CGPoint(x: 126.7635, y: 203), CGPoint(x: 128.3564, y: 203), CGPoint(x: 127.9103, y: 202), CGPoint(x: 126.6102, y: 192), CGPoint(x: 122.1243, y: 194), CGPoint(x: 118.2486, y: 195), CGPoint(x: 114.1323, y: 196), CGPoint(x: 114.3311, y: 199), CGPoint(x: 114.0865, y: 199), CGPoint(x: 113.8978, y: 199), CGPoint(x: 116.5594, y: 199)])
    ]
}

/// Facial response reads the accepted recovery; it never changes body motion or judgment.
enum RecoveryExpression: String {
    case neutral, surprised, braced, relieved, ready
    static func sample(_ recovery: JourneyRecovery, reduced: Bool = false) -> Self {
        guard !reduced else { return .neutral }
        switch recovery.phase {
        case .idle: return .neutral
        case .falling: return .surprised
        case .catching: return .braced
        case .returning: return recovery.age < 0.40 ? .relieved : .ready
        }
    }
}

/// Original body pixels remain the primary texture. Only an inset face region
/// reads the sibling expression atlas; missing art leaves the original intact.
enum RecoveryExpressionAtlas {
    struct Pack {
        let textures: [SKTexture]
        let shaders: [SKShader]
        init(name: String, face: SIMD4<Float>) {
            guard let image = UIImage(named: name)?.cgImage else { textures = []; shaders = []; return }
            textures = (0..<32).compactMap { index in
                let x0 = (Double(index % 8) * Double(image.width) / 8).rounded(.toNearestOrEven)
                let y0 = (Double(index / 8) * Double(image.height) / 4).rounded(.toNearestOrEven)
                let x1 = (Double(index % 8 + 1) * Double(image.width) / 8).rounded(.toNearestOrEven)
                let y1 = (Double(index / 8 + 1) * Double(image.height) / 4).rounded(.toNearestOrEven)
                guard let cell = image.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)) else { return nil }
                let texture = SKTexture(cgImage: cell); texture.filteringMode = .linear; return texture
            }
            shaders = textures.map { texture in
                SKShader(source: """
                void main() {
                    vec2 uv = v_tex_coord;
                    vec4 base = texture2D(u_texture, uv);
                    vec4 face = texture2D(u_expression, uv);
                    vec2 lo = smoothstep(u_faceRect.xy, u_faceRect.xy + vec2(0.025), uv);
                    vec2 hi = 1.0 - smoothstep(u_faceRect.zw - vec2(0.025), u_faceRect.zw, uv);
                    float mask = lo.x * lo.y * hi.x * hi.y * face.a;
                    gl_FragColor = vec4(mix(base.rgb, face.rgb, mask), base.a) * v_color_mix;
                }
                """, uniforms: [SKUniform(name: "u_expression", texture: texture),
                                SKUniform(name: "u_faceRect", vectorFloat4: face)])
            }
        }
        var isValid: Bool { textures.count == 32 && shaders.count == 32 }
    }
    static let packs: [RunnerTheme: Pack] = [
        .dinosaur: Pack(name: "RecoveryDinosaurExpressions", face: SIMD4(0.49, 0.42, 0.92, 0.80)),
        .cat: Pack(name: "RecoveryCatExpressions", face: SIMD4(0.51, 0.44, 0.92, 0.76)),
        .robot: Pack(name: "RecoveryRobotExpressions", face: SIMD4(0.43, 0.54, 0.75, 0.79))
    ]
    static func shader(theme: RunnerTheme, pose: Int) -> SKShader? {
        guard (18...28).contains(pose), DenseCharacterAtlas.packs[theme]?.isValid == true,
              let pack = packs[theme], pack.isValid else { return nil }
        return pack.shaders[pose]
    }
}

/// Grounded follow-through samples actual note/input times, never creates a hit.
/// Base art stays registered; only the upper body breathes/anticipates a cue.
struct JourneyIdleMotion {
    enum Phase { case inactive, waiting, anticipating, releasing }
    let phase: Phase
    let breath: Double
    let sway: Double
    let detail: Double
    let charge: Double
    static let inactive = Self(phase: .inactive, breath: 0, sway: 0, detail: 0, charge: 0)

    static func sample(route: RunnerRoute?, elapsed: Double, frame: PlatformJourneyFrame,
                       theme: RunnerTheme, reduced: Bool, stopped: Bool) -> Self {
        guard let route, !reduced, !stopped, elapsed.isFinite, (0...route.duration).contains(elapsed),
              frame.recovery.phase == .idle, let first = route.relativeTimes.first,
              elapsed >= first - 0.36, route.beatDuration.isFinite, route.beatDuration > 0 else { return .inactive }
        var time = elapsed
        var gain = 1.0
        var releasing = false
        if let age = frame.jumpAge {
            guard age.isFinite, age >= 0 else { return .inactive }
            if age < 0.10 {
                // Preserve the pose at the actual press, then release it gently.
                // No pending animation delays an early/late accepted takeoff.
                time -= age
                gain = 1 - JourneyMotion.progress(age / 0.10)
                releasing = true
            } else if age < 0.64 { return .inactive }
            else { gain = JourneyMotion.progress((age - 0.64) / 0.08) }
        } else { gain = JourneyMotion.progress((time - first + 0.36) / 0.08) }

        // Future fixture hits must not hide their upcoming cue. A hit exactly at
        // sample time is deliberately excluded when reconstructing pre-press pose.
        let prior = Set(route.journeyHits.filter { $0.inputTime - route.epoch < time - 1e-9 }.compactMap(\.targetID))
        if let missed = route.targets.indices.last(where: {
            !prior.contains(route.targets[$0].id) && time - route.relativeTimes[$0] - route.alignment - TimingSession.matchingWindow >= 0.60
        }) {
            let recoveredAge = time - route.relativeTimes[missed] - route.alignment - TimingSession.matchingWindow
            gain *= JourneyMotion.progress((recoveredAge - 0.60) / 0.08)
        }
        let next = route.targets.indices.first {
            !prior.contains(route.targets[$0].id) && route.relativeTimes[$0] >= time - TimingSession.matchingWindow - 1e-9
        }
        var charge = 0.0
        if let next {
            let delta = route.relativeTimes[next] - time
            if delta >= 0 { charge = JourneyMotion.progress(1 - delta / 0.24) }
            else {
                charge = 1 - JourneyMotion.progress(-delta / TimingSession.matchingWindow)
                // Return to neutral before a real miss switches to falling art.
                gain *= 1 - JourneyMotion.progress((-delta - 0.10) / 0.08)
            }
        }
        let angle = 2 * Double.pi * (time - first) / route.beatDuration
        return Self(phase: releasing ? .releasing : charge > 0 ? .anticipating : .waiting,
                    breath: sin(angle) * gain,
                    sway: sin(angle * (theme == .robot ? 1 : 0.5)) * gain,
                    detail: sin(angle * (theme == .cat ? 2 : 1)) * gain,
                    charge: charge * gain)
    }
}

/// Scene-local uniforms: two views cannot change one another's actor. A single
/// texture is deformed, never cross-faded into a second silhouette. The lower
/// 28% is unchanged so waiting/charging does not slide the planted feet.
private struct JourneyGroundedRig {
    let breath = SKUniform(name: "u_breath", float: 0)
    let sway = SKUniform(name: "u_sway", float: 0)
    let detail = SKUniform(name: "u_detail", float: 0)
    let charge = SKUniform(name: "u_charge", float: 0)
    let shader: SKShader
    init(theme: RunnerTheme) {
        shader = SKShader(source: """
        void main() {
            vec2 uv = v_tex_coord;
            float upper = smoothstep(0.28, 0.72, uv.y);
            float mechanical = step(1.5, u_style);
            float feline = step(0.5, u_style) * (1.0 - mechanical);
            uv.y += upper * (u_charge * mix(0.045, 0.025, mechanical)
                          - u_breath * mix(0.016, 0.008, mechanical));
            uv.x -= upper * u_sway * mix(0.012, 0.004, mechanical);
            float tail = (1.0 - smoothstep(0.27, 0.47, v_tex_coord.x))
                       * smoothstep(0.28, 0.40, v_tex_coord.y)
                       * (1.0 - smoothstep(0.68, 0.78, v_tex_coord.y));
            uv.y -= tail * u_detail * mix(0.036, 0.045, feline) * (1.0 - mechanical);
            float tips = smoothstep(0.80, 0.93, v_tex_coord.y);
            uv.x -= tips * u_detail * (mechanical * 0.014 + feline * 0.007);
            vec4 body = texture2D(u_texture, uv);
            gl_FragColor = body * v_color_mix;
        }
        """, uniforms: [breath, sway, detail, charge,
                         SKUniform(name: "u_style", float: theme == .robot ? 2 : theme == .cat ? 1 : 0)])
    }
    func apply(_ value: JourneyIdleMotion) {
        breath.floatValue = Float(value.breath); sway.floatValue = Float(value.sway)
        detail.floatValue = Float(value.detail); charge.floatValue = Float(value.charge)
    }
}

enum DenseAnimationFrame {
    static let ready = 28
    static func sample(elapsed: Double, age: Double?, reduceMotion: Bool, stationary: Bool) -> Int {
        guard !reduceMotion, elapsed.isFinite, (0...20.18).contains(elapsed) else { return ready }
        if let age, age.isFinite, (0..<0.48).contains(age) { return 12 + min(11, Int(age * 25)) }
        if let age, age.isFinite, (0.48..<0.64).contains(age) { return 24 + min(3, Int((age - 0.48) * 25)) }
        guard elapsed >= 4 else { return ready }
        guard !stationary else { return ready }
        return Int(((elapsed - 4) * 24).truncatingRemainder(dividingBy: 12))
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
    static func markerAlpha(route: RunnerRoute?, elapsed: Double, reduceMotion: Bool) -> CGFloat {
        guard !reduceMotion, let route, let index = route.currentIndex(at: elapsed),
              elapsed < route.duration - TimingSession.matchingWindow else { return 0.45 }
        let age = max(0, elapsed - route.relativeTimes[index])
        return 0.45 + 0.55 * CGFloat(max(0, 1 - age / 0.12))
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
    private static var warmedThemes = Set<RunnerTheme>()
    static func warm(_ theme: RunnerTheme) {
        guard warmedThemes.insert(theme).inserted else { return }
        let poses = theme == .dinosaur ? animated + original : CompanionAtlas.pack(theme).textures
        let backdrops = [journeyBackdrops[theme], CompanionAtlas.background(theme)].compactMap { $0 }
        SKTexture.preload(poses + (DenseCharacterAtlas.packs[theme]?.textures ?? []) + (RecoveryExpressionAtlas.packs[theme]?.textures ?? []) + backdrops, withCompletionHandler: {})
    }
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
    private var groundedRig = JourneyGroundedRig(theme: .dinosaur)
    #if DEBUG
    private(set) var callbackCount = 0
    private(set) var renderCount = 0
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
        // A shallow cradle with raised ends makes contact readable, rather
        // than a glow following a standing character through the water.
        let cradle = CGMutablePath()
        cradle.move(to: CGPoint(x: -48, y: 9))
        cradle.addQuadCurve(to: CGPoint(x: 48, y: 9), control: CGPoint(x: 0, y: -21))
        cradle.addLine(to: CGPoint(x: 43, y: 14))
        cradle.addQuadCurve(to: CGPoint(x: -43, y: 14), control: CGPoint(x: 0, y: 1))
        cradle.closeSubpath(); safety.path = cradle
        safety.name = "safetyCatch"; safety.lineWidth = 2; safety.zPosition = 5
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
        applyTheme(theme)
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
        let wasAnimating = snapshot.animate
        let themeChanged = theme != state.theme
        if themeChanged { applyTheme(state.theme) }
        snapshot = state
        #if DEBUG
        if !state.animate { previousHost = nil }
        #endif
        // One display callback owns live drawing. SwiftUI publishes elapsed
        // around33Hz; it must not introduce a second render loop between frames.
        if !state.animate || !wasAnimating || themeChanged { render(at: PracticeStore.now()) }
        if view?.isPaused != !state.animate { view?.isPaused = !state.animate }
    }
    private func applyTheme(_ next: RunnerTheme) {
        theme = next
        groundedRig = JourneyGroundedRig(theme: next)
        EggSceneTextures.warm(next)
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
        for top in platformTops { top.fillColor = next.accent }
        safety.fillColor = next.pad; safety.strokeColor = next.accent
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
        #if DEBUG
        renderCount += 1
        #endif
        let raw = snapshot.presentationElapsed?(host) ?? snapshot.elapsed
        let limit = snapshot.platformJourney ? snapshot.route?.duration ?? 20.18 : 20.18
        let elapsed = raw.isFinite ? min(limit, max(0, raw)) : 0
        if snapshot.platformJourney { renderJourney(elapsed: elapsed, host: host); return }
        first.alpha = 1
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
        if first.shader != nil { first.shader = nil }
        first.color = .white; first.colorBlendFactor = recovery
        if let passed = snapshot.finishedPassed { setOriginal(first, passed ? 5 : 4) }
        else {
            setMotion(first, elapsed: snapshot.preparing ? 0 : elapsed, age: age, reduced: reduced, stationary: false)
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
        let dense = DenseJourneyFrame.sample(route: route, elapsed: snapshot.preparing ? 0 : elapsed, reduced: reduced)
        let state = dense?.world ?? PlatformJourneyFrame.sample(route: route, elapsed: snapshot.preparing ? 0 : elapsed, reduced: reduced)
        let stopped = snapshot.preparing || snapshot.finishedPassed != nil
        let w = size.width, h = size.height, stride = w * 0.27, ground = h * 0.31
        let completed = snapshot.finishedPassed == true
        let total = route?.targets.count ?? 16
        let step = completed ? Double(total) : state.step, camera = completed ? max(0,Double(total)-1.3) : state.camera
        let origin = w * 0.20 - CGFloat(camera) * stride
        let activeFlight = !stopped && (dense?.active ?? (state.jumpAge.map { (0..<0.48).contains($0) } == true))
        let age = state.jumpAge ?? 1
        // Two valid four-grid presses can share an arc apex. Reserve headroom
        // for the registered sprite's rotation, scaling the whole trajectory.
        let highDensity = route?.grid.map { $0.interval < 0.30 } == true
        let hop = activeFlight && !reduced ? CGFloat(dense?.height ?? JourneyMotion.arc(age / 0.48)) * min(78, h * (dense == nil ? 0.20 : highDensity ? 0.14 : 0.16)) : 0
        let recovery = stopped ? JourneyRecovery.idle : state.recovery
        let fall = CGFloat(recovery.depth)
        let extraAge = route?.hits.last.flatMap { $0.grade == .extra ? elapsed - ($0.inputTime - (route?.epoch ?? 0)) : nil }
        let extra = !stopped && !reduced && !activeFlight && recovery.phase == .idle && age >= 0.64 && extraAge.map { (0..<0.22).contains($0) } == true ? CGFloat(sin(.pi * extraAge! / 0.22)) : 0
        let x = origin + CGFloat(step) * stride + CGFloat(recovery.drift) * stride + extra * 3
        let y = ground + hop - fall * min(64, h * 0.18)
        characterSize = min(132, max(90, h * 0.27))
        let backdrop = EggSceneTextures.journeyBackdrops[theme]
        if island.texture !== backdrop { island.texture = backdrop }
        let source = backdrop?.size() ?? CGSize(width: 2, height: 1)
        let scale = max((w + 24) / max(1, source.width), h / max(1, source.height))
        island.size = CGSize(width: source.width * scale, height: source.height * scale)
        let parallax = CGFloat(camera) * 1.5
        let coveredParallax = dense == nil ? parallax : min(parallax,max(0,(island.size.width-w)/2))
        island.position = CGPoint(x: (w - island.size.width) / 2 - coveredParallax, y: (h - island.size.height) / 2)
        floor.isHidden = true; edge.isHidden = true
        rocks.forEach { $0.isHidden = true }; rewards.forEach { $0.isHidden = true }
        pebbles.forEach { $0.isHidden = true }
        for slot in platforms.indices {
            let index = dense == nil ? slot : DenseJourneyFrame.platformIndex(slot:slot,camera:camera,total:total) ?? total+1
            let px = origin + CGFloat(index) * stride
            let visible = index <= total && px > -w * 0.2 && px < w * 1.2
            let platform = platforms[slot], top = platformTops[slot]
            platform.isHidden = !visible; top.isHidden = !visible
            let texture = theme == .dinosaur ? EggSceneTextures.original[8] : CompanionAtlas.pack(theme).textures[20]
            if platform.texture !== texture { platform.texture = texture }
            platform.size = CGSize(width: w * 0.19, height: min(72, w * 0.18))
            platform.position = CGPoint(x: px, y: ground - 4)
            platform.alpha = 1
            top.position = CGPoint(x: px, y: ground - 3); top.xScale = w * 0.19 / 72
            let landed = index > 0 && index <= Int((step + 1e-8).rounded(.down))
            if landed && (dense != nil ? slot < rewards.count : index <= rewards.count) {
                let reward = rewards[dense != nil ? slot : index - 1]
                reward.isHidden = !visible; reward.position = CGPoint(x: px, y: ground - 26)
                reward.setScale(0.5)
            }
        }
        let next = min(total, Int((step + 1e-8).rounded(.down)) + 1)
        let landingX = origin + CGFloat(next) * stride
        beatMarker.zPosition = recovery.phase == .idle ? 8 : 4
        beatMarker.isHidden = completed || snapshot.finishedPassed == false
        beatMarker.position = CGPoint(x: landingX, y: ground + 1)
        beatMarker.alpha = EggBeatLane.markerAlpha(route: route, elapsed: elapsed, reduceMotion: reduced)
        nextBeat.isHidden = stopped || route == nil || activeFlight
        nextBeat.position = CGPoint(x: landingX, y: ground + 36)
        nextBeat.fontColor = theme.accent
        let alternating = route?.targets.contains { $0.stroke == .left } == true
        let waiting = route?.isRest(at:elapsed) == true
        let prompt = waiting ? "—" : alternating ? route?.promptTarget(at: elapsed).map { $0.stroke == .right ? "R" : "L" } ?? "" : "♪"
        if nextBeat.text != prompt { nextBeat.text = prompt }
        // Hand instruction remains readable; only the landing marker pulses.
        nextBeat.alpha = waiting || alternating || reduced ? 1 : beatMarker.alpha
        let endX = origin + CGFloat(total) * stride
        nest.isHidden = endX > w + 60; nest.position = CGPoint(x: endX, y: ground)
        shadow.position = CGPoint(x: x, y: ground + 1)
        shadow.xScale = 0.75 - hop / 300; shadow.alpha = (0.20 - hop / 600) * max(0, 1 - fall * 2)
        player.position = CGPoint(x: x, y: y)
        player.zRotation = reduced ? 0 : (-recovery.drift * 0.36 - (activeFlight ? JourneyMotion.arc(age / 0.48) * 0.05 : 0)) * Double(theme.lean)
        let landing = !stopped && !reduced ? CGFloat(dense?.landing ?? ((0.48..<0.64).contains(age) ? pow(sin(.pi * (age - 0.48) / 0.16), 2) : 0)) : 0
        let contact = max(landing, CGFloat(recovery.compression))
        player.xScale = 1 + contact * 0.08 * theme.compression
        player.yScale = 1 - contact * 0.10 * theme.compression
        let faceShader = !stopped && RecoveryExpression.sample(recovery, reduced: reduced) != .neutral
            ? RecoveryExpressionAtlas.shader(theme: theme, pose: recovery.pose) : nil
        let idle = JourneyIdleMotion.sample(route: route, elapsed: elapsed, frame: state, theme: theme,
                                           reduced: reduced, stopped: stopped)
        groundedRig.apply(idle)
        let idleShader = idle.phase != .inactive && DenseCharacterAtlas.packs[theme]?.isValid == true ? groundedRig.shader : nil
        let shader = faceShader ?? idleShader
        if first.shader !== shader { first.shader = shader }
        first.color = .white; first.colorBlendFactor = 0; first.alpha = 1
        if let passed = snapshot.finishedPassed { setOriginal(first, passed ? 5 : 4) }
        else if recovery.phase != .idle {
            setRecoveryPose(first, recovery.pose)
        }
        else { setMotion(first, elapsed: snapshot.preparing ? 0 : elapsed, age: stopped ? nil : age, reduced: reduced, stationary: true) }
        safety.isHidden = recovery.phase == .idle
        let catchX = recovery.phase == .falling ? origin + CGFloat(step + 0.50) * stride : x
        let catchDepth = recovery.phase == .falling ? 0.75 : recovery.depth
        safety.position = CGPoint(x: catchX, y: ground - CGFloat(catchDepth) * min(64, h * 0.18) - 6)
        safety.alpha = CGFloat(JourneyMotion.progress(recovery.age / 0.08) * (1 - JourneyMotion.progress((recovery.age - 0.54) / 0.06)))
        safety.xScale = 1 + CGFloat(recovery.compression) * 0.12
        safety.yScale = 1 - CGFloat(recovery.compression) * 0.25
        for (index, puff) in dust.enumerated() {
            puff.alpha = landing * 0.6; puff.xScale = 1 + landing
            puff.position = CGPoint(x: x - 18 - CGFloat(index) * 12, y: ground + CGFloat(index) * 3)
        }
        let latest = route?.journeyHits.last
        glint.isHidden = latest?.grade != .perfect || !activeFlight
        glint.position = CGPoint(x: x + 36, y: y + characterSize - 20)
    }
    private func setMotion(_ node: SKSpriteNode, elapsed: Double, age: Double?, reduced: Bool, stationary: Bool) {
        guard let pack = DenseCharacterAtlas.packs[theme], pack.isValid else {
            let fallback = stationary && !(age.map { (0..<0.64).contains($0) } ?? false) ? 14 : EggAnimationFrame.sample(elapsed: elapsed, age: age, reduceMotion: reduced)
            setAnimated(node, fallback)
            return
        }
        let index = DenseAnimationFrame.sample(elapsed: elapsed, age: age, reduceMotion: reduced, stationary: stationary)
        setDense(node, index: index, pack: pack)
    }
    private func setRecoveryPose(_ node: SKSpriteNode, _ index: Int) {
        guard let pack = DenseCharacterAtlas.packs[theme], pack.isValid else {
            setAnimated(node, index < 24 ? 13 : 15); return
        }
        setDense(node, index: index, pack: pack)
    }
    private func setDense(_ node: SKSpriteNode, index: Int, pack: DenseCharacterAtlas.Pack) {
        let texture = pack.textures[index], source = texture.size(), anchor = pack.anchors[index]
        if node.texture !== texture { node.texture = texture }
        node.anchorPoint = CGPoint(x: anchor.x / source.width, y: 1 - anchor.y / source.height)
        node.size = CGSize(width: source.width * characterSize / pack.referenceHeight, height: source.height * characterSize / pack.referenceHeight)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo:.caption) private var cueLineHeight: CGFloat = 18
    @ScaledMetric(relativeTo:.subheadline) private var cueBodyHeight: CGFloat = 44
    let accepted: Set<Int>
    let streak: Int
    let stop: () -> Void
    var theme: RunnerTheme = .dinosaur
    private var route: RunnerRoute? { practice.runnerRoute }
    private var profile: IslandLesson { practice.selected.flatMap(IslandLesson.profile) ?? .first }
    private var resting: Bool { route?.isRest(at:practice.elapsed) == true }
    private var promptStroke: Stroke? { resting ? nil : route?.promptTarget(at: practice.elapsed)?.stroke }
    private let ink = Color(red: 0.08, green: 0.25, blue: 0.18)
    private var age: Double? { practice.latestHit.map { max(0, PracticeStore.now() - $0.inputTime) } }
    private var cue: String {
        guard let route else { return "準備拍點，馬上開始…" }
        if let remaining = route.countInRemaining(at:practice.elapsed,stepsPerBeat:profile.stepsPerBeat), practice.latestHit == nil { return "先聽 \(remaining) 拍，準備跳" }
        if let age, age < 0.48, let grade = practice.latestHit?.grade {
            switch grade {
            case .perfect: return "漂亮！\(theme.item)亮起來了"
            case .early: return "跳過了，下一拍稍等一下"
            case .late: return "跳過了，下一拍早一點"
            case .extra: return "多打一下，再跟上"
            }
        }
        let recovery = (DenseJourneyFrame.sample(route:route,elapsed:practice.elapsed,reduced:false)?.world ?? PlatformJourneyFrame.sample(route: route, elapsed: practice.elapsed, reduced: false)).recovery
        if reduceMotion, recovery.phase != .idle { return "沒跟上，聽下一拍再試！" }
        if let instruction = recovery.instruction { return instruction }
        if resting { return "休息這格，先聽拍；有音符再跳！" }
        return "跟鼓聲，跳到亮起的小島！"
    }
    /// Brief large-text action, with the full instruction retained for speech.
    private var compactCue: String {
        if cue.hasPrefix("先聽") {return cue.components(separatedBy:"，").first ?? cue}
        if cue.hasPrefix("漂亮") {return "漂亮，再跟拍！"}
        if cue.hasPrefix("跳過了，下一拍稍") {return "下一拍慢一點"}
        if cue.hasPrefix("跳過了，下一拍早") {return "下一拍早一點"}
        if cue.hasPrefix("多打") {return "多一下，先聽拍"}
        if cue.hasPrefix("沒跟上") {return "接住你，別急"}
        if cue.hasPrefix("接住了") {return "站穩，聽下一拍"}
        if cue.hasPrefix("回到") {return "回來了，再跟拍"}
        if cue.hasPrefix("休息") {return "休息，先聽拍"}
        return "跟鼓聲跳！"
    }
    var body: some View {
        GeometryReader { geometry in
            let compact = textSize.isAccessibilitySize
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(compact ? "第 \(profile.number) 關" : "第 \(profile.number) 關 · \(profile.title)")
                            .font(compact ? .caption.bold() : .headline).lineLimit(compact ? 1 : 2)
                            .accessibilityLabel("第 \(profile.number) 關 · \(profile.title)")
                            .accessibilityValue("\(theme.title)陪你跟拍")
                            .accessibilityIdentifier("activeLessonNumber")
                        if !compact {
                            Text("\(theme.title)陪你跟拍").font(.caption).foregroundStyle(BeatLabStyle.muted)
                                .accessibilityIdentifier("activeCompanion")
                        }
                    }
                    Spacer(minLength: 6)
                    Text("\(practice.selected?.bpm ?? profile.bpm) BPM").font((compact ? Font.caption : Font.subheadline).monospacedDigit()).lineLimit(1)
                }
                phraseRoute
                EggMissionScene(theme: theme, elapsed: practice.elapsed, accepted: route?.accepted ?? [],
                    presentationElapsed: { practice.presentationElapsed(at: $0) },
                    acceptedAction: route?.latestAccepted, latestAction: practice.latestHit, route: route, platformJourney: true)
                    .frame(maxWidth:.infinity,minHeight:200,maxHeight:.infinity)
                    .layoutPriority(1)
                    .overlay(alignment: .topLeading) {
                        if !compact {
                            HStack(spacing: 6) {
                                MissionProp(theme: theme, destination: false).frame(width: 22, height: 24)
                                Text(theme.mission).font(.caption.bold())
                            }.padding(9).foregroundStyle(ink)
                                .background(Color(red:1,green:0.98,blue:0.88),in:Capsule()).padding(12)
                        }
                    }
                Text(compact ? compactCue : cue).font(compact ? .caption.bold() : .subheadline.bold())
                    .multilineTextAlignment(.center).lineLimit(compact ? 1 : 2)
                    .frame(height:compact ? cueLineHeight : cueBodyHeight)
                    .accessibilityLabel(cue).accessibilityIdentifier("jumpCue")
                HStack {
                    Text(compact ? "\(route?.accepted.count ?? 0) / \(route?.targets.count ?? 0) 座" : "抵達 \(route?.accepted.count ?? 0) / \(route?.targets.count ?? 0) 座小島")
                        .accessibilityLabel("抵達 \(route?.accepted.count ?? 0) / \(route?.targets.count ?? 0) 座小島")
                        .accessibilityIdentifier("jumpMatches")
                    if !compact {
                        Spacer(minLength:4)
                        Text(streak >= 2 ? "連續 \(streak) 拍！" : profile.usesBothHands ? "右左接力" : "右手跟拍")
                    }
                }.font(.caption.bold()).lineLimit(1)
                if profile.usesBothHands {
                    HStack(spacing:10) {handPad(.right);handPad(.left)}.frame(height:56)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius:20).fill(Color(uiColor:theme.pad))
                        Label(resting ? "休息，先聽拍" : "跟鼓聲跳",systemImage:resting ? "pause.fill" : "arrow.up.right").font(.headline.bold())
                            .foregroundStyle(ink).allowsHitTesting(false).accessibilityHidden(true)
                        TapPad(feedback:"跳，\(cue)") {time,accessible in practice.tap(at:time,accessibility:accessible)}
                    }.frame(height:56)
                }
                Button(action:stop) {
                    Label("停止挑戰",systemImage:"stop.fill").font(.subheadline).lineLimit(1)
                        .frame(maxWidth:.infinity,minHeight:44)
                }.accessibilityIdentifier("stopPractice")
            }.padding(.horizontal,12).padding(.vertical,6)
                .frame(maxWidth:BeatLabStyle.maxWidth).frame(maxWidth:.infinity,maxHeight:geometry.size.height)
        }
    }
    private func handPad(_ stroke: Stroke) -> some View {
        let right = stroke == .right
        let active = promptStroke == stroke
        return ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color(uiColor: theme.pad).opacity(active ? 1 : 0.55))
            RoundedRectangle(cornerRadius: 20).strokeBorder(active ? ink : Color.clear, lineWidth: 3)
            Text(resting ? (right ? "右手 R 等" : "左手 L 等") : (right ? "右手 R ↗" : "左手 L ↗")).font(.headline.bold()).lineLimit(1).minimumScaleFactor(0.6)
                .foregroundStyle(ink).allowsHitTesting(false).accessibilityHidden(true)
            TapPad(feedback: "\(active ? "下一拍" : "準備接力")，\(cue)",
                   label: right ? "右手鼓墊" : "左手鼓墊",
                   identifier: right ? "practiceTapPad.right" : "practiceTapPad.left") {
                time, accessible in practice.tap(at: time, accessibility: accessible)
            }
        }.frame(maxWidth: .infinity)
    }
    private var phraseRoute: some View {
        let current = route?.grid?.cellIndex(at: practice.elapsed)
        let perBeat = profile.stepsPerBeat, perBar = perBeat * 4
        let bar = (current ?? 0) / perBar
        let compact = textSize.isAccessibilitySize
        return HStack(spacing: 8) {
            Text(current == nil ? (compact ? "4拍" : "聽 4 拍") : (compact ? "\(bar + 1)/4" : "\(bar + 1)/4 小節"))
                .font(.caption.bold()).lineLimit(1)
            Spacer(minLength: 2)
            ForEach(0..<4, id: \.self) { beat in
                HStack(spacing: perBeat == 4 ? 1 : 2) {
                    ForEach(0..<perBeat, id: \.self) { subdivision in
                        let index = bar * perBar + beat * perBeat + subdivision
                        let target = route?.cellTarget(index)
                        let matched = target.flatMap { route?.grades[$0.id] } != nil
                        let expired = target.map { practice.elapsed > $0.time - (route?.epoch ?? 0) + (route?.alignment ?? 0) + TimingSession.matchingWindow } ?? false
                        VStack(spacing: 0) {
                            Image(systemName: target == nil && route != nil ? "minus" : matched ? "checkmark.circle.fill" : expired ? "arrow.uturn.backward.circle" : "music.note")
                                .font(.system(size: perBeat == 1 ? 23 : perBeat == 4 ? 11 : 15, weight: .bold))
                                .foregroundStyle(target == nil && route != nil ? BeatLabStyle.muted : matched ? Color(uiColor: theme.accent) : expired ? Color.orange : BeatLabStyle.ink)
                            if profile.usesBothHands { Text(target == nil && route != nil ? "—" : target?.stroke == .left ? "L" : "R").font(.system(size:compact ? 16 : 13,weight:.bold)) }
                        }.frame(width: perBeat == 1 ? (compact ? 32 : 40) : perBeat == 4 ? (compact ? 12 : 14) : (compact ? 18 : 21),height:36)
                            .background(current == index ? Color(uiColor:theme.pad) : Color.clear,in:Capsule())
                    }
                }.accessibilityHidden(true)
            }
        }.padding(.horizontal,10).padding(.vertical,3)
            .background(BeatLabStyle.surface,in:Capsule())
            .accessibilityElement(children:.ignore).accessibilityLabel(profile.stepsPerBeat == 4 ? "每拍四格的四個拍點" : profile.dense ? "每拍兩下的四個拍點" : "這一小節的四個拍點")
            .accessibilityValue(current.map { "第 \($0 / perBeat % 4 + 1) 拍，第 \($0 % perBeat + 1) 格，\(route?.cellTarget($0).map { $0.stroke == .left ? "左手" : "右手" } ?? "休息")；抵達 \(route?.accepted.count ?? 0) 座小島" } ?? "先聽四拍，再跟鼓聲跳")
            .accessibilityIdentifier("rhythmLane")
    }
}
