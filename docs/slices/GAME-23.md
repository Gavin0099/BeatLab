# GAME-23 — 下墜、承接與回到平台

Owner 2026-10-08: TestFlight12 跳躍尚可，掉落不真實且不順。保留已接受的跳躍；這是掉落呈現修正，不是玩法／判分改版。

Risk L2: presentation reads existing clock/results, no timing authority change. Depends on GAME22 atlas/cache and GAME21 display-callback renderer.

Allowed production: BeatLab/Views/EggMissionView.swift only. Tests: BeatLabTests/PracticeStoreTests.swift. Documentation: this contract, GAME-23-verification.json, PLAN.md, docs/verification.md, canonical evidence/memory. Ignored TestResults/GAME-23 may hold local source copies, logs, native specimens and signed candidate.

Forbidden: jump curves/duration/flight pose order, audio/DSP/Core/PracticeStore/input/matching/score/persistence, other UI/navigation, asset pixels, project/signing/version metadata, GitHub Mac runs, new mechanics/characters/currencies, TestFlight/public upload, PR/merge/framework edits.

Root cause: symmetric jump arc reused for a miss produces a sinking/floating cycle; stationary dense-frame selection keeps the falling actor in ready28; safety ellipse follows the actor throughout instead of visibly catching it; instruction says recovered while still falling.

Behavior: only after the real target window expires, .24s accelerating descent, .08s decelerating catch, .28s visible carrier return. Normalized reviewed depths: age .12=.1875, .24=.75, .28=.9375, .32=1, .46=.5, .60=0. Actor moves into the gap and returns on the visible catch; never advances a scored platform. Existing descending poses18–23 (.24s/6=25 poses/s) and contact24–27 represent the fall/catch; no blended duplicate actor. Catch appears below the actor before contact, compresses on contact and visibly carries it back. Instruction distinguishes falling/caught/return; static Reduce Motion has neutral miss feedback. At60BPM recovery finishes at target+.78 before the next earliest valid press at target+.82. No universal high-tempo fall guarantee.

Failure/checks: independent depth/velocity/seam fixtures, repeated misses, actual matcher miss/extra/next early hit, alignment shifts, missing route/invalid clock, preparing/cancel/restart/finished, Reduce Motion/suspended, one opaque actor/no node churn; all three themes on native SKView, sequential fall/catch/return specimens and live callbacks; local App regression and signed build. Changed scene sizes/light/dark fixtures; motion scene has no font/layout changes. Full accessibility, physical presented FPS/timing and owner appeal are pending, never implied by simulator tests.

Rollback: revert this slice's EggMissionView/tests only to 9fbc0be; preserve learner data, assets and evidence. No uninstall/reset. Status DEFINED, implementation/test/phone acceptance not yet claimed.

Implementation/local gate: App73/0, Core53/0, syntax/structure PASS, signed Debug candidate PASS; 123 native sequential/compact/tall/light/dark specimens, actual callbacks and static reduction/suspension. Initial73/0 passed; visual review found cue over face and extra shaking carrier, corrected presentation and final73/0 passed again. Reviewed jumps retain the same curves/poses; no asset pixel or99 protected input changes. Status SOURCE_TESTED_SIGNED_READY, physical/owner acceptance PENDING. Packaging setup failures (wrong xctestrun folder, interpreter symlink, source-check script cwd, wildcard provisioning assumption, DER entitlement parsing) retained; none is an App test failure. No install, release upload, version bump or public claim.
