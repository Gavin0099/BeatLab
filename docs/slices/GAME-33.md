# GAME-33 — 左右鼓墊位置修正與難度診斷

Owner 2026-10-09 reports the second lesson right-hand pad on the left and
left-hand pad on the right, and asks whether advancing is too difficult.
Risk L1 for presentation order; difficulty/scoring changes would be L2 and are
outside this correction until the owner's ambiguous difficulty feedback is
clarified. Existing commit/push and paired iPhone trial authorization remains.

Allowed production: BeatLab/Views/EggMissionView.swift, only paired hand-pad
placement. Allowed tests: BeatLabUITests/PracticeUITests.swift, spatial bounds
assertions for real visible pads. Allowed docs/evidence: this contract, PLAN,
verification, source-bound receipts and canonical memory. Local ignored
TestResults/GAME-33 stores immutable source, commands, xcresults and difficulty
analysis. Forbidden: clocks, audio/input/matcher, pad callbacks or identifiers,
target/RL pattern order, score/pass/star/unlock/save rules, catalog tempo/pattern,
animation/art/metadata, Apple uploads, PR/merge, GitHub Mac or phone fixtures.

Contract: the user's left-hand pad is physically left of their right-hand pad
in every shared dual-pad lesson. Each accessible label/identifier stays attached
to its corresponding hand. The musical R,L sequence still starts with R; never
reverse the timeline merely to change screen position. Highlight and UIKit
timestamps remain unchanged; single-pad lessons remain unchanged.

Checks: independent geometric invariant left.maxX <= right.minX; semantic labels,
44pt minimum and visible Stop; real second-level dual-pad input/cancel/restart,
zero-input failure/retry/third locked at largest text. Same shared layout covers
all dual profiles; verify a narrow largest-text case as applicable. Freeze all
source inputs and retain actual failure evidence. Local iphoneos signature/source
checks precede any standing-authorized in-place Wi-Fi install. No reset/unlock
fixture on the owner phone. Physical timing/FPS/child usability remain unaccepted.

Difficulty diagnosis: report actual catalog gates, timing windows and adjacent
target density; distinguish difficult-to-unlock from next-level difficulty.
Do not silently lower thresholds or claim hand correctness is graded. Log the
owner answer/decision and use a separate L2 contract if scoring/catalog changes
are requested. Failure paths: spatial or label mismatch, unreachable pads/Stop,
cancel accidentally saving, zero-input unlocking, source mismatch/invalid profile
or unavailable/locked device. Rollback only this correction to7d5c0b5, preserve
existing progress and failed attempts.

Status LOCAL_UI_GATE_PASSED / WIFI_INSTALLED_AND_LAUNCHED; difficulty clarification pending.

Observed local evidence: final build-for-testing passed after the test geometry
helper was corrected. Narrow SE3 normal Light actual dual touches/cancel/restart
and largest Light zero-input failure/retry/third-lock passed2/0; largest Dark
passed1/0 separately. Three original screenshots confirm left/L on the left and
right/R on the right. Largest typography was retained; this is not full
Accessibility/child acceptance. Only the newly created task-owned simulator was
restored Light, shutdown and deleted. Initial successful build before the shared
test helper adjustment is retained; it is not the final test build.

Delivery: matching sourceac9893c locally signed Debug0.1.0(13),107 frozen inputs and13 package files validated. Fresh owner localNetwork connected; install and launch each exit0/success. No reset/fixture/Apple upload. Owner progress after opening not yet observed. Difficulty thresholds remain unchanged; explanation in GAME-33-difficulty-analysis.md and source-bound verification in GAME-33-verification.json.

Follow-up owner answer clarifies one-star unlock is the difficulty. The separate
L2 GAME34 now handles introductory one-star policy; GAME33 remains the observed
layout-only delivered baseline and its receipts are not relabeled as score tests.
