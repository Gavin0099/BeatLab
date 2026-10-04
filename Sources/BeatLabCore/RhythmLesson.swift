import Foundation

public enum Stroke: String, Codable, Sendable { case right = "R", left = "L", rest = "-" }

public struct RhythmPattern: Codable, Equatable, Sendable {
    public let stepsPerBeat: Int
    public let steps: [Stroke]

    public init(stepsPerBeat: Int, steps: [Stroke]) {
        self.stepsPerBeat = stepsPerBeat
        self.steps = steps
    }

    public func validate() throws {
        guard [1, 2, 3, 4].contains(stepsPerBeat), steps.count == stepsPerBeat * 4,
              steps.contains(where: { $0 != .rest }) else { throw LessonError.invalidPattern }
    }

    public func targets(bpm: Int, bars: Int, epoch: Double, countInBeats: Int = 4) throws -> [TimingTarget] {
        try validate()
        _ = try Tempo(bpm: bpm)
        guard (1...16).contains(bars), (0...8).contains(countInBeats), epoch.isFinite else {
            throw LessonError.invalidLesson
        }
        let stepDuration = 60.0 / Double(bpm * stepsPerBeat)
        var result: [TimingTarget] = []
        for bar in 0..<bars {
            for (index, stroke) in steps.enumerated() where stroke != .rest {
                let step = bar * steps.count + index
                result.append(TimingTarget(id: step, time: epoch + Double(countInBeats) * 60 / Double(bpm)
                    + Double(step) * stepDuration, stroke: stroke))
            }
        }
        return result
    }
}

public struct Lesson: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let instruction: String
    public let bpm: Int
    public let bars: Int
    public let pattern: RhythmPattern
    public let requiredHitRate: Double
    public let requiredPerfectRate: Double
    public let maxExtraRate: Double

    public func validate() throws {
        _ = try Tempo(bpm: bpm)
        try pattern.validate()
        guard !id.isEmpty, !title.isEmpty, !instruction.isEmpty, (1...16).contains(bars),
              requiredHitRate.isFinite, requiredPerfectRate.isFinite, maxExtraRate.isFinite,
              (0...1).contains(requiredHitRate), (0...1).contains(requiredPerfectRate),
              (0...1).contains(maxExtraRate) else { throw LessonError.invalidLesson }
    }

    public func passes(_ summary: TimingSummary) -> Bool {
        summary.targetCount > 0 && summary.hitRate >= requiredHitRate
            && summary.perfectRate >= requiredPerfectRate && summary.extraRate <= maxExtraRate
    }

    public func atTempo(_ value: Int) throws -> Lesson {
        _ = try Tempo(bpm: value)
        guard value >= bpm else { throw LessonError.invalidLesson }
        return Lesson(id: id, title: title, instruction: instruction, bpm: value, bars: bars,
            pattern: pattern, requiredHitRate: requiredHitRate, requiredPerfectRate: requiredPerfectRate,
            maxExtraRate: maxExtraRate)
    }

    public func stars(_ summary: TimingSummary) -> Int {
        guard passes(summary) else { return 0 }
        if summary.perfectRate >= 0.95 && summary.extraCount == 0 && summary.missedCount == 0 { return 3 }
        if summary.perfectRate >= 0.8 && summary.extraRate <= 0.05 { return 2 }
        return 1
    }
}

public enum LessonError: Error { case unsupportedVersion, invalidPattern, invalidLesson, duplicateID }

public struct LessonCatalog: Codable, Sendable {
    public let schemaVersion: Int
    public let lessons: [Lesson]

    public static func load(_ data: Data) throws -> LessonCatalog {
        struct Header: Decodable { let schemaVersion: Int }
        guard try JSONDecoder().decode(Header.self, from: data).schemaVersion == 1 else {
            throw LessonError.unsupportedVersion
        }
        let catalog = try JSONDecoder().decode(Self.self, from: data)
        guard !catalog.lessons.isEmpty, catalog.lessons.count <= 100 else { throw LessonError.invalidLesson }
        guard Set(catalog.lessons.map(\.id)).count == catalog.lessons.count else { throw LessonError.duplicateID }
        for lesson in catalog.lessons { try lesson.validate() }
        return catalog
    }

    public static func bundled() throws -> LessonCatalog {
        guard let url = Bundle.module.url(forResource: "lessons", withExtension: "json") else {
            throw LessonError.invalidLesson
        }
        return try load(Data(contentsOf: url))
    }
}
