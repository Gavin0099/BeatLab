import Foundation

public enum BeatEmphasis: Int, Codable, CaseIterable, Sendable {
    case normal = 1, accent = 2, muted = 3
    public var next: Self { self == .accent ? .normal : self == .normal ? .muted : .accent }
    public var displayName: String { self == .accent ? "重音" : self == .normal ? "一般" : "靜音" }
}

public enum ClickTimbre: Int, Codable, CaseIterable, Sendable {
    case electronic = 0, woodblock = 1, mechanical = 2
    public var displayName: String { self == .electronic ? "電子音" : self == .woodblock ? "木魚聲" : "機械音" }
}

public struct MetronomeConfiguration: Equatable, Codable, Sendable {
    public private(set) var tempo: Tempo
    public private(set) var timeSignature: TimeSignature
    public private(set) var subdivision: Subdivision
    public private(set) var beatEmphases: [BeatEmphasis]
    public private(set) var clickTimbre: ClickTimbre
    public private(set) var screenPulseEnabled: Bool
    public private(set) var hapticsEnabled: Bool
    public var accentEnabled: Bool { beatEmphases.first == .accent }
    /// Two bits per big beat. Zero is reserved for the legacy DSP default.
    public var encodedBeatPattern: Int {
        beatEmphases.enumerated().reduce(0) { $0 | ($1.element.rawValue << ($1.offset * 2)) }
    }

    public static let defaultValue = MetronomeConfiguration()

    public enum ValidationError: Error, Equatable {
        case incompatibleSubdivision(Subdivision, TimeSignature)
        case invalidBeatPattern
        case invalidBeatIndex(Int)
    }

    public init() {
        tempo = .defaultValue
        timeSignature = .fourFour
        subdivision = .quarter
        beatEmphases = [.accent, .normal, .normal, .normal]
        clickTimbre = .electronic
        screenPulseEnabled = false
        hapticsEnabled = false
    }

    public init(
        tempo: Tempo,
        timeSignature: TimeSignature,
        subdivision: Subdivision,
        accentEnabled: Bool,
        beatEmphases: [BeatEmphasis]? = nil,
        clickTimbre: ClickTimbre = .electronic,
        screenPulseEnabled: Bool = false,
        hapticsEnabled: Bool = false
    ) throws {
        guard Subdivision.supported(for: timeSignature).contains(subdivision) else {
            throw ValidationError.incompatibleSubdivision(subdivision, timeSignature)
        }
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.subdivision = subdivision
        let pattern = beatEmphases ?? (0..<timeSignature.beatsPerBar).map { $0 == 0 && accentEnabled ? .accent : .normal }
        guard pattern.count == timeSignature.beatsPerBar else { throw ValidationError.invalidBeatPattern }
        self.beatEmphases = pattern
        self.clickTimbre = clickTimbre
        self.screenPulseEnabled = screenPulseEnabled
        self.hapticsEnabled = hapticsEnabled
    }

    public mutating func setTempo(_ value: Tempo) {
        tempo = value
    }

    public mutating func setTimeSignature(_ value: TimeSignature) {
        timeSignature = value
        beatEmphases = Array(beatEmphases.prefix(value.beatsPerBar))
        while beatEmphases.count < value.beatsPerBar { beatEmphases.append(.normal) }
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
        beatEmphases[0] = value ? .accent : .normal
    }

    public mutating func cycleBeat(at index: Int) throws {
        guard beatEmphases.indices.contains(index) else { throw ValidationError.invalidBeatIndex(index) }
        beatEmphases[index] = beatEmphases[index].next
    }
    public mutating func setClickTimbre(_ value: ClickTimbre) { clickTimbre = value }
    public mutating func setScreenPulseEnabled(_ value: Bool) { screenPulseEnabled = value }
    public mutating func setHapticsEnabled(_ value: Bool) { hapticsEnabled = value }

    private enum CodingKeys: String, CodingKey {
        case tempo, timeSignature, subdivision, accentEnabled, beatEmphases, clickTimbre, screenPulseEnabled, hapticsEnabled
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            tempo: values.decode(Tempo.self, forKey: .tempo),
            timeSignature: values.decode(TimeSignature.self, forKey: .timeSignature),
            subdivision: values.decode(Subdivision.self, forKey: .subdivision),
            accentEnabled: values.decode(Bool.self, forKey: .accentEnabled),
            beatEmphases: values.decodeIfPresent([BeatEmphasis].self, forKey: .beatEmphases),
            clickTimbre: values.decodeIfPresent(ClickTimbre.self, forKey: .clickTimbre) ?? .electronic,
            screenPulseEnabled: values.decodeIfPresent(Bool.self, forKey: .screenPulseEnabled) ?? false,
            hapticsEnabled: values.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? false
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(tempo, forKey: .tempo)
        try values.encode(timeSignature, forKey: .timeSignature)
        try values.encode(subdivision, forKey: .subdivision)
        try values.encode(accentEnabled, forKey: .accentEnabled)
        try values.encode(beatEmphases, forKey: .beatEmphases)
        try values.encode(clickTimbre, forKey: .clickTimbre)
        try values.encode(screenPulseEnabled, forKey: .screenPulseEnabled)
        try values.encode(hapticsEnabled, forKey: .hapticsEnabled)
    }
}
