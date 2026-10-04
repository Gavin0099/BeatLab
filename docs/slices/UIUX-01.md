# UIUX-01 — Native MVP interface

Owner request: finish UI/UX before Mac acceptance. Risk L1 for navigation, disclosure and persistence-status presentation; audio/target/scoring authorities stay unchanged.

Allowed: BeatLab/Views/**, BeatLab/Design/**, BeatLab/Resources/Assets.xcassets/**, BeatLab/App/PracticeStore.swift (presentation status/retry only), BeatLabTests/PracticeStoreTests.swift, BeatLabUITests/**, BeatLab.xcodeproj/**, docs/design/**, docs/mac-acceptance.md, scripts/check_source.py, PLAN.md, README.md and curated memory/evidence. No DSP, matching rules, microphone/MIDI, services or protected framework edits.

Visual thesis: warm neutral canvas, deep purple actions, large rounded beat/tempo numerals, restrained green/gold feedback. Primary mode: native product UI; no decorative marketing hero. Light/dark semantic assets, system typography and SF Symbols.

Flow: Home → today's recommended lesson → learn pattern → 4-beat count-in → tap → results → retry/next. Metronome prioritizes tempo and Start/Stop, with settings and advanced challenges disclosed below. Practice uses separate learning/playing/results states; session content replaces the course list while active.

States: first use/no progress, completed course, locked lessons, busy speech preparation, playback failure, interruption/cancel, corrupt data, future schema, missing catalog, unsaved result, pass/retry and calibrated/uncalibrated summary. Never announce persisted progression before save succeeds; only future progress allows destructive reset, missing catalog does not.

Checks: native Swift syntax/project membership, measured palette contrast, defined UI navigation/disclosure/locked-state tests. Render a clearly labeled local design-reference prototype at narrow/mobile/tablet, dark, large text and reduced motion; this is not SwiftUI rendering. Apple compile/render/VoiceOver/physical touch checks remain NOT RUN and listed for Mac.

Rollback: revert only UIUX-01 files/changes to the prior MVP source package; preserve UserDefaults payloads, audio code, framework pin and previous artifacts. No commit/push/upload authorized.
