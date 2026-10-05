# GAME-07 — Repair clipped native challenge viewport

Owner's build-6 iPhone screenshot shows the rhythm lane cut off above the fixed
jump/control inset, and the owner again rejects the game feel. L1 layout repair;
owner explicitly chose dinosaur rhythm runner in the async reply. Implement a native runner presentation over existing lesson judgment, not new scoring.

Allowed: PracticeView playing layout/presentation, focused PracticeUITests and presentation fixtures in PracticeStoreTests,
this contract/evidence and PLAN/README/verification. Preserve all prior changes.
Forbidden: transport, target matching, grading, saved progress, lesson patterns,
new raster assets, protected governance files, release/commit/push. A simple flat mint/green scene is a proposed treatment matching the existing dinosaur, not an accepted palette.

Root cause to verify: the bottom safe-area inset contains the entire scene,
feedback pad and stop controls; at the shown size it consumes much of the
viewport and clips the independent upper scroll content. Move the stage into
one challenge composition, with a compact HUD and in-flow controls. Use a single
scroll fallback for small heights and accessibility sizes; never an overlay
that covers required rhythm cues. Calibration keeps its existing controls.

Checks: actual simulator bounds of rhythm lane, scene, pad and stop; count-in
and mid-run screenshots; cancel, real zero-input failure and retry; normal
light/dark, narrow/short viewport, maximum text and Reduce Motion. Regression
must fail against the old clipped composition where feasible. No timing or game
appeal claim follows from these checks. Native source changes invalidate the
build-6 source match; phone candidate installation requires a new signed receipt.

Rollback only this slice's layout/test changes from ignored before snapshots.
Do not reset learner data. Owner chose runner; enjoyment, visual approval and physical timing remain pending.

Runner contract: engine elapsed plus existing pattern IDs positions approaching
rocks; rests have no rock. Only already-judged matched hits clear a rock and
trigger a hop; extra presses give no clearance. Uncrossed rocks pass behind the
player and existing miss/extra totals determine the real final stars/failure.
Existing stars/unlocks/save authority remains unchanged; no collisions, lives or
animation-derived penalties. Existing click track is not composed music. Reduce
Motion uses discrete rock positions and no hop. Default companion becomes dinosaur;
cat/robot selection remains available. A new pure presentation helper is L1 only
because it cannot submit targets, grades or saved state.


Initial delivery check: signed 0.1.0 (7) candidate retained. Fresh owner iPhone inventory
is unavailable; connection requested once. Installation/launch remain NOT RUN.
Focused normal/narrow/max-text-dark/reduced-motion evidence is recorded; actual
phone rendering and game appeal remain pending.

PHONE-07 subsequently restored delivery after the owner requested installation:
existing signed build 7 installed and launched successfully; see
PHONE-07-verification.json. No source changes, rebuild or learner-data reset.
