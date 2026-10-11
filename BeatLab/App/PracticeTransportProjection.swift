import Foundation

/// Original logical targets/hits remain immutable across pause. Only the host
/// projection changes, once, after sample-scheduled four-beat count-in.
struct PracticeTransportProjection {
    let logicalEpoch: Double
    let frozenElapsed: Double
    let resumeHost: Double
    init?(logicalEpoch: Double, frozenElapsed: Double, countInEpoch: Double, countInDuration: Double) {
        guard [logicalEpoch, frozenElapsed, countInEpoch, countInDuration].allSatisfy(\.isFinite),
              frozenElapsed >= 0, countInDuration > 0 else { return nil }
        self.logicalEpoch = logicalEpoch; self.frozenElapsed = frozenElapsed
        resumeHost = countInEpoch + countInDuration
    }
    func logicalTime(at host: Double) -> Double? {
        guard host.isFinite, host >= resumeHost else { return nil }
        return logicalEpoch + frozenElapsed + host - resumeHost
    }
    func elapsed(at host: Double) -> Double {
        guard host.isFinite else { return frozenElapsed }
        return frozenElapsed + max(0, host - resumeHost)
    }
}
