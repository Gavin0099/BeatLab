# GAME-11 — 連續移動與即時動作回饋

Status IMPLEMENTED_LOCAL_CHECKS_PASS_INSTALL_BLOCKED_OWNER_PENDING. Owner 2026-10-06: GAME-10 比較好了但仍不夠，要求參考市面 App 流暢度。沿用送蛋回巢，針對動作與 frame pacing；不另加玩法或改品牌。參考官方開發紀錄可證明設計做法，不能證明參考 App 或 BeatLab 真機 FPS/延遲。

## Before-edit boundary

L2 because a new read-only view of the existing audio-host epoch crosses the audio/UI clock boundary. No authority change. Allowed: `BeatLab/Views/EggMissionView.swift`, `BeatLab/App/PracticeStore.swift` only for a side-effect-free presentationElapsed(hostTime) accessor, `BeatLabTests/PracticeStoreTests.swift`, `BeatLabUITests/PracticeUITests.swift` for applicable regression; `docs/design/runner-fluidity/**`, this contract/verification, PLAN, ignored `TestResults/GAME-11/**`. Canonical milestone companion via memory_record and receipts under artifacts/evidence/test-results/GAME-11-*.

Forbidden: Audio/**, DSP/**, Sources/BeatLabCore/**, TapPad, matching/targets/grade/star/persistence/calibration/endTime, store polling/sound scheduling, Xcode project/bundle/build/icon, other pages/lessons/characters/assets, framework/baseline, release upload/PR/merge. No physics collision authority, delayed input pending animation, grade override or fake successful trials. No copy of reference art/music.

Build infrastructure fallback: exact-byte temporary source copy at `/tmp/beatlab-game11-build-*` or macOS TMPDIR with that prefix, containing Package.swift, Xcode project/schemes and App/Core/DSP/test inputs only. Raw source-copy manifest in ignored TestResults. Original source hashes must match before/after build/test/install. This avoids Xcode recursive warming of large local evidence/DerivedData; no project/package changes or deletion of historical evidence. Temporary build does not prove physical performance.

## Contract

Existing audio.audibleEpoch anchors read-only host-time presentation. TimelineView animation schedule requests up to 60 updates/second for scene only, not sound/input/HUD/persistence. Guard invalid host/epoch and inactive phases; never mutate elapsed or advance matching/finish from display callbacks. Reduce Motion pauses continuous display schedule and retains real published beat/grade changes. Schedule is a request, not an achieved FPS claim.

Preserve original tap timestamp; a matched jump starts from that actual input time. Extra during a matched jump gives an in-place/pad reaction without cutting off the accepted jump or extending its lifetime. Landing follow-through is finite and returns to run; no queues. Static/inactive/count-in poses remain deterministic. Continuous background drift has no eight-second reset; near-ground texture wraps outside viewport. Different run poses share a stable foot position/size. Shadow changes with height, landing has finite squash/dust. Reserve cue text height to prevent layout moving beneath the player's finger.

First create independent playable old/new movement comparison using existing browser audio/score only; preserve true failure/retry/input. Rendering cache avoids rebuilding atlas crops/Canvas sizes each frame. Native display redraw never changes accepted IDs or rewards. Stop/cancel/restart resets ephemeral motion; reduce-motion switching produces no scoring change.

## Checks

Independent fixtures: read-only accessor versus known audio epoch at sub30ms times, nonfinite values, inactive/cancel/restart/late callbacks and no score/state mutation; original matcher unchanged. Jump continuity including accepted then extra while airborne, fixed duration/finite transforms, reduced motion, wrap boundaries. Native App regression and actual UIKit touch/zero-input/retry/stop, SE/large text/light/dark/reduced-motion applicable checks. Inspect and record actual runtime frames; distinguish simulator rendering from physical display/latency. Physical performance measurements only when tooling/device supports them; preserve failures and NOT RUN otherwise. Source hashes bind tests/build/install to candidate. Existing device install authorization applies after candidate visual/runtime inspection; no learner reset.

Rollback: restore allowed code/test paths to 9a7c62d; remove new concept/docs and reconcile PLAN through canonical writer. Preserve data, historical evidence, asset identity and framework pin. No migrations.

## Observed outcome

See GAME-11-verification.json. Final browser22, core53, wide App44+UIKit3, SE largest-text four independent real runs1 and dark viewport1 passed. Initial SE actual touch/restart and normal viewport2 passed; failed largest-text attempts retained. Tests use unchanged20second duration and actual input, never forced success. Physical profiling cannot attach to offline phone; simulator Hitches unsupported. Signed source-bound candidate exists, install failed because paired device unavailable, launch NOT RUN. No new phone candidate installed, TestFlight/public unchanged. Owner feedback partially accepts GAME-10 only; GAME-11 appeal remains pending. Prior GAME-10 owned-SE Reduce Motion restoration debt resolved to OFF, appearance light, observed via CUA and preference.
