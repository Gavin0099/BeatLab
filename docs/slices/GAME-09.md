# GAME-09 — 跑酷遊玩與結果的品牌一致

狀態：IN_PROGRESS；L1，依賴 GAME-08 角色與既有 GAME-07 runner。目的：把角色、障礙、場景、節奏提示、操作和結果做成同一畫風的短練習循環；美術接受與好玩分別觀察。

Allowed files：`BeatLab/Views/PracticeView.swift` 的 runnerChallenge／runnerContent／runnerRhythm／runnerStage、feedback 色彩與 resultPanel／AdventureFinish 呈現；`BeatLab/Views/RhythmLane.swift` 的 display styles；`BeatLabUITests/PracticeUITests.swift`、`BeatLabTests/PracticeStoreTests.swift` 中純呈現 fixtures；`docs/design/branding/runner-layout.md`；本 evidence／PLAN。
Forbidden：PracticeStore、TapPad／UIKit input、Audio／DSP／Sources、課程與評分／保存；RhythmJumpPresentation.record／cueStep、RhythmRunnerPresentation 時計公式；latestHit 的判定／input 時戳與 lifecycle 邏輯；新生命／道具經濟／碰撞評分／新音樂排程。新增 soundtrack／更改節奏密度若需要，另立 L2 機制契約。

契約：短 HUD＋主要場景＋清楚節奏格＋單一「跳」與停止入口，一個高度感知 composition，短高度／大字一起捲動。只從既有 elapsed／targets 畫石頭；命中才清除並跳起，extra 無清除，miss 保留失敗後果，休止沒有石頭且必須等。先聽四拍再開始。獎勵／結果讀實際 summary；save 未成功不展示已解鎖；重試／下一關／最後一關／保存重試／放棄都保留。Reduce Motion 靜態位置、高亮和可操作 pad，避免動畫決定結果。

Failure paths：場景遮文字／跳躍弧線、控制遮節奏格、extra 冒充命中、零輸入也像成功、保存失敗顯示成功、重試殘留上一輪障礙。Checks：獨立 fixture 驗 matched／duplicate／extra／rest／invalid IDs；實際 UIKit touch 命中、zero-input failure／cancel／restart；結果成功／失敗／最後關／save failure；一般與小螢幕、亮暗、最大字級與 Reduce Motion 的 count-in／mid-run／result 截圖。高密度十六分提示要核對。原評分測試不修改 expected 來配合美術。
Rollback：只回復本 slice 呈現/test；角色資產與資料保留。完成代表 UI 循環可操作且 owner 回饋已記錄，不自動宣稱兒童喜愛或真機 timing。若 owner 再拒絕玩法，先測短可玩概念，不能用換色當機制修正。

Owner 修訂：核心 loop 必須形成聽到拍點→看 upcoming cue 預判→真實 touch 操作→即時視覺／聲音回饋。Perfect 用已判定 hit 驅動跳躍／落地效果／當次 combo／場景回饋；combo 只作可重置的呈現，不保存、不改星星。Miss 要有可理解的失誤、恢復及下一拍提示；extra 不冒充成功，休止仍等。先驗一小段真可玩的 loop，不新增篇章／Skin／角色／模式。

Feedback sound 若新增或改音訊路徑，先擴 exact allowed file contract 並升 L2，驗負載、聲音遮蔽、timing 與 failure；不得用動畫／UI Timer 排聲音，也不得把既有 click 聲稱為新增 input feedback 已完成。本輪已實作呈現部分；新增 input feedback 音效仍未實作。

Embedded QA-01C：當片真機 timing、音畫同步、touch response、frame pacing／掉幀驗證，缺證據不能以漂亮畫面或 simulator PASS 當無 regression。

Implementation boundary extension (before edits)：允許 `BeatLab/Resources/Assets.xcassets/RunnerIsland.imageset/{artwork.png,Contents.json}` 與 `docs/design/branding/runner-art-sources.json` 新增一張共用原創 scene background；不增 Skin／角色／模式。允許 PracticeView 的 latestHit observer 額外記錄 transient combo／presentation grade，只讀既有 `jump.record` 成功與 hit.grade，不更改判定、input、targets；開始／停止／重試清除。漏拍回饋只從已過 matching deadline 的未接受目標呈現，稱「這拍沒跨過」；不新增 score 或宣稱實測 latency。新增音訊 feedback 尚未在 allowed boundary，不做其完成宣稱。

Recovery 呈現 buffer 採現有 matchingWindow 180ms + schema 允許的最大 calibration offset 250ms，寧可較晚提示，也不提前把仍可配對的目標顯示漏拍。純呈現 fixture 驗 buffer 前後、休止、matched、非法 position；score 與 session 完全不改。

Observed viewport defect：narrow native 截圖的 scene overlay 遮住恐龍頭；prompt 移至 scene 上方同一 composition（保留 jumpCue identifier），角色高度按場景限制，jump arc 只做視覺限幅，不改 hopTask／input／判定。重驗 narrow count-in、mid-run、matched／restart 與 maximum text。
