# GAME-10 — 第一關送蛋回巢試玩

Status IMPLEMENTED_AND_INSTALLED；本機工程檢查完成，owner 玩法接受／實體 timing／public gate 待驗。Owner 2026-10-06 接受分析提案「好，這樣做做看」。先獨立可操作 concept，再 native；本片 L2（在既有 DSP clock 上混合原創鼓組），UI 部分 L1。只改善 first-beat / 60 BPM / 恐龍，其他九關與夥伴保留既有流程，不新增 catalog、模式、角色或遊戲經濟。

## Boundaries before edits

Allowed production files: `BeatLab/Views/PracticeView.swift`, new `BeatLab/Views/EggMissionView.swift`, new `BeatLab/Audio/PracticeGroove.swift`, `BeatLab/Audio/MetronomeAudio.swift`, `BeatLab/App/PracticeStore.swift`, `Sources/BeatLabDSP/BeatLabDSP.c`, `Sources/BeatLabDSP/include/BeatLabDSP.h`, `BeatLab.xcodeproj/project.pbxproj` for exactly those two Swift memberships, new `BeatLab/Resources/Assets.xcassets/EggMissionAtlas.imageset/{Contents.json,artwork.png}`. Allowed tests: `Tests/BeatLabCoreTests/DSPTests.swift`, `Tests/DSPKernelTests/main.c`, `BeatLabTests/MetronomeAudioTests.swift`, `BeatLabTests/PracticeStoreTests.swift`, `BeatLabUITests/PracticeUITests.swift`. Allowed docs: this contract/verification, PLAN, `docs/design/egg-mission/**`, ignored `TestResults/GAME-10/**`. Milestone companion uses canonical memory writer daily/active-task-summary/review-log and actual test receipts under `artifacts/evidence/test-results/GAME-10-*`.

Forbidden: timing position/epoch formulas, transport scheduling rules, targets/matching/score/stars/thresholds, UIKit touch path, persisted schema/migrations, catalog, other page redesign, icon/bundle/build, permissions/services, framework/protected baseline, PR/merge/public distribution. No animation-derived targets, collision grading, fabricated ms precision or reset on silence. Browser clock is isolated and never transplanted into native.

## Loop and authorities

Four count-in beats then sixteen real targets at 60 BPM. Show the nest destination and carried egg before starting; approaching rocks preview the next musical beat. Accepted hits cross rocks; Perfect lights the egg; extra hops in place without progress; expired unmatched targets show a stumble/catch/recovery. Do not add lives or a second collision timing requirement. Scene advancement reads original elapsed; success/failure reads actual existing summary/stars and save result. Zero input fails. Retry remains the existing lesson. Hand labels remain instructions, not detection.

Original finite mono drum PCM is prepared before graph.start, copied into C DSP before first render, and indexed by the existing sample cursor after four count-in beats. Beat/meter/subdivision change disables the bed to prevent mismatch. No allocation/locking/UI timer in render. No source music copied. Existing clear click and short judged input feedback retained. Gain0 silences all output without resetting transport. Invalid rate/PCM/setup safely falls back to existing clicks; nonmission/free metronome/calibration have no bed.

Independent invariants: PCM finite, <=16 s, peak <=0.20, rate 8k–192k; setter rejects started DSP/invalid samples/length/delay. Bed starts after exactly four beats, stops finitely, respects gain/mute, cannot change beat history/clock/target positions. Chunk sizes do not change output. Stop/cancel/restart cannot retain a prior bed. UI reacts only to accepted hit IDs and original miss deadlines (matching window + max calibration allowance); reduced motion uses static poses/highlights. Scene, jump and stop must remain reachable on SE, large text, light/dark.

## Checks and failure paths

Playable browser concept: manual input, real zero-input failure, extra/missed/matched distinction, finish/retry/cancel, count-in, mobile dimensions; browser audio not hardware precision evidence. Native: DSP boundary fixtures plus existing core/C/UBSan/offline duration tests, actual graph/music output and calibration/free-play exclusion, stop/restart/volume0, presentation independent hit fixtures, native first lesson input/zero-input/retry/stop, unaffected ten-lesson smoke. Inspect native screenshots for SE, max text, dark and Reduce Motion. Physical timing, cue audibility, frame pacing, VoiceOver and child appeal remain NOT RUN until measured/owner tried; no release gate claim from local results.

Rollback: restore only listed changed production/test paths to 6a9677e and remove new files/memberships; preserve learner data, historical evidence, current PLAN/memory changes and framework pin. Feature scoped by lesson/BPM/companion can be disabled without migrations.
