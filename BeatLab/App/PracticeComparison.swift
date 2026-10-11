import Foundation
import BeatLabCore

enum RhythmPresentation: String, CaseIterable { case falling, runner
    var title: String { self == .falling ? "雙軌節奏" : "節奏跑酷" }
}

/// Only projects already-authored targets and actual matcher results.
struct RhythmGameSnapshot {
    let targets: [TimingTarget]
    let hits: [TimingHit]
    let epoch: Double
    let duration: Double
    let alignment: Double
    let bpm: Int
    var subdivisions: Int = 1
    var accepted: Set<Int> { Set(hits.compactMap(\.targetID)) }
    var perfectStreak: Int {
        var streak = 0
        var previousID: Int?
        for hit in hits {
            guard hit.grade == .perfect, let id = hit.targetID,
                  let index = targets.firstIndex(where: { $0.id == id }) else { streak = 0; previousID = nil; continue }
            let preceding = index > 0 ? targets[index - 1].id : nil
            streak = previousID == preceding ? streak + 1 : 1
            previousID = id
        }
        return streak
    }
    func perfectStreak(at elapsed: Double) -> Int {
        let streak = perfectStreak
        guard streak > 0, let lastID = hits.last?.targetID,
              let index = targets.firstIndex(where: { $0.id == lastID }) else { return 0 }
        let expired = missed(at: elapsed)
        // A real missed target ends the displayed streak immediately; rests
        // have no target and therefore never reset it. Scoring is untouched.
        return targets.suffix(from: index + 1).contains(where: { expired.contains($0.id) }) ? 0 : streak
    }
    func missed(at elapsed: Double) -> Set<Int> {
        guard elapsed.isFinite else { return [] }
        let played = accepted
        return Set(targets.filter { $0.time + alignment + TimingSession.matchingWindow + 1e-10 < epoch + elapsed && !played.contains($0.id) }.map(\.id))
    }
    func distance(_ target: TimingTarget, elapsed: Double) -> Double? {
        guard elapsed.isFinite, bpm > 0 else { return nil }
        // Same center as inputTime - calibrationOffset in TimingSession.
        return (target.time + alignment - epoch - elapsed) / (2 * 60 / Double(bpm))
    }
}
