public enum Subdivision: String, CaseIterable, Codable, Sendable {
    case quarter
    case eighth
    case sixteenth
    case triplet
    case compoundEighth

    public static func supported(for signature: TimeSignature) -> [Subdivision] {
        signature.isCompound
            ? [.compoundEighth]
            : [.quarter, .eighth, .sixteenth, .triplet]
    }

    public static func defaultValue(for signature: TimeSignature) -> Subdivision {
        signature.isCompound ? .compoundEighth : .quarter
    }
}
