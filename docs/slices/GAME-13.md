# GAME-13 — 貓咪雲端與機器人科技平台連續動作

Status IMPLEMENTED_BUILD_PASS_FINAL_UI_PARTIAL_OWNER_PENDING. Owner 2026-10-06：「貓咪和機器人也這樣做，風格要不一樣」。沿用 GAME-12 第一關 60 BPM 的既有短任務；兩個角色各有原創跑步八幀、跳躍六幀、準備／落地／失誤／成功與場景。貓咪暖色柔軟雲端，機器人保留原角色蠟筆材質、藍色科技平台。恐龍素材與行為保留。

## Before-edit boundary

L2 presentation at existing clock boundary. Allowed: BeatLab/Views/EggMissionView.swift; BeatLab/Views/PracticeView.swift (cosmetic companion theme, preparation/start/result); BeatLabTests/PracticeStoreTests.swift; BeatLabUITests/PracticeUITests.swift (actual companion navigation/touch/retry); new CatMotionAtlas / RobotMotionAtlas / RunnerCloud / RunnerCircuit imagesets (Contents.json/artwork.png); docs/design/companion-motion/**; docs/slices/GAME-13.md and GAME-13-verification.json; PLAN.md; ignored TestResults/GAME-13/** and exact-byte temporary build copy. Canonical writer and evidence receipt may write memory and artifacts/evidence/test-results/GAME-13-*.

Forbidden: PracticeStore/audio/DSP/Core/input/targets/scoring/save/lesson/endTime, Xcode project/package/bundle/build/icon, existing assets, framework/baseline, new modes/levels/currency/lives, public/TestFlight/PR/merge. Existing phone installation authority applies only after satisfactory visual and runtime checks; preserve learner data.

## Contract / dependencies

Depends on GAME-12 persistent SpriteKit scene, one opaque character layer, registered alpha crops and existing read-only presentationElapsed. First-beat at 60 BPM now uses that scene for all three companions. Other speeds/lessons keep existing runner. Shared controls, count-in, matching, music, success/failure/save rules remain. Cat delivers a fish parcel to its cloud home; robot delivers an energy capsule to its charging station; these are cosmetic mission descriptions, not new scoring state. Each theme has its own backdrop/obstacle/props and gait bob/lean/landing personality. Accepted action retains its original lifetime; extra never interrupts or advances; miss safety recovery awards nothing. Reduce Motion static; background/result/preparation paused; no SKActions/collision scoring or frame-derived sound.

Before native edits, playable themed concept retains real AudioContext judging and real zero-input failure, extra/retry/cancel. Generated art uses inspected owner references, actual transparent alpha and no raster reencoding. Crop/baseline metadata reviewed and saved; frame callback does not decode textures or create nodes. Invalid theme/time/size produces finite static presentation, never affects store. Theme selection is cosmetic; no persistence migration.

## Checks / rollback

Observed QA repair within PracticeView allowed presentation scope: accessibility XXXL journey row compressed its departure label into a vertical column and failed the actual companion entrance test twice. Stack badge/details vertically at accessibility sizes; retain normal layout, lesson selection and unlock rules. Keep both failed candidates, capture full visibility diagnostics and rerun the same entry flow. This is a layout finding, not proof of the exact hittability root cause.

QA fixture root cause: the eight capped 220 pt drags reached the fully visible first lesson only on the final gesture. The loop threw without checking that final position; setting `requiresHit=false` still failed before attempting a touch, so the initial isHittable interpretation was unsupported. Raise the bounded scroll checks to 24, retain enabled/hittable/viewport requirements, and assert a real coordinate touch opens the exact first lesson. No score, time, route or saved completion is injected.

The expanded check reached both companions; robot's second live run then exposed a fixture query error: querying `isHittable` on an offscreen UIKit pad threw an invalid activation point before any viewport scroll. Check frame visibility before hit-point lookup. Keep actual hit-point requirements on visible controls and do not extend the 20 second course.

Actual XXXL preparation screenshot showed the repeated full mission caption covering the cat's ears. Use concise in-scene captions at accessibility sizes while preserving the full outside title and full scene accessibility label. Accessibility result scene gets 280 pt instead of 220 pt to fit character beneath its caption. Normal-size captions/layout and all timing remain unchanged. Interrupt only the owned in-progress viewport-fixed run for this observed visual repair; retain its partial logs.

Actual concept inputs and zero-input failure for both themes; image alpha/crop/identity/frame-order inspection; native App regressions plus independent theme fixtures for distinct textures/transforms and matched/extra/miss/retry/resize/Reduce Motion; real SKView update/pause/detach. Native navigation selects each companion and starts real first lesson; real UIKit input and cancellation/retry. Changed-area narrow, large text, light/dark and Reduce Motion screenshots. Bind exact source/build hashes and preserve failed attempts. Simulator evidence cannot prove physical FPS/input timing, child appeal or public readiness.

Rollback only allowed files to f43507f and remove new assets/concept; reconcile PLAN via canonical writer. Preserve learner data, existing art/evidence and framework pin.

## Final checkpoint

Final source-bound App49/Core53/browser20 PASS; final wide actual cat/robot touch/cancel/retry 2/0 PASS. Final narrow run50/2 retains XXXL application crash and robot zero accepted inputs. CoreAudio RPC timeout stack is in unchanged audio stop path; no causal claim or audio repair within this slice. Latest generic Simulator build PASS; prior explicit-device destination build failed. Owned narrow settings restored to light/Reduce Motion off, then shut down only that owned device. No signed phone build/install/launch; fresh owner tunnel unavailable. No TestFlight/public/physical FPS or timing/child appeal acceptance. Exact runs/hashes/failures in GAME-13-verification.json.
