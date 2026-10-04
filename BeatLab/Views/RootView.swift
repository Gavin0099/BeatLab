import SwiftUI

enum AppTab: Hashable {
    case home, metronome, practice
}

struct RootView: View {
    @EnvironmentObject private var practice: PracticeStore
    @EnvironmentObject private var audio: MetronomeAudio
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(openMetronome: { selectedTab = .metronome }, openPractice: { selectedTab = .practice })
            }
            .tabItem { Label("首頁", systemImage: "house.fill") }
            .tag(AppTab.home)

            NavigationStack {
                MetronomeView(openPractice: { selectedTab = .practice })
            }
            .tabItem { Label("節拍器", systemImage: "metronome") }
            .tag(AppTab.metronome)

            NavigationStack { PracticeView() }
                .tabItem { Label("練習", systemImage: "hand.tap.fill") }
                .tag(AppTab.practice)
        }
        .onChange(of: selectedTab) { tab in
            if tab != .practice && (practice.phase == .playing || practice.phase == .preparing) {
                practice.cancel(audio: audio, message: "這次練習已停止，沒有計入成績。回來可重新開始。")
            }
        }
    }
}
