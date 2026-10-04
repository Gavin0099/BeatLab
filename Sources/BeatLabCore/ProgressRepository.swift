import Foundation

public enum InterfaceMode: String, Codable, CaseIterable, Hashable, Sendable { case beginner, standard }

public struct LessonProgress: Codable, Equatable, Sendable {
    public var stars: Int
    public var bestPerfectRate: Double
    public var bestBPM: Int
}

public struct PracticeProgress: Codable, Equatable, Sendable {
    public var results: [String: LessonProgress] = [:]
    public var lastLessonID: String?
    public var mode: InterfaceMode = .beginner
    public var calibration: TimingCalibration?
    public init() {}

    public func isUnlocked(_ id: String, in lessons: [Lesson]) -> Bool {
        guard let index = lessons.firstIndex(where: { $0.id == id }) else { return false }
        return index == 0 || (results[lessons[index - 1].id]?.stars ?? 0) > 0
    }
    public func recommended(in lessons: [Lesson]) -> Lesson? {
        lessons.first { isUnlocked($0.id, in: lessons) && (results[$0.id]?.stars ?? 0) == 0 } ?? lessons.last
    }
    public mutating func record(_ lesson: Lesson, summary: TimingSummary) {
        lastLessonID = lesson.id
        let stars = lesson.stars(summary)
        guard stars > 0 else { return }
        let old = results[lesson.id]
        results[lesson.id] = LessonProgress(stars: max(stars, old?.stars ?? 0),
            bestPerfectRate: max(summary.perfectRate, old?.bestPerfectRate ?? 0),
            bestBPM: max(lesson.bpm, old?.bestBPM ?? 0))
    }
}

public struct ProgressRepository {
    public static let storageKey = "beatlab.practice.progress"
    public enum Status: Equatable { case new, restored, corrupt, futureVersion }
    public enum StoreError: Error { case futureVersion, invalidData }
    private let defaults: UserDefaults
    private struct Header: Decodable { let schemaVersion: Int }
    private struct Envelope: Codable { let schemaVersion: Int; let progress: PracticeProgress }
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() -> (PracticeProgress, Status) {
        guard defaults.object(forKey: Self.storageKey) != nil else { return (.init(), .new) }
        guard let data = defaults.data(forKey: Self.storageKey) else { return (.init(), .corrupt) }
        do {
            guard try JSONDecoder().decode(Header.self, from: data).schemaVersion == 1 else { return (.init(), .futureVersion) }
            let value = try JSONDecoder().decode(Envelope.self, from: data).progress
            try validate(value)
            return (value, .restored)
        } catch { return (.init(), .corrupt) }
    }
    public func save(_ progress: PracticeProgress) throws {
        if load().1 == .futureVersion { throw StoreError.futureVersion }
        try validate(progress)
        defaults.set(try JSONEncoder().encode(Envelope(schemaVersion: 1, progress: progress)), forKey: Self.storageKey)
    }
    public func reset() { defaults.removeObject(forKey: Self.storageKey) }
    private func validate(_ progress: PracticeProgress) throws {
        guard progress.results.count <= 100, progress.results.allSatisfy({ key, value in
            !key.isEmpty && (1...3).contains(value.stars) && value.bestPerfectRate.isFinite
                && (0...1).contains(value.bestPerfectRate) && (30...240).contains(value.bestBPM)
        }) else { throw StoreError.invalidData }
        if let calibration = progress.calibration,
           !calibration.valid(for: calibration.route, sampleRate: calibration.sampleRate) { throw StoreError.invalidData }
    }
}
