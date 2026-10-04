import Foundation

public struct MetronomeConfiguration: Equatable, Codable, Sendable {
    public private(set) var tempo: Tempo
    public private(set) var timeSignature: TimeSignature
    public private(set) var subdivision: Subdivision
    public private(set) var accentEnabled: Bool

    public static let defaultValue = MetronomeConfiguration()

    public enum ValidationError: Error, Equatable {
        case incompatibleSubdivision(Subdivision, TimeSignature)
    }

    public init() {
        tempo = .defaultValue
        timeSignature = .fourFour
        subdivision = .quarter
        accentEnabled = true
    }

    public init(
        tempo: Tempo,
        timeSignature: TimeSignature,
        subdivision: Subdivision,
        accentEnabled: Bool
    ) throws {
        guard Subdivision.supported(for: timeSignature).contains(subdivision) else {
            throw ValidationError.incompatibleSubdivision(subdivision, timeSignature)
        }
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.subdivision = subdivision
        self.accentEnabled = accentEnabled
    }

    public mutating func setTempo(_ value: Tempo) {
        tempo = value
    }

    public mutating func setTimeSignature(_ value: TimeSignature) {
        timeSignature = value
        if !Subdivision.supported(for: value).contains(subdivision) {
            subdivision = .defaultValue(for: value)
        }
    }

    public mutating func setSubdivision(_ value: Subdivision) throws {
        guard Subdivision.supported(for: timeSignature).contains(value) else {
            throw ValidationError.incompatibleSubdivision(value, timeSignature)
        }
        subdivision = value
    }

    public mutating func setAccentEnabled(_ value: Bool) {
        accentEnabled = value
    }

    private enum CodingKeys: String, CodingKey {
        case tempo, timeSignature, subdivision, accentEnabled
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            tempo: values.decode(Tempo.self, forKey: .tempo),
            timeSignature: values.decode(TimeSignature.self, forKey: .timeSignature),
            subdivision: values.decode(Subdivision.self, forKey: .subdivision),
            accentEnabled: values.decode(Bool.self, forKey: .accentEnabled)
        )
    }
}
