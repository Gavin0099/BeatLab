# GAME-25 — First-level grounded motion and takeoff continuity

Owner on2026-10-09 explicitly authorizes implementing inter-jump continuity then
installing over Wi-Fi. Risk L2: presentation samples existing host/target/input
boundaries; timing authority stays unchanged. Dependencies GAME21–24 accepted
flight/fall curves, dense registration, cached expressions and motion review.

Allowed production: BeatLab/Views/EggMissionView.swift only. Tests:
BeatLabTests/PracticeStoreTests.swift. Docs: this contract/verification, PLAN,
docs/verification.md, canonical evidence/memory. Ignored TestResults/GAME-25
source copy/builds/native specimens/phone receipts. App commit/branch push and
owner in-place install/launch authorized. No PR/merge/TestFlight/public upload.
Forbidden: PracticeStore/Core/audio/input/matcher/score/save, original asset
pixels/anchors, flight/fall curves/durations/pose order, scene navigation/result
redesign, version/signing metadata, other levels, new mechanics, framework edits,
GitHub Mac execution, reset/uninstall/certificate regeneration.

Behavior: a single opaque existing sprite uses bounded continuous upper-body
deformation while grounded: dinosaur breath/tail, cat breath/tail/ears, robot
head/antenna. Lower28% stays registered and unwarped; no running-on-platform,
duplicate sprites/ghost blends, new bitmap claims or per-frame shader allocation.
Idle fades in after landing/recovery; real upcoming note gives anticipation
without advancing or awarding anything. Accepted early/on-time/late starts
flight immediately, with ≤.10s release of prior grounded deformation. First
valid early input overrides count-in stance. Existing path/grade/pose authority
unchanged. Recovery expression owns its phase; reduced/preparing/finish/missing
route/invalid time disables new deformation. Suspended callbacks stop. Missing
dense atlas uses preserved fallback with no idle shader.

Checks: independent fixture boundaries/invalid/missing route/first early,
early→late/late→early, real matcher matched/extra/miss/next early, four continuous
beats and recovery→idle, planted root/camera/feet, distinct native upper-body
pixels during previously static waits, scene-local shader identity and one actor,
actual live callback progression/pause, three themes/compact/tall/light-dark.
Update old static28 tests to distinguish stable base texture from moving rendered
body; retain Reduce Motion static assertion. Full local App regression and Core,
source diff audit preserving curves/PNG/audio/input/save. Signed candidate binds
tested source/compiled assets/profile before fresh Wi-Fi install and launch.
Physical FPS/input latency/child appeal/first-level completion remain pending
owner/device evidence, not implied by simulator callbacks.

Failure paths: idle cannot override flight/landing/recovery; invalid clocks yield
neutral. Reject foot sliding, clipped/body smearing, shader compile/missing assets,
shared uniforms leaking between scenes, active-hit suppression or failed native
pixel evidence. Preserve attempts; no phone install before corrected candidate
passes. Rollback only these source/test changes to9beca67; preserve data/evidence.
Status SOURCE_NATIVE_TESTED / INSTALLED_AND_LAUNCHED_FOR_TRIAL. F5 result handoff remains separate;
levels2–10 deferred until first level complete.
