# GAME-22 — 連續角色姿勢素材

Owner 2026-10-08 明確要求優先完成更多有效動畫圖片；GAME21 尚未安裝，GAME20 動作已被拒絕。

Risk L2 presentation reads existing audio/input clock; never changes timing authority.

Allowed: EggMissionView.swift, PracticeStoreTests.swift, three new DenseDinosaurMotion/DenseCatMotion/DenseRobotMotion imagesets (original PNGs preserved), docs/design/dense-motion/**, this contract/verification, PLAN, canonical evidence/memory. No project/signing/version, audio/DSP/Core/PracticeStore/input/matcher/score/save/other UI/old assets/Kit changes. No release upload, extra mechanics, copied competitor art.

Plan: built-in imagegen referenced existing owner characters; 32 cells per theme: run 0–11, flight 12–23, landing 24–27, ready 28–31. Run 12 frames/0.5s =24 poses/s; flight 12/0.48s =25; landing 4/0.16s =25. Character source identity/proportion/registration/alpha and sequential anatomy reviewed before consumption. No duplicate-image inflation or two-sprite ghost blending. SKView target60 distinct from pose cadence and physical FPS.

Gate: read-only alpha/grid/hash validation; distinct run/flight frames; loaded native textures and observable whole-scene animation at native callbacks, single opaque character, pause/Reduce Motion static, unchanged matching/progress/failure/retry; full App regression. Review actual sequence (not just sheet), registration, last-to-first loop and flight-to-landing join for three themes. Build simulator and signed candidate; physical presented FPS/owner appeal remain pending until measured/played.

Failure paths: missing/invalid atlas falls back to preserved sparse art; nonfinite/negative/huge time gives ready, interrupted/rest/miss stays tied to existing presentation snapshot; no animation-driven grades/targets. Reject bad character morphs, cropped edges, ghosting, near-identical repeated poses, unclear contacts even if nominal frame count passes.

Rollback: revert only this slice's presentation/assets/tests to GAME21 fd1e75f, preserve lesson data and evidence. No uninstall/reset.

References checked 2026-10-08: Adobe https://helpx.adobe.com/animate/desktop/animation/animation-basics.html (24 fps common animation rate, not a universal minimum); Apple https://developer.apple.com/documentation/spritekit/skview/preferredframespersecond (requested/actual rendering rate distinct); Godot https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html (sprite sheets/ordered frames).

Status: DEFINED / ART_IN_PROGRESS. Acceptance not claimed.

2026-10-08 implementation gate: final three 32-cell original PNGs pass read-only alpha/grid/unique-pixel-hash audit. Active motion uses12 run +12 flight +4 landing; ready28 is canonical static stance,29–31 retained source alternatives and not claimed as additional live motion. First robot grid failed at10/11/19, regenerated with margins; discarded variant retained locally, not installed. Whole-source sandbox101 inputs, production84; native App69/0 PASS (4 new regressions). Real SKView callbacks see>8 different textures over a flight/recovery sequence; controlled native fixture checks every new pose and captures84 specimens. This is not physical presented FPS. Final sim test build/signed Debug phone build PASS; first test build failed Swift tuple inference, repaired by explicit types only. Native6 apex/landing specimens observed clean; Chrome run11→0 and jump6/12/15 inspected at registered source scale. No appeal/physical FPS/full UI/accessibility/public claim. iPhone currently paired but unavailable, installation NOT RUN.

Source commit333012c3973c103ac3b6dfb571669265f8df7db4. PhoneFrozen source101/production84/protected93/signature/profile/new3Assets.car entries verified; install/launch NOT RUN because owner tunnel unavailable. Receipt artifacts/evidence/test-results/GAME-22.json checks source/artifact/report integrity and records69 PASS; it does not turn outstanding physical/UI/child gates green. Canonical memory writer/guard ran, current diff blockers0; pre-existing background warnings retained in verification, no governance adoption claim.
