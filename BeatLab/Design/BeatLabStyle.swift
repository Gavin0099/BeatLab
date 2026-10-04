import SwiftUI
import BeatLabCore

enum BeatLabStyle {
    static let canvas = Color("Canvas")
    static let surface = Color("Surface")
    static let ink = Color("Ink")
    static let muted = Color("MutedInk")
    static let line = Color("Separator")
    static let accentSoft = Color("AccentSoft")
    static let onAccent = Color("OnAccent")
    static let success = Color("Success")
    static let successSoft = Color("SuccessSoft")
    static let reward = Color("Reward")
    static let rewardSoft = Color("RewardSoft")
    static let maxWidth: CGFloat = 680
}

struct BLCard<Content: View>: View {
    let color: Color
    let content: Content
    init(color: Color = BeatLabStyle.surface, @ViewBuilder content: () -> Content) {
        self.color = color; self.content = content()
    }
    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
            .padding(20).background(color, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct BLPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.bold()).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 24).padding(.horizontal, 16).padding(.vertical, 16)
            .foregroundStyle(enabled ? BeatLabStyle.onAccent : BeatLabStyle.muted)
            .background(enabled ? Color.accentColor : BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
    }
}

struct BLSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 22).padding(.horizontal, 12).padding(.vertical, 12)
            .foregroundStyle(enabled ? Color.accentColor : BeatLabStyle.muted)
            .background(BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct BLSectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title2.bold()).foregroundStyle(BeatLabStyle.ink).accessibilityAddTraits(.isHeader)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(BeatLabStyle.muted) }
        }.fixedSize(horizontal: false, vertical: true)
    }
}

struct BLPill: View {
    let title: String
    var symbol: String = "music.note"
    var body: some View {
        Label(title, systemImage: symbol).font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor).padding(.horizontal, 12).padding(.vertical, 8)
            .background(BeatLabStyle.accentSoft, in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

struct BLStatusMessage: View {
    let text: String
    var symbol: String = "info.circle.fill"
    var body: some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: { Image(systemName: symbol).accessibilityHidden(true) }
        .font(.subheadline).foregroundStyle(BeatLabStyle.ink)
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct BLModePicker: View {
    @EnvironmentObject private var practice: PracticeStore
    var body: some View {
        Picker("顯示模式", selection: Binding(get: { practice.mode }, set: { practice.setMode($0) })) {
            Text("入門").tag(InterfaceMode.beginner)
            Text("標準").tag(InterfaceMode.standard)
        }.pickerStyle(.segmented).accessibilityIdentifier("interfaceMode")
    }
}
