# 0001 — Foundation boundaries

2026-10-04; accepted for BL-001 implementation. No existing ADR conflicts.

SwiftUI/iOS 16 shell depends on a local BeatLabCore Swift package. Core owns validated values and the UserDefaults JSON repository; it imports Foundation, never SwiftUI, Combine or audio APIs. App owns one main-actor observable ConfigurationStore and tab navigation. This keeps domain/storage tests runnable on non-Apple Swift toolchains while preserving native UI.

App root owns the store with StateObject and injects it into descendants; views read that object rather than constructing independent stores. Future engine requests/applied-state handling belong to BL-002, not to this settings editor. Foundation edits persist immediately because no transport exists yet.

UserDefaults envelope schema 1 is local, with no account/data collection. Unknown schemas are preserved and editing requires explicit reset. Corrupt content returns safe defaults with a visible notice. Persistence has no claimed disk acknowledgement; App relaunch test is the acceptance evidence.

Minimum iOS 16 supports NavigationStack and uses ObservableObject rather than newer Observation-only APIs. No background mode, microphone permission, MIDI, or audio capability is declared.

References: [Apple model ownership](https://developer.apple.com/documentation/SwiftUI/Managing-model-data-in-your-app), [Swift Package Manager](https://docs.swift.org/main/documentation/packagemanagerdocs/), [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults).
