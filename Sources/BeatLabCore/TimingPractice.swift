import Foundation

public struct TimingTarget: Codable, Equatable, Sendable {
    public let id: Int
    public let time: Double
    public let stroke: Stroke
    public init(id: Int, time: Double, stroke: Stroke) { self.id = id; self.time = time; self.stroke = stroke }
}

public enum TimingGrade: String, Codable, Sendable { case early, perfect, late, extra }

public struct TimingHit: Codable, Equatable, Sendable {
    public let targetID: Int?
    public let inputTime: Double
    public let error: Double?
    public let grade: TimingGrade
}

public struct TimingSummary: Codable, Equatable, Sendable {
    public let targetCount: Int
    public let hits: [TimingHit]
    public var matched: [TimingHit] { hits.filter { $0.targetID != nil } }
    public var extraCount: Int { hits.count - matched.count }
    public var missedCount: Int { targetCount - matched.count }
    public var hitRate: Double { targetCount == 0 ? 0 : Double(matched.count) / Double(targetCount) }
    public var perfectRate: Double { targetCount == 0 ? 0 : Double(matched.filter { $0.grade == .perfect }.count) / Double(targetCount) }
    public var extraRate: Double { targetCount == 0 ? 0 : Double(extraCount) / Double(targetCount) }
    public var meanSignedError: Double? { mean(matched.compactMap(\.error)) }
    public var meanAbsoluteError: Double? { mean(matched.compactMap(\.error).map(abs)) }
    public var standardDeviation: Double? {
        let errors = matched.compactMap(\.error)
        guard let average = mean(errors) else { return nil }
        return sqrt(errors.reduce(0) { $0 + pow($1 - average, 2) } / Double(errors.count))
    }
    private func mean(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}

public enum PracticeError: Error { case invalidTargets, invalidCalibration }

/// Targets are engine-host times. Window (180 ms) and Perfect (50 ms) are separate rules.
public struct TimingSession: Sendable {
    public let targets: [TimingTarget]
    public let calibrationOffset: Double
    public private(set) var hits: [TimingHit] = []
    private var used: Set<Int> = []
    public static let matchingWindow = 0.180
    public static let perfectWindow = 0.050

    public init(targets: [TimingTarget], calibrationOffset: Double = 0) throws {
        guard !targets.isEmpty, targets.allSatisfy({ $0.time.isFinite && $0.stroke != .rest }),
              Set(targets.map(\.id)).count == targets.count,
              zip(targets, targets.dropFirst()).allSatisfy({ $0.0.time < $0.1.time }) else {
            throw PracticeError.invalidTargets
        }
        guard calibrationOffset.isFinite, abs(calibrationOffset) <= 0.250 else {
            throw PracticeError.invalidCalibration
        }
        self.targets = targets
        self.calibrationOffset = calibrationOffset
    }

    @discardableResult
    public mutating func tap(at inputTime: Double) -> TimingHit? {
        guard inputTime.isFinite else { return nil }
        let adjusted = inputTime - calibrationOffset
        // Earliest target wins an exact tie. Already hit closest target => extra;
        // a duplicate is never shifted onto a neighboring unplayed note.
        let closest = targets.min {
            let a = abs($0.time - adjusted), b = abs($1.time - adjusted)
            return abs(a - b) < 1e-10 ? $0.time < $1.time : a < b
        }!
        let error = adjusted - closest.time
        let hit: TimingHit
        if abs(error) > Self.matchingWindow + 1e-10 || used.contains(closest.id) {
            hit = TimingHit(targetID: nil, inputTime: inputTime, error: nil, grade: .extra)
        } else {
            used.insert(closest.id)
            let grade: TimingGrade = abs(error) <= Self.perfectWindow + 1e-10 ? .perfect : error < 0 ? .early : .late
            hit = TimingHit(targetID: closest.id, inputTime: inputTime, error: error, grade: grade)
        }
        hits.append(hit)
        return hit
    }

    public var summary: TimingSummary { TimingSummary(targetCount: targets.count, hits: hits) }
}

public struct TimingCalibration: Codable, Equatable, Sendable {
    public let route: String
    public let sampleRate: Double
    public let offset: Double
    public let spread: Double

    /// User alignment estimate includes human bias, not independent hardware measurement.
    public static func estimate(errors: [Double], route: String, sampleRate: Double) throws -> Self {
        guard errors.count >= 16, errors.allSatisfy({ $0.isFinite && abs($0) <= 0.250 }),
              !route.isEmpty, sampleRate.isFinite, sampleRate >= 8000 else { throw PracticeError.invalidCalibration }
        let sorted = errors.sorted(), offset = sorted[sorted.count / 2]
        let deviations = errors.map { abs($0 - offset) }.sorted()
        let spread = deviations[deviations.count / 2]
        guard spread <= 0.040 else { throw PracticeError.invalidCalibration }
        return Self(route: route, sampleRate: sampleRate, offset: offset, spread: spread)
    }

    public func valid(for route: String, sampleRate: Double) -> Bool {
        !self.route.isEmpty && self.sampleRate.isFinite && self.sampleRate >= 8000
            && self.route == route && self.sampleRate == sampleRate && offset.isFinite && abs(offset) <= 0.250
            && spread.isFinite && (0...0.040).contains(spread)
    }
}
