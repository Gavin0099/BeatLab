# GAME-28 — 練習畫面的可見角色與可讀提示

NIGHT01 authorizes fixing observed shared defects without waiting for owner.
Risk L1 presentation only; dependency GAME27 engineering source gate. Exact
allowed: EggMissionView.swift layout/mission overlay only, PracticeView.swift
result layout only, PracticeUITests.swift geometry regression, docs/PLAN/evidence
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
Status DEFINED / WAITING_GAME27_GATE.
