# GAME-01 — Native rhythm journey

Outcome (2026-10-04): IMPLEMENTED_AND_INSTALLED. Selected native journey is
included in signed BeatLab 0.1.0 (4), installed and launched in place on the
owner iPhone. Core 50, App 17, final UI 6 and large/dark practice rerun 3 PASS;
App and final UI are separate runs. Failed/interrupted attempts remain in the
canonical evidence at GAME-01-verification.json. Physical timing, device game
walkthrough, child/full-accessibility and G1-G4 acceptance remain pending.

Owner (2026-10-04) explicitly requests adding the game interface after build 3
phone installation. Implement the selected journey design in the native App,
then build/test and install/launch the new candidate in place on the owner's
paired iPhone. No release upload or data reset.

Risk L1 presentation/navigation. Preserve the existing audio epoch, elapsed,
UITouch timestamp mapping, matching-window input guard, targets, grades,
star/pass rules, ProgressRepository and schema. Any change to those authorities
or clock boundaries escalates to L2 with a new contract before editing.

Allowed files: BeatLab/Views/{PracticeView,RhythmLane,RootView,HomeView}.swift;
BeatLabTests/PracticeStoreTests.swift; BeatLabUITests/{PracticeUITests,
InterfaceUITests}.swift; PLAN.md, README.md, docs/verification.md,
docs/mac-acceptance.md, docs/design/GAME-DESIGN.md, docs/slices/GAME-01*,
ignored TestResults/GAME-01/**. Existing TapPad and PracticeStore are read-only.
No project membership changes/new Swift files are required.
Follow-up test-only scope: BeatLabUITests/FoundationUITests.swift must open the
new practice settings sheet before checking shared metronome settings; preserve
its configuration/persistence assertions and execute the regression.
Forbidden: DSP, audio, core matching/scoring/progress, microphone/MIDI/services,
test fixture hooks in the shipping App, profile/certificate recreation,
uninstall/data reset, release upload, framework/pin/baseline changes. Preserve
all prior uncommitted work and receipts.

Behavior: practice tab initially shows a three-chapter journey with actual
saved completion/stars, explicit prior-lesson lock reason, and recommended
challenge. Selecting a lesson opens preparation; Home daily/continue opens
the selected preparation. Settings and the existing full lesson browser remain
available. Four-beat preparation, rhythm/rests and four-bar display read the
existing practice state. Circular pad keeps UIKit touch-down authority and the
existing early matching-window allowance; visual count-in does not add a
stricter input gate. Small/default text has reachable bottom pad; accessibility
text uses scrollable inline pad. No new animation loop or Timer.

Hide tab navigation during active practice and unsaved result; Root's existing
cancel-on-tab-change remains a defensive fallback. Cancel returns to journey
without score. Results use real summary/stars; retry/next only under existing
guards; final lesson has no nonexistent next. Unsaved results expose retry and
confirmed discard with no course-map bypass. Calibration remains accessible
through practice settings and returns to practice correctly.

Verification before installation: native App tests (actual transport cancel,
full-hit saved/restart/unlock, future payload save failure/retry/discard), UI
journey/chapter locks/selection/count-in/cancel/no-tap result/navigation and
existing full-browser flow; light/default and accessibility/dark screenshots.
Inspect rendering; run impacted core tests, simulator and signed iphoneos build,
verify source/artifact hashes/profile, install and launch with fresh inventory.
No timing/VoiceOver/child/release acceptance claim from UI or installation.

Rollback: restore only this slice's source edits from its pre-edit snapshots,
keeping MET-01 and all other work; never uninstall/revert phone data casually.
Record new candidate receipt separately from build 3. G1–G4 remain unaccepted.
