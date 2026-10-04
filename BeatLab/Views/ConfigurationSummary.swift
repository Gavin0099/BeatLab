import SwiftUI
import BeatLabCore

extension Subdivision {
    var displayName: String {
        switch self {
        case .quarter: return "四分音符"
        case .eighth: return "八分音符"
        case .sixteenth: return "十六分音符"
        case .triplet: return "三連音"
        case .compoundEighth: return "每拍三個八分音符"
        }
    }
}

struct ConfigurationSummary: View {
    let configuration: MetronomeConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(configuration.tempo.bpm) BPM · \(configuration.timeSignature.rawValue)")
                .font(.headline.bold())
                .monospacedDigit()
                .accessibilityIdentifier("configurationSummary")
            Text(configuration.subdivision.displayName)
                .font(.subheadline)
                .accessibilityIdentifier("subdivisionSummary")
            Text(configuration.accentEnabled ? "第一拍重音：開啟" : "第一拍重音：關閉")
                .font(.subheadline)
                .foregroundStyle(BeatLabStyle.muted)
                .accessibilityIdentifier("accentSummary")
        }
    }
}
