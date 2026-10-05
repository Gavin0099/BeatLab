# HOME-01 — 首頁與已選定 icon 一致

2026-10-05 owner reports TestFlight candidate 9 downloaded and homepage inconsistent with selected yellow/green dinosaur icon. Implement native homepage revision using that approved icon as the concrete visual reference; no new gameplay or publication request inferred.

Risk L1: homepage composition, existing navigation and tab tint only. Dependencies: PracticeStore recommended/select/unlocked/progress; ConfigurationStore; existing approved AppIcon. No timing/input/scoring changes.
Allowed: BeatLab/Views/HomeView.swift; RootView.swift tint only; BeatLab/Design/BeatLabStyle.swift brand palette/button style additions; Resources/Assets.xcassets/HomeDinosaur.imageset and six Home* color sets; docs/design/branding/home-* prompt/provenance; FoundationUITests.swift; this slice and verification JSON; PLAN.md; ignored TestResults/HOME-01 backups/build logs/screenshots/xcresult. Existing AppIcon remains unchanged.
Forbidden: audio, gameplay, matching, clocks, persistence, lesson content/unlocks, new rewards/currency/services, permissions, bundle/signing/version changes, TestFlight upload/App Store submission, other simulators' state, governance framework/AGENTS.base.md, unrelated dirty files.

Failure paths: no recommended lessons/invalid catalog preserve fallback + metronome access; blocked practice disables CTA; completed-all preserves repeat; saved last lesson only continues if unlocked; large type/small screen scrolls whole composition; dark palette readable; long titles wrap; tab bar does not hide reachable controls. Preserve ConfigurationSummary accessibility fields and existing navigation IDs.
Checks: iOS simulator build; Foundation UI navigation/shared configuration regression; focused daily-entry/tab separation test with native screenshot; actual light/dark largest-font/small-height homepage screenshots. These do not establish physical timing, child usability, VoiceOver acceptance or G1-G4. TestFlight candidate 9 remains the distributed version.
Rollback: restore only the four Swift files and PLAN from ignored before snapshots; remove only HOME-01 newly added assets/docs. Preserve earlier dirty work and uploaded candidate 9 manifests.
