# GAME-28 — 練習畫面的可見角色與可讀提示

NIGHT01 authorizes fixing observed shared defects without waiting for owner.
Risk L1 presentation only; dependency GAME27 engineering source gate. Exact
allowed: EggMissionView.swift layout/mission overlay and bounded cosmetic backdrop parallax only, PracticeView.swift
result layout only, PracticeUITests.swift geometry regression, PracticeStoreTests.swift native compact late-scene background regression, docs/PLAN/evidence
and canonical memory. Forbidden: all route/motion/clock/input/audio/scoring/save,
lesson catalog, new art, settings and project/version files. This slice does not
redesign gameplay or resolve F5 result teleport; define that separately.

Observed GAME26 largest accessibility text leaves only top of scene in visible
ScrollView (actor below fold); dark material mission capsule uses green ink on
dark gray; result content can scroll behind floating tab bar. Controls reachable
is insufficient. Preserve Dynamic Type, original speech labels and44pt controls.
Provide always-visible scene+input during active mission: compact essential HUD
at accessibility sizes, move secondary companion/status detail into semantic
labels rather than consuming gameplay viewport. Size scene from available height
with meaningful min; avoid putting scene inside a scroll area that crops actor.
Long instructions/status remain readable through appropriate adjustable text/
scrollable secondary area without moving pad/stop off screen. Use opaque reviewed
warm/light mission caption background independent of scheme for stable green
contrast; do not use dark adaptive material under fixed green ink. Results need
scroll clearance for floating tab and reachable complete stars/actions; do not
shrink content simply to make test pass.

Checks: actual native window at normal and accessibilityXXXL light/dark, first
single pad + fourth dual pad. Scene full frame above pads, enough actor space,
44pt reachable stop/input, no duplicate actor, title/tempo/route semantic labels
retained. Capture and inspect actual screenshots, not only isHittable. Zero input
result/retry lock regressions and result stars/actions clear of tab at scroll
positions. Owned simulator before/after restoration. Relevant local UI plus
motion-source audit; physical child/contrast accessibility acceptance remains
pending where unavailable. Rollback only this presentation delta to GAME27 source.
Status IMPLEMENTING / GAME27_ENGINEERING_GATE_PASSED.
Additional scoped check: dense long routes can move backdrop beyond its overscan on200pt-high scenes. Clamp cosmetic dense parallax to actual backdrop coverage, keeping first/second legacy camera/physics identical; native final-island coverage regression. No scene target or actor motion changes.

Initial native background-coverage assertions passed, but actor-anchor fixture assumed55% instead of the reviewed55.1% (.20+1.3*.27). Native test0pass/1fail with3 anchor assertions preserved; test expectation corrected from GAME27 anchor invariant, actor production unchanged. Run actual narrow layout before final source freeze.

Initial narrow largest UI0pass/2fail stopped at status-bar AX lookup absent on SE, before remaining geometry checks; capture export has no manual PNG because assertion preceded capture. Use observed window top when status-bar AX unavailable. Keep raw log/bundle; structured summary tool reported DBError0 (NOT AVAILABLE, not fabricated counts). Also reserve scaled cue height and concise AX action copy to prevent scene resizing when feedback changes length; full speech labels retained. Test stage height before/after real count-in/touches.

02:28 final narrow largest UI2/0 PASS, focus1/0 PASS. Export tooling creates shared SQLite index inside each xcresult: parallel summary/export on same bundle caused index collision; sequential retry passed with original result intact. Future same-bundle xcresult reads/exports must run sequentially. This is evidence-tooling race, not App test failure. Initial narrow failure legacy metrics2/2 preserved.

Actual final narrow PNG review: whole active actor/controls now visible, stable scene, stars above tab. Result scene caption still wraps two huge lines and covers actor head; scoped EggMissionScene overlay now uses Dynamic Type caption and a single line at AX (full scene speech mission preserved). Final source/gates must bind this additional presentation delta; retain prior passed native/UI roots. No actor/matcher change.

Final caption-source gate: native1/0, actual normal darkUI2/0, largest primary-dark2/0+narrow-light2/0; 3native/13UI images. Actual final PNG reviewed: caption above actor head, whole scene/pads/stop, result stars above tab. Original motion/clock/input/audio/grade/save exact. Both booted appearance baselines light restored before shutdown, all simulator states restored. Status ENGINEERING_GATE_PASSED_OWNER_TRIAL_PENDING; F5 GAME31 and physical acceptance pending.
