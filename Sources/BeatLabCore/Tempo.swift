import Foundation

public struct Tempo: Equatable, Hashable, Codable, Sendable {
    public static let allowedRange = 30...240
    public static let defaultValue = Tempo(validatedBPM: 80)
    public let bpm: Int

    public enum ValidationError: Error, Equatable {
        case outOfRange(Int)
    }

    public init(bpm: Int) throws {
        guard Self.allowedRange.contains(bpm) else {
            throw ValidationError.outOfRange(bpm)
        }
        self.bpm = bpm
    }

    private init(validatedBPM: Int) {
        bpm = validatedBPM
    }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(bpm: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(bpm)
    }
}
