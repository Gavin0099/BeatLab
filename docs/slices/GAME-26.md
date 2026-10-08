# GAME-26 — 第二關左右接力跨島

Owner2026-10-09 explicitly starts level2, superseding the previous levels2–10
hold for this level only. First-level physical acceptance is still pending.
Risk L2: mission eligibility and read-only cue/scene/input boundaries; no timing
or grade authority change. Dependencies: GAME25 cached grounded rig, accepted
flight/recovery, existing catalog quarter-hands and progress/save contracts.

Allowed production: BeatLab/Views/EggMissionView.swift (level profiles, cue/HUD,
second-level dual pads and read-only R/L scene prompt); PracticeView.swift
(preparation/eligibility/results metadata); App/PracticeStore.swift (restrict
mission mode to authored levels/base tempo); Views/TapPad.swift (optional semantic
label/identifier, same UIKit timestamp path). Tests: PracticeStoreTests.swift,
PracticeUITests.swift. Docs: this contract/evidence, PLAN, verification and
canonical memory/evidence. Ignored TestResults/GAME-26 local builds/native
screens/fixtures. Prior standing owner App commit/branch push and paired-device
trial authorization remain. No TestFlight/public upload, PR/merge or GitHub Mac.
Forbidden: lesson JSON/core/DSP/audio/scheduler/judgment/window/calibration/save
schema/rules, original PNG/registration, flight/fall curves/pose cadence, version
metadata, other levels, new currency/hand detection or result F5 redesign.

Level2 retains65BPM/4bars/16 R,L,R,L strokes. Four-beat count-in; matching notes
advance one island, extras never advance and miss recovers before next cue.
Character themes/art and motion remain shared. Level2 presents paired right/left
pads and R/L prompt by actual target times/results, independent of traveled
platform count. Both pads call the existing time-only matcher; hand labels are
instructional, not detection or graded-side assertions. First level keeps its
single pad. Existing65BPM click/feedback is retained; the authored60BPM music bed
stays first-level only. Scene count-in/HUD derives selected level; no hardcoded
first-level60 labels. No locks bypass, reset or fabricated unlock on save failure.
Unsupported/custom tempos use existing generic practice as before.

Checks before trial: base-profile/invalid/other-level restrictions; 65BPM target
spacing/count-in/end, alternating strokes, matched/extra/miss/early/late actual
matcher, shortest valid adjacent-hit gap and read-only world continuity; first-
level regression. Native all3themes grounded/flight/return and R/L prompts,
Reduce Motion/invalid route/reset. Store original locked→saved first result→
second selection, result save/restore/third lock and failed/cancel/retry semantics.
Actual UIKit dual-pad touches/stop/restart with explicit isolated saved-first
fixture; compact viewport/largest-text reachability. Local full App and Core
regression, owned simulator state restore, source audit forbidden files. Build,
signature/source/profile checks before any previously authorized phone trial.
Physical65BPM output/input latency/FPS and child learning remain unaccepted.

Failure paths: second cannot launch when locked/unsaved first; missing route
shows preparing; target end/invalid time yields neutral; cue must not stick at
first/last R or follow missed platform index. Pause/reduce clears motion. Reject
unreachable dual pads/stop or duplicate grading. Preserve failed attempts; fix
before candidate delivery. Rollback only this slice source/doc changes to6a5381b;
keep saved progress, receipts, protected baseline and framework unchanged.
Status ENGINEERING_GATE_PASSED / OWNER_TRIAL_PENDING. Local full App87/0 before
final hand-caption opacity-only delta; final native focus1/0 and real UI3/0;
Core53/0 unchanged. Both original failed runs retained. All simulator states and
light appearance restored. Largest-text controls are reachable, but native review
observed actor below fold, dark material caption contrast and large result/tab
overlap. These visual defects are open, not accepted; NIGHT01 permits a separate
scoped shared accessibility/layout fix. Physical evidence and F5 remain pending.
Levels3–10 now proceed under NIGHT01, not this slice alone.
