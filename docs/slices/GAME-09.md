# GAME-09 — 跑酷遊玩與結果的品牌一致

狀態：PLANNED；L1，依賴 GAME-08 角色與既有 GAME-07 runner。目的：把角色、障礙、場景、節奏提示、操作和結果做成同一畫風的短練習循環；美術接受與好玩分別觀察。

Allowed files：`BeatLab/Views/PracticeView.swift` 的 runnerChallenge／runnerContent／runnerRhythm／runnerStage、feedback 色彩與 resultPanel／AdventureFinish 呈現；`BeatLab/Views/RhythmLane.swift` 的 display styles；`BeatLabUITests/PracticeUITests.swift`、`BeatLabTests/PracticeStoreTests.swift` 中純呈現 fixtures；`docs/design/branding/runner-layout.md`；本 evidence／PLAN。
Forbidden：PracticeStore、TapPad／UIKit input、Audio／DSP／Sources、課程與評分／保存；RhythmJumpPresentation.record／cueStep、RhythmRunnerPresentation 時計公式；latestHit hop 觸發與 lifecycle 邏輯；新生命／道具經濟／碰撞評分／新音樂排程。新增 soundtrack／更改節奏密度若需要，另立 L2 機制契約。

契約：短 HUD＋主要場景＋清楚節奏格＋單一「跳」與停止入口，一個高度感知 composition，短高度／大字一起捲動。只從既有 elapsed／targets 畫石頭；命中才清除並跳起，extra 無清除，miss 保留失敗後果，休止沒有石頭且必須等。先聽四拍再開始。獎勵／結果讀實際 summary；save 未成功不展示已解鎖；重試／下一關／最後一關／保存重試／放棄都保留。Reduce Motion 靜態位置、高亮和可操作 pad，避免動畫決定結果。

Failure paths：場景遮文字／跳躍弧線、控制遮節奏格、extra 冒充命中、零輸入也像成功、保存失敗顯示成功、重試殘留上一輪障礙。Checks：獨立 fixture 驗 matched／duplicate／extra／rest／invalid IDs；實際 UIKit touch 命中、zero-input failure／cancel／restart；結果成功／失敗／最後關／save failure；一般與小螢幕、亮暗、最大字級與 Reduce Motion 的 count-in／mid-run／result 截圖。高密度十六分提示要核對。原評分測試不修改 expected 來配合美術。
Rollback：只回復本 slice 呈現/test；角色資產與資料保留。完成代表 UI 循環可操作且 owner 回饋已記錄，不自動宣稱兒童喜愛或真機 timing。若 owner 再拒絕玩法，先測短可玩概念，不能用換色當機制修正。
