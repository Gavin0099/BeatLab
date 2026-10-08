# GAME-21 — 跨島動作回歸修正

Status SOURCE_TESTED_OWNER_PREVIEW_PENDING。Owner指出已安裝GAME20「比之前跳的還爛、動作不順」；記為REJECTED_GAME20_MOTION，不以App61 PASS或安裝成功取代體驗接受。Risk L2只讀clock/render boundary，僅修既有第一關跨島呈現與三角色動作，不增加玩法/素材。

Allowed exact files: BeatLab/Views/EggMissionView.swift, BeatLabTests/PracticeStoreTests.swift, PLAN.md, docs/slices/GAME-21.md/GAME-21-verification.json, canonical evidence GAME-21*, canonical writer memory; ignored TestResults/GAME-21/**。
Forbidden: PracticeStore/audio/Core/input/target matching/calibration/score/save、其餘Views/UITests、asset/music/project/version/signing、KidsCharacterKit、上傳TestFlight/public、新模式/關卡/貨幣。既有Wi-Fi本人測試安裝授權延續，同bundle/team原地安裝，不uninstall/reset。

Root mechanism observed in source: camera在0.48s落地後才以0.32s跟進，令角色落地後在螢幕上倒滑；sin跳躍在落地速度非零而瞬間固定y；single sprite整幀換圖且落地立刻回14，沒有pose銜接。不是已測得的physical掉幀根因。

Contract: 保留每matched一格、0.48s flight/0.16s landing、16真實targets；camera用同一flight progress跟進，角色screen x不因落地後camera倒退。起落/跌落使用端點一階二階速度零的平滑曲線，最大高度/時間不改；保留已註冊的單一不透明sprite與現有pose序列，不以雙圖混合掩蓋姿勢跳切，不生成新bitmap；extra不打斷accepted，miss不前進，ReduceMotion靜態。持續SpriteKit graph；live SwiftUI configure只交新snapshot給下一display callback，不在每次publish額外render；theme static色/尺寸減少每幀重設。必要texture預熱只能一次/theme，不能在frame decode。

Checks: independent screen-velocity/endpoint invariants、late/early/duplicate/extra/miss、C2起落/camera continuity/drop frames、單一opaque角色/image support與three-theme实际SKScene、actual platform SKView callback/paused/detach/no-double-render。App完整regression；native sampled sprite畫面/短動作觀察，不拿headless fixture稱真實輸入或physicalFPS。signed/source/hash frozen以及owner Wi-Fi install/launch分開記錄。現有UI cat start/viewport/narrow gaps不因此關閉。

Rollback: revert以上呈現與新增regression至0e83ed3，不碰matching或刪除學習資料；保留owner拒絕與失敗證據。驗收是owner手機再試，public/physical timing/FPS/child仍pending。

Withdrawn trial constraint (historical, superseded): preserve opaque base during24ms overlay. Native specimens later disproved this workaround: distinct poses still generated double heads/limbs; overlay was removed entirely. Final has one opaque character and unchanged existing pose sequence.

## Native evidence correction

First App suite:65 executed /62 cases PASS /3 cases FAIL /6 assertions FAIL. Existing single-opaque-character invariants rejected the added overlay graph; no owner installation. The two-sprite blend was withdrawn, not the existing assertions. Final scope keeps one registered opaque sprite and existing pose sequence, focuses on C2 motion/coupled camera/frame-owned rendering/prewarm. No claim that sparse source poses now equal skeletal animation or that texture switching is eliminated. Preserve failed suite plus native specimens; final needs fresh65-case run/build and human visual inspection.

Human inspection of withdrawn native specimens confirmed robot/cat double heads and dinosaur double limbs at the attempted overlay midpoint. This prototype is visually rejected as well as test-failed and remains uninstalled; it is not the final motion candidate.

Final native App65 cases/0 failures PASS, including unchanged single-character guards and4 motion regressions. Native SpriteKit samples of all3 themes at4.252 were visually inspected: single clean character, no overlay ghosting, separated landing platforms. Samples are synthetic matcher fixtures in native renderer, not live UI input or measured physicalFPS; sparse existing poses remain a limitation. Signed final build PASS, frozen/source/phone receipt pending.

Delivery evidence source fd1e75f54a6688365f571466507059398539d8d2: final frozen95/78 hash bind +93protected unchanged +codesign/profile PASS. Phone install NOT RUN, launch NOT RUN. Paired owner inventory currently unavailable; asked once for same Wi-Fi/unlock. Exact outcomes inGAME-21-verification.json; last phone remains GAME20 until actual receipt.
