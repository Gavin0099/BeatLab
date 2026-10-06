# GAME-14 — 均勻可讀的 60 BPM 障礙提示

Status IMPLEMENTED_BUILD_PASS_WIDE_CHECKS_PASS_NARROW_INCOMPLETE_PHONE_BLOCKED. Owner 2026-10-06 clarified the issue is uneven-looking obstacle intervals, not character FPS. Base27d07d0, current installed source6019be7. KidsCharacterKit integration remains deferred.

## Before-edit contract

L2 presentation on existing clock boundary. Allowed exact source: BeatLab/Views/EggMissionView.swift (pure lane geometry/visibility and fixed visual beat marker); BeatLabTests/PracticeStoreTests.swift (independent first-lesson timing/visibility/clock fixtures). Allowed docs: docs/slices/GAME-14.md / GAME-14-verification.json, docs/design/beat-spacing/**, PLAN.md; ignored TestResults/GAME-14/** and exact-byte temporary build copy; canonical memory writer/evidence artifacts GAME-14-*.

Forbidden: PracticeStore/Audio/Core/DSP/input/targets/matching/score/persistence/lesson/tempo/calibration, other views/tests/assets/icon/project/package, KidsCharacterKit art/integration, new modes/levels/rewards, TestFlight/public/PR/merge. Existing commit/engineering branch push and owner phone installation authorization persist; preserve bundle/team/learner data.

Observed source: first60BPM obstacle centers already have equal spacing and cross actor anchor at elapsed4+i, on the read-only audio-host epoch. However any accepted target immediately hides its rock and replaces it with a reward, including early matches; this can remove an upcoming visual cue before its scheduled crossing. No video/physical capture establishes real unequal beat intervals; do not assert an audio scheduling defect or a measured root cause from the screenshot.

Repair: keep each accepted obstacle visible until its fixed scheduled crossing, then fade only behind the marker; no input-based repositioning or new targets. Add a fixed floor beat marker at the actor anchor, pulsing from existing elapsed only, so arrival has a readable reference independent of pose/feet. Matching feedback remains immediate; upcoming cue timing never derives from tap/collision/animation. First beat4s then1s intervals remains unchanged. Miss/extra cannot move/hide an upcoming target. Reduce Motion uses static step positions with no animated fade/pulse, but never hides a pre-crossing accepted cue. Preparation/result/background/detach remain paused. Invalid clock/geometry remains finite/static.

## Checks and rollback

Before fix, execute an actual native regression showing early accepted cue hidden before4s; preserve FAIL. Independent reviewed first-beat catalog fixtures validate16 crossings at4...19 seconds and adjacency at narrow/wide sizes; verify before/after crossing, dropped display samples, early/late/extra/miss, accepted visibility, reuse, resize, Reduce Motion, pause/detach. Native App regression and focused actual touch/cancel/retry; visualize old/new lane with real input and audio clock, zero-input failure/Extra/retry/cancel before native presentation edit. No concept state transplanted into App.

Build exact bytes, record source/artifact/signature and phone install/launch outcomes. Simulator/model evidence is not physical onset sync, frame pacing, child acceptance or full release QA. GAME-13 narrow XXXL failures remain unaccepted. Rollback only allowed files to27d07d0, preserve learner data and previous evidence.

## Implementation evidence

Before-fix native regression FAIL: one test, two assertions (early rock disappearance and reward before crossing). Exact-byte final generic Simulator build PASS; wide native 55/0 (52 App tests + 3 real UI workflows). New catalog fixtures cover 16 scheduled crossings, accepted/not accepted, skipped callbacks, 320/375/402 widths and static Reduce Motion. Browser final 30 checks PASS with genuine early input and actual rendered positions; real 16-target completion is 16 Perfect/0 Extra. Initial browser stale-RAF fixture failure retained; copied-formula geometry checks replaced in final run.

95 source inputs bind final build; 93 protected inputs remain unchanged. First narrow attempt used nonexistent class filter and was explicitly interrupted without acceptance; corrected narrow run and phone delivery pending at implementation checkpoint. Physical audiovisual cadence not measured. Prior GAME-13 narrow XXXL failures remain unaccepted. Canonical evidence reader validates receipts; it does not rerun tests. Source check only parses structure; native build/test evidence is separate.


Corrected narrow dark run produced no test execution output after several minutes and was interrupted explicitly; no narrow pass claimed. Only the owned xcodebuild was stopped. Owned narrow appearance restored to light and initially-off device shut down successfully; shared Simulator services and unrelated Garden devices untouched. No new small-screen screenshot claimed. Phone build follows implementation commit a6e1869; final delivery receipts will bind that source.


Signed iphoneos Debug 0.1.0(10) build PASS; frozen candidate binds a6e1869 and 78 production inputs, valid original team/bundle/profile/signature. Installation attempted once from fresh paired-device inventory; CoreDevice failed to locate owner phone. Launch NOT RUN. Unlock/USB request pending; reuse this candidate after connection, do not rebuild or uninstall/reset. Installation and physical synchronization remain unaccepted. Engineering branch checkpoint does not update TestFlight/public.


Canonical writer executed for daily/review-log/active-task-summary, bound a6e1869 and durable GAME-14-regression receipt. Memory guard current/repo B0 blockers0; historical missing memory1/provenance2 and root writer-path warnings remain. Framework writer used via pinned PYTHONPATH; do not claim knowledge-base update or full normalization. This is milestone/defect memory, not session-end closeout.
