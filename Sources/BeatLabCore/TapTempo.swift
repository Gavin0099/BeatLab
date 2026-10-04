import Foundation

/// Host-time seconds, never wall time. Five most recent intervals, median estimate.
public struct TapTempo: Sendable {
    private var lastTap: Double?
    private var intervals: [Double] = []

    public init() {}

    public mutating func reset() {
        lastTap = nil
        intervals.removeAll(keepingCapacity: true)
    }

    public mutating func tap(at seconds: Double) -> Tempo? {
        guard seconds.isFinite, seconds >= 0 else { reset(); return nil }
        guard let previous = lastTap else { lastTap = seconds; return nil }
        let interval = seconds - previous
        guard interval > 0 else { reset(); lastTap = seconds; return nil }
        // Ignore a double tap without shifting the reference of the intended tap.
        guard interval >= 0.25 else { return nil }
        lastTap = seconds
        guard interval <= 2 else { intervals.removeAll(keepingCapacity: true); return nil }
        if !intervals.isEmpty {
            let sorted = intervals.sorted()
            let middle = sorted[sorted.count / 2]
            if abs(interval - middle) > middle * 0.35 {
                // A deliberate tempo change starts a new series rather than blending.
                intervals.removeAll(keepingCapacity: true)
            }
        }
        intervals.append(interval)
        if intervals.count > 5 { intervals.removeFirst() }
        guard intervals.count >= 2 else { return nil }
        let sorted = intervals.sorted()
        let middle = sorted.count / 2
        let median = sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
        return try? Tempo(bpm: Int((60 / median).rounded()))
    }
}
