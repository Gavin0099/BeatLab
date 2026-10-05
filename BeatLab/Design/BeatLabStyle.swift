import SwiftUI
import BeatLabCore

enum BeatLabStyle {
    static let accent = Color("AccentColor")
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
    static let minimumTarget: CGFloat = 44

    enum TypeScale {
        static let title = Font.system(.title2, design: .rounded).bold()
        static let action = Font.headline.bold()
        static let secondaryAction = Font.headline
        static let body = Font.subheadline
        static let label = Font.subheadline.weight(.semibold)
    }
    enum Spacing {
        static let compact: CGFloat = 8
        static let regular: CGFloat = 12
        static let content: CGFloat = 16
        static let card: CGFloat = 20
        static let section: CGFloat = 24
    }
    enum Radius {
        static let card: CGFloat = 24
        static let primary: CGFloat = 18
        static let control: CGFloat = 16
    }
}

struct BLCard<Content: View>: View {
    let color: Color
    let content: Content
    init(color: Color = BeatLabStyle.surface, @ViewBuilder content: () -> Content) {
        self.color = color; self.content = content()
    }
    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
            .padding(BeatLabStyle.Spacing.card)
            .background(color, in: RoundedRectangle(cornerRadius: BeatLabStyle.Radius.card))
    }
}

struct BLPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BLPrimaryButtonBody(configuration: configuration)
    }
}

private struct BLPrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        configuration.label.font(BeatLabStyle.TypeScale.action).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.horizontal, BeatLabStyle.Spacing.content).padding(.vertical, BeatLabStyle.Spacing.content)
            .foregroundStyle(enabled ? BeatLabStyle.onAccent : BeatLabStyle.muted)
            .background(enabled ? BeatLabStyle.accent : BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: BeatLabStyle.Radius.primary))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
    }
}

struct BLSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(BeatLabStyle.TypeScale.secondaryAction).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 22)
            .padding(.horizontal, BeatLabStyle.Spacing.regular).padding(.vertical, BeatLabStyle.Spacing.regular)
            .foregroundStyle(enabled ? BeatLabStyle.accent : BeatLabStyle.muted)
            .background(BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: BeatLabStyle.Radius.control))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct BLSectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(BeatLabStyle.TypeScale.title).foregroundStyle(BeatLabStyle.ink).accessibilityAddTraits(.isHeader)
            if let subtitle { Text(subtitle).font(BeatLabStyle.TypeScale.body).foregroundStyle(BeatLabStyle.muted) }
        }.fixedSize(horizontal: false, vertical: true)
    }
}

struct BLPill: View {
    let title: String
    var symbol: String = "music.note"
    var body: some View {
        Label(title, systemImage: symbol).font(BeatLabStyle.TypeScale.label)
            .foregroundStyle(BeatLabStyle.accent).padding(.horizontal, BeatLabStyle.Spacing.regular).padding(.vertical, BeatLabStyle.Spacing.compact)
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
        .font(BeatLabStyle.TypeScale.body).foregroundStyle(BeatLabStyle.ink)
        .padding(BeatLabStyle.Spacing.content).frame(maxWidth: .infinity, alignment: .leading)
        .background(BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: BeatLabStyle.Radius.control))
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

struct BLToolbarIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .frame(width: BeatLabStyle.minimumTarget, height: BeatLabStyle.minimumTarget)
            .contentShape(Rectangle())
    }
}

// Compatibility names for the approved homepage. Shared roles have one authority.
enum HomeBrand {
    static let canvas = BeatLabStyle.canvas
    static let surface = BeatLabStyle.surface
    static let hero = Color("HomeHero")
    static let ink = BeatLabStyle.ink
    static let muted = BeatLabStyle.muted
    static let forest = BeatLabStyle.accent
    static let heroInk = Color(red: 32 / 255, green: 62 / 255, blue: 49 / 255)
}

struct HomeAdventureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BLPrimaryButtonBody(configuration: configuration)
    }
}
