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

// Three system text styles, with weight/design variants for each job. Keeping
// these semantic lets iOS choose optical sizes, leading and Dynamic Type curves.
enum BLTypography {
    static let tempo = Font.system(.largeTitle, design: .rounded).bold().monospacedDigit()
    static let beatNumber = Font.system(.title2, design: .rounded).bold().monospacedDigit()
    static let sectionTitle = Font.title2.bold()
    static let body = Font.body
    static let control = Font.body.weight(.semibold)
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
        configuration.label.font(BLTypography.control.bold()).multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
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
        configuration.label.font(BLTypography.control).multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
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
            Text(title).font(BLTypography.sectionTitle).foregroundStyle(BeatLabStyle.ink).accessibilityAddTraits(.isHeader)
            if let subtitle { Text(subtitle).font(BLTypography.body).foregroundStyle(BeatLabStyle.muted) }
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
        .font(BLTypography.body).foregroundStyle(BeatLabStyle.ink)
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(BeatLabStyle.accentSoft, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct BLModePicker: View {
    @EnvironmentObject private var practice: PracticeStore
    @Environment(\.dynamicTypeSize) private var textSize
    var wrapsAtAccessibilitySizes = false
    var body: some View {
        Group {
            if wrapsAtAccessibilitySizes && textSize.isAccessibilitySize {
                BLWrappingPicker("顯示模式", value: practice.mode == .beginner ? "入門" : "標準",
                                 selection: Binding(get: { practice.mode }, set: { practice.setMode($0) })) {
                    modes
                }
            } else {
                Picker("顯示模式", selection: Binding(get: { practice.mode }, set: { practice.setMode($0) })) {
                    modes
                }.pickerStyle(.segmented)
            }
        }.accessibilityIdentifier("interfaceMode")
    }
    private var modes: some View {
        Group {
            Text("入門").tag(InterfaceMode.beginner)
            Text("標準").tag(InterfaceMode.standard)
        }
    }
}

// A native selection menu with an unconstrained, wrapping label. Native menu
// picker labels and segmented controls can otherwise compress long selections.
struct BLWrappingPicker<Selection: Hashable, Content: View>: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let title: String
    let value: String
    let selection: Binding<Selection>
    let content: Content

    init(_ title: String, value: String, selection: Binding<Selection>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.selection = selection
        self.content = content()
    }

    var body: some View {
        Menu {
            Picker(title, selection: selection) { content }
        } label: {
            let layout = textSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
            layout {
                Text(title).font(BLTypography.body).foregroundStyle(BeatLabStyle.ink)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value).font(BLTypography.control)
                    Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: textSize.isAccessibilitySize ? .leading : .trailing)
            }
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44)
        }
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

// Homepage palette derived from the owner's approved yellow dinosaur icon.
// Existing transport/game screens keep their own styles and behavior.
enum HomeBrand {
    static let canvas = Color("HomeCanvas")
    static let surface = Color("HomeSurface")
    static let hero = Color("HomeHero")
    static let ink = Color("HomeInk")
    static let muted = Color("HomeMuted")
    static let forest = Color("HomeForest")
    static let heroInk = Color(red: 32 / 255, green: 62 / 255, blue: 49 / 255)
}

struct HomeAdventureButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.bold()).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 24).padding(.horizontal, 16).padding(.vertical, 16)
            .foregroundStyle(HomeBrand.canvas)
            .background(HomeBrand.forest, in: RoundedRectangle(cornerRadius: 18))
            .opacity(!enabled ? 0.45 : configuration.isPressed ? 0.8 : 1)
    }
}
