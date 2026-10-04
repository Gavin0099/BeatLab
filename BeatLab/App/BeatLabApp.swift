import Foundation
import SwiftUI
import BeatLabCore

@main
@MainActor
struct BeatLabApp: App {
    @StateObject private var store: ConfigurationStore
    @StateObject private var audio = MetronomeAudio()
    @StateObject private var practice: PracticeStore

    init() {
        var defaults = UserDefaults.standard
        #if DEBUG
        // UI tests use an isolated suite. Production ignores all test arguments.
        if let suite = ProcessInfo.processInfo.environment["BEATLAB_UI_TEST_SUITE"],
           suite.hasPrefix("BeatLabUITests."),
           let testDefaults = UserDefaults(suiteName: suite) {
            defaults = testDefaults
            if ProcessInfo.processInfo.arguments.contains("--reset-test-settings") {
                defaults.removePersistentDomain(forName: suite)
            }
        }
        #endif
        _store = StateObject(wrappedValue: ConfigurationStore(
            repository: ConfigurationRepository(defaults: defaults)
        ))
        _practice = StateObject(wrappedValue: PracticeStore(repository: ProgressRepository(defaults: defaults)))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(audio)
                .environmentObject(practice)
                .onChange(of: store.configuration) {
                    if practice.phase != .playing && practice.phase != .preparing { audio.request($0) }
                }
                .onChange(of: practice.mode) { mode in
                    if mode == .beginner { audio.setGap(0); audio.setLadder(0) }
                }
                .tint(.accentColor)
        }
    }
}
