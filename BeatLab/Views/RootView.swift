import SwiftUI

enum AppTab: Hashable {
    case home, metronome, practice
}

struct RootView: View {
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @State private var selectedTab: AppTab = .home
    @State private var preparationRequest = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(openMetronome: { selectedTab = .metronome }, openPractice: { preparationRequest += 1; selectedTab = .practice })
            }
            .tabItem { Label("首頁", systemImage: "house.fill") }
            .tag(AppTab.home)

            NavigationStack {
                MetronomeView(openPractice: { selectedTab = .practice })
            }
            .tabItem { Label("節拍器", systemImage: "metronome") }
            .tag(AppTab.metronome)

            NavigationStack { PracticeView(preparationRequest: preparationRequest) }
                .toolbar(practice.phase == .playing || practice.phase == .preparing || practice.needsSaveRetry ? .hidden : .visible, for: .tabBar)
                .tabItem { Label("練習", systemImage: "hand.tap.fill") }
                .tag(AppTab.practice)
        }
        .tint(selectedTab == .home ? HomeBrand.forest : Color.accentColor)
        .onChange(of: selectedTab) { tab in
            if tab != .practice && (practice.phase == .playing || practice.phase == .preparing) {
                practice.cancel(audio: audio, message: "這次練習已停止，沒有計入成績。回來可重新開始。")
            }
        }
    }
}
