# GAME-20 — 跟拍跨島的原生第一關

Status SOURCE_IMPLEMENTED_PHONE_INSTALLED_QA_PARTIAL，2026-10-08。Owner拒絕GAME17畫面後，授權「好，往下做，做完幫我安裝」。Risk L2：只讀audio/input/UI時間界面，未修改判分權威。以現有第一關60 BPM為入口，三角色共用，保留16真實targets、4拍數拍、既有星星/保存/解鎖及音訊。

目的：遊戲場景為主要表面；有效matched每次跨到下一個落腳點，先看到角色橫向起跳再由鏡頭跟進。漏拍過真實matching window後可見跌落/接回原平台，不推進matched數；extra不推進且不打断有效jump。背景沿用原有美術，runtime裁掉連續地面；有分隔的平台、下一落腳點的節拍提示和可見終點。樂句縮成短列，不再四個大表單格。準備/實際结果/重試都接相同構圖。

Allowed exact files：BeatLab/Views/EggMissionView.swift（只讀route epoch/valid-hit cache、pure presentation及持續SpriteKit graph、UI）、BeatLab/Views/PracticeView.swift（第一關prepare/result資料接線及copy）、BeatLabTests/PracticeStoreTests.swift（新增獨立fixture/實際scene測試）、BeatLabUITests/PracticeUITests.swift（相應label/viewport與真實操作驗證）、本契約/GAME-20-verification.json、PLAN、canonical artifacts/evidence/test-results/GAME-20*及canonical writer memory，ignored TestResults/GAME-20/**。
Forbidden：BeatLab/App/**、BeatLab/Audio/**、Sources/**、Tests/**、resources/assets/music/project/signing/version、targets/matching窗口/calibration/score/save/生命/貨幣/新課程/新角色、KidsCharacterKit。運動畫面不得生成拍點、判分或音訊；不用UI Timer排聲音，不捏造physical ms/FPS。沿用同bundle/team Debug signedphone install/launch，禁止uninstall/reset/upload。

Presentation contract：一個真實matched target只增加一格；同target duplicate/extra不得增加。位置取actual inputTime和原epoch，0.48秒飛行、0.16秒落地；鏡頭延後0.48秒開始0.32秒跟進，純視覺，不另設landing judgment。Miss只能在targetTime+alignment+matchingWindow之後，0.48秒sin軌跡跌落並回到原平台；新matched接回可玩狀態。Reduce Motion保持静態落腳/顏色，沒有飛行/鏡頭平滑/跌落位移。跳幀以absolute time重算，取消/重試不沿用舊hit；沒有route時準備畫面只能展示環境，不創造可判定目標。成功終點姿態只由既有finishedPassed給出，不因畫面distance成立。

Checks：獨立spec fixture和真實TimingSession early/late/extra/duplicate/miss、invalid時間、16 hits endpoint、camera continuity/dropped frames、Reduce Motion、新run空資料；三theme actualSKScene橫移/平台gaps/安全回復、不改node graph/physics/no scheduling。實際App regression（含save failure/interruption/restart）、dino actualtouch及zero-input結果與locked、companion流程、wide viewport及narrow dark最大字級立即驗，實際截圖檢視。建置95source/78production frozen hash/signature/device新inventory綁定，完成後Wi-Fi install/launch。未通過項保留FAIL；phone installation是owner preview，不等於full QA/G1-G4/child/physical timing/FPS/public接受。原cat重新start/narrowXXXL缺口不得隱藏。

Rollback：只回復上述presentation/UI與相關測試至d13697b，保留owner拒絕/失敗證據與learner data；不改clock/grade/資料作補救。

## 2026-10-08 原生畫面修正

初次建置與61 App tests PASS；UI cat首次start未進入playing FAIL、其它流程尚未完整驗完，保留原始log。Actual owned-wide screenshot observed-current.png已看到跨島場景：cue被過高scene推入scroll下方，背景stretch使太陽變橢圓。僅修allowed呈現檔中的scene高度/aspect-fill背景並消除同texture/text的每幀重設，新增texture aspect guard；不推定UI start失敗原因已解決。停止only owned前候選測試，保留App61/partialUI結果，不稱全綠。後候選需重build/freeze並驗actual viewport/touch/no-input/companions，沿用未變的Core/App store/save證據需精確source reuse說明；真機節拍/FPS仍NOT RUN。

比例guard首次使用1e-8，在3theme各觀察2.963e-8差異；SpriteKit浮點size round不能用Double機器精度要求。改為獨立1e-6比例誤差上限（低於百萬分之一），保留首次1 case/3 assertions FAIL，需重跑，不改production以配合test。

交付：source 0e83ed34efa4a0e5576eee6ff52fb0c011042e94，Wi-Fi install PASS，launch BLOCKED_DEVICE_LOCKED；精確tests/失敗/未完成/非claims見GAME-20-verification.json。本人可玩preview，不等於physical/child/full QA/release acceptance。
