# GAME-15 — 角色動作連續性與真機流暢度診斷

Status IMPLEMENTED_NATIVE_BUILD_PASS_WIDE57_PASS_PHONE_PENDING. Owner reports installed GAME-14 actions still not smooth; classifying pose cadence vs scene hitch vs delayed response. Base 55851abf23bbf4973b6e4036f17d3add7b20bab3. GAME-14 Wi-Fi install/launch PASS; source a6e1869 remains installed. KidsCharacterKit integration still deferred.

Before-edit scope: L2 read-only performance/animation boundary diagnosis. Initially allowed docs/slices/GAME-15.md / GAME-15-verification.json, PLAN.md, ignored TestResults/GAME-15/** and canonical GAME-15 evidence/memory. No App source or asset edits until an implementation contract defines exact changes, independent failure regression, applicable checks and rollback.

Forbidden: audio transport/scheduling/targets/input/matching/score/persistence/calibration/lessons, new art or KidsCharacterKit, release uploads/PR/merge, phone uninstall/reset, unrelated apps/devices/shared Simulator services. User authorizes smoother game, existing engineering commit/branch push persists. Do not rebuild/reinstall just to diagnose unchanged candidate.

Observe actual animation frame selection, transitions into/out of jump/recovery, physical display/hitch evidence when device supports Instruments. Existing 60 request is not proof of presented FPS. Simulator callback interval/work measurements exclude GPU/compositor and cannot establish physical fluidity. New profiling does not modify timing authority. Any physical capture must identify actual gameplay segment, not idle HUD or scripted success.

Retain prior GAME-14 and GAME-13 QA gaps and failed profiler attempts. No owner acceptance claim. Rollback diagnosis docs only; retain captured evidence and installed candidate/data.


## Implementation contract before edits

L2 presentation-only continuity. Exact allowed source: BeatLab/Views/EggMissionView.swift and BeatLabTests/PracticeStoreTests.swift. Allowed docs additionally docs/design/motion-continuity/**, GAME-15-verification.json, PLAN.md; ignored exact-byte temp build root. All audio/input/matching/score/persistence/catalog/tempo/assets/project/UITests and deferred KidsCharacterKit remain forbidden.

Observed: missed presentation lasts0.48s each expired target. During it renderer freezes or swaps avatar to `setOriginal(4)` (dinosaur different atlas/anchor/scale; companions static frame16), suppresses gait bob, then abruptly returns to run. Proposed invariant: missed musical target must not replace/freeze avatar run cycle, change registered body geometry or abruptly cut bob. Keep ordinary run/jump poses and motion, use existing text plus a short cosmetic tint pulse for miss; tint cannot award hit, advance obstacle, hide pending cues or schedule sound. Jump feedback clears tint immediately. Reduce Motion remains static with a small static miss highlight. Preparation/result and task-score outcomes unchanged.

Execute regression on original production first, retain FAIL. Independent reference state only removes expired-miss flag at same host/elapsed to compare actual SpriteKit texture identity/size/anchor/position; verify actual miss pose continues changing, actual upcoming rock center unchanged and no accepted state fabricated. Check all3 companions, accepted jump from recovery, invalid/reduced inputs/lifecycle, real zero-input failure/cancel/retry and lane-spacing protections. Reuse isolated browser playable concept; compare original freeze vs continuous loop with real misses. Final source/phone signature receipts bind candidate before owner install; prior 55/30 are not new evidence. No asset regeneration or increasing frame selector speed to imitate fluidity. This does not solve limited drawing-frame count or prove physical GPU/frame pacing. Rollback only allowed files to55851ab, preserve installed data and all failures.

Physical Animation Hitches attempt failed with device-boot timeout over wireless. Instruments did not record gameplay; physical frame pacing NOT RUN. Do not reset phone or change user Wi-Fi preference to work around this.


Final generic native build PASS; actual wide57/0 (App54 +3 real UI workflows for zero-input failure/locks, matched touch/retry/cancel and viewport). Source95/protected93 verified; browser33/0 with real16Perfect/0Extra and actual zero-input recovery renderer observation. No Core rerun; source/tests byte-identical. New phone delivery pending at implementation checkpoint. Physical profiling failure retained; artwork pose-count limitation and prior small-screen/XXXL QA remain unaccepted.
