# GAME-03 — Rhythm jump platforms and reusable design skill

Owner authorizes implementing the proposed jump-island game and saving the
five verified game references as a reusable skill. Existing phone-update
permission continues. Risk L2 evidence boundary conservatively retained for
new rhythm-cue/accepted-hit presentation; scoring/audio/input authorities are
read-only and physical timing acceptance is still pending.

Allowed: BeatLab/Views/PracticeView.swift (presentation state and jump stage),
BeatLabTests/PracticeStoreTests.swift (independent presentation fixtures),
BeatLabUITests/PracticeUITests.swift (actual native flows), PLAN.md, README.md,
docs/verification.md, docs/design/GAME-DESIGN.md, docs/slices/GAME-03*, ignored
TestResults/GAME-03/**; personal skill folder beatlab-rhythm-game-design.

Read-only: PracticeStore, TapPad, RhythmLane, Core/DSP/audio, catalog,
persistence/schema, project membership, assets/provenance, protected baseline
and framework pin. No clocks/targets/judgment from animation. Use latest accepted
TimingHit results and existing elapsed value only for visual presentation.

Matched hits jump to their target tile. Extra/duplicate hits do not add a route
success. Count-in remains intact; missed tiles are not filled, rest tiles stay
wait cues. Safety repositioning keeps current cue reachable and awards nothing.
Cancel/restart resets transient presentation. Calibration keeps the original
pad. Reduce Motion uses no jump/route animation. Preserve modes, locks,
retry/discard/save behavior, real stars and all three cosmetic companions.

Verification: independent fixtures for hit/miss/extra/rest/count-in/restart,
existing native practice flows with jump-stage assertions, focused maximum
text/dark checks, reduced-motion presentation coverage, signed device build
and manifest. Core timing regressions remain required for L2; physical timing,
child appeal and G1-G4 cannot be accepted without their actual evidence.
Preserve all failed/interrupted results; report scoped/composite evidence.

Rollback: restore only this slice's edits from ignored before snapshots;
preserve GAME-02 and earlier work. Skill rollback is limited to its newly
created folder. No uninstall/data reset, commit/push/PR/merge/TestFlight implied.
