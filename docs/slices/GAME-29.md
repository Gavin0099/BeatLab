# GAME-29 — 留白與反拍（第五、六、九關）

Defined under NIGHT01; dependency GAME27 density and GAME28 responsive gate.
Risk L2 read-only cue/input-clock boundary; no grade authority change. Exact
allowed: EggMissionView.swift authored profiles, validated grid/rest-cell cue,
waiting presentation and target-count path; PracticeView.swift preparation copy;
PracticeStore.swift first-only music flag only if needed; PracticeStoreTests.swift,
PracticeUITests.swift, docs/PLAN/evidence/canonical memory. Forbidden core/DSP/audio,
lesson JSON/window/threshold/save schema, original art, motion curves of first4,
new modes/currency/services/version. Separate later slice handles sixteenths.

Existing authored lessons:5 at70BPM R,-,R,- quarter;6 at70BPM R,L,-,R,-,L,R,-
eighth;9 at75BPM -,R,-,L,-,R,-,L eighth. Grid cells and TimingTargets are different:
rest has no target. Reconstruct read-only cells from validated target IDs and grid
interval including initial/trailing rests, and validate selected catalog profile.
Four-beat count-in remains musical beats, not note interval nor first-note offset.
During a rest show wait/stand cue; next valid early window may overlap rest time,
so actual matcher acceptance must immediately have accurate feedback. Never claim
all taps within rest cell are extras: matcher nearest-target/window is authority.
Tap exact rest center fixture where outside note windows must be extra/no island;
missed actual targets recover; no fall at a rest, no platform/score increment
from silence. Musical wait may show next hand upcoming without instructing jump
now. Distinguish current rest from next target prompt and accepted feedback.

Path goal/counter = actual matched target count (5=8,6=20,9=16); keep route-grid
steps separate. Platform pool must also cover sparse quarter notes and starting
rest, not default16 goal. Keep original quarter/half flight duration determined
by grid interval; shared first4 motion behavior remains equivalent. Preparation
shows authored rest/right/left pattern and unambiguous waiting. No role detection.

Checks: reviewed target IDs/times/count-in/end, exact rest-center extra, legal
near-rest early/late nearest-target tie, accepted duplicates, missed-note recovery,
no rest fall, first/trailing-rest cue, aligned0/±.25 cue authority, cancel/retry,
zero failure locked continuation and failed save. Native all3 themes rest and
next early, last path8/20/16 and Reduce Motion; real UI rest wait and actual touch.
Build/test local Mac; owned simulator restoration, source/component audit. Keep
physical mixed cue clarity/timing/FPS/child acceptance pending owner trial.
Rollback only this scoped delta to completed GAME28; preserve saves/evidence.
Status DEFINED / WAITING_GAME27_GAME28.
