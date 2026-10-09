# GAME-34 — 前兩關一星解鎖與精準挑戰分開

Owner clarifies 2026-10-09 that the current lesson is too hard to earn one star
and unlock the next. Supersedes the skill's reuse-existing-star-rule default for
the introductory one-star policy only. The first two sixteen-target lessons
should reward following the beat before requiring narrow Perfect accuracy.
Risk L2: scoring/catalog boundary and persisted unlock effect. Depends GAME33
corrected hand-pad layout and existing scorer, progress repository and Store.

Allowed production: Sources/BeatLabCore/RhythmLesson.swift (optional two-star
hit-rate floor, validation and atTempo preservation), Resources/lessons.json
(only first/second requiredHitRate, requiredPerfectRate, maxExtraRate and new
optional requiredTwoStarHitRate), BeatLab/Views/PracticeView.swift (read-only
intro one-star criterion in preparation). Allowed tests: Core PracticeTests.swift
and ProgressTests.swift, App PracticeStoreTests.swift, UI PracticeUITests.swift.
Docs/PLAN/verification, canonical memory/evidence and ignored TestResults/GAME-34
local frozen build/results/phone packaging. Existing branch commit/push and
paired in-place Wi-Fi trial remain authorized. No TestFlight/public/PR/merge.

Policy (independent test oracle): intro one star requires at least12/16 matched
targets, any number of Perfect hits including0, no more than4 extra taps.
11 matches or5 extras fail; zero-input and spam never earn/unlock. Early/late
matches use existing ±180ms matcher; ±50ms Perfect remains unchanged. Two stars
still require at least14/16 matched and13/16 Perfect, zero extras for16 targets
(original85% hit,80% Perfect,5% extra). Three stars retain original95% Perfect,
zero missed/extra:16/16 Perfect for these lessons. All third–tenth thresholds,
target patterns/BPM/bars/count-in, input/audio/clocks, animations/art and saved
progress schema remain unchanged. Musical R/L sequence and actual hand grading
are not altered. A matched jump is not fabricated into a Perfect grade.

Optional catalog requiredTwoStarHitRate defaults to requiredHitRate when absent;
old v1 catalogs decode with the same scoring semantics. If provided it must be
finite,0...1 and >=requiredHitRate. Preserve it through atTempo; nil remains
absent when encoded. Progress persistence still records max stars/best values;
existing1/2/3-star scores survive, failed save cannot unlock until actual retry.
Do not recompute historical failed attempts or write a phone unlock fixture.

Checks: exact integer pass/fail fixtures; old catalog optional-field absence and
invalid thresholds; second/third locked boundaries, future/corrupt save, restart
and best-star preservation. Full local Core and App regression plus real Store
new one-star late-only result/save/reload and failed-save retry. UI preparation
shows the actual12/16 and4-extra rule; real dual input/cancel/restart and largest
zero-input fail/retry remain correct. Bind107 frozen inputs and observed tests.
Signed local iphoneos package/source/profile/resources before Wi-Fi install.
Applicable physical evidence is limited to observed install/launch; real-device
judgment/timing/FPS/child usability/public gates remain unaccepted and must be
reported separately. Build/test only on this Mac, no GitHub Mac.

Failure paths: weakened two/three-star scoring, unmodified higher lesson drift,
legacy catalog break, lost two-star floor on tempo copy, unlocked-before-save,
zero/spam passing, old saved3star lowered, false total-destination presentation,
source/package mismatch or invalid profile/device lock/unavailability. Retain
failed attempts; do not waive failed tests. Rollback scoped policy/UI changes to
40b0904 while preserving existing progress and receipts. No schema migration or
reset. No slower mode or dense-level tempo changes in this slice.

Status LOCAL SOFTWARE GATES PASSED / PHONE CANDIDATE PENDING.
Full Core59/App115 and fresh UI3 passed on this Mac, no failures/skips.
Actual UI normal plus largest Light/Dark and original screenshots inspected.
Owner phone/install/physical acceptance remain separate pending evidence.
