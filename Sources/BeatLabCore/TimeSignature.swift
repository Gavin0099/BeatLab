public enum TimeSignature: String, CaseIterable, Codable, Sendable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case sixEight = "6/8"

    public var beatsPerBar: Int {
        switch self {
        case .twoFour, .sixEight: return 2
        case .threeFour: return 3
        case .fourFour: return 4
        }
    }

    public var isCompound: Bool { self == .sixEight }
}
