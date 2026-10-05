# BeatLab 驗收與證據

> **目前基準（2026-10-05）**：TestFlight 0.1.0（10）已提供本人試玩，Release／實際上傳包／Apple 處理／群組可測已驗證。Owner 手機回饋接受首頁風格，節拍器與練習待六個後續 slice。下面各舊 build 與未上傳敘述是歷史狀態；最新交付以 TF-02 evidence 為準。G1-G4、物理 timing、三頁／十關完整 accessibility 與兒童體驗仍未接受。此輪 PROGRESS-01 只分析、checkpoint 與 Git push；沒有重跑整個 native suite。
> [目前功能與切分](design/FEATURE-AUDIT-20261005.md) · [當前 beta](slices/TF-02-verification.json) · [checkpoint evidence](slices/PROGRESS-01-verification.json)


## GAME-05：視覺改版草稿（owner 已拒絕）

owner 已指出顏色不符合且遊戲不好玩；先前操作驗證不能取代這個接受結果。原創背景／精簡 HUD／大角色與落地光圈已套入隔離的瀏覽器概念；原生 App 未修改。核心 browser clock／判定／生命／通關函式與 GAME-04 比對一致，新增場景觸控仍接同一個 press。開始／暫停／重試、零輸入失敗、真實 DOM tap 命中、duplicate／extra 及通關都有檢查；小螢幕 light／dark 與圖片需分開人工檢視。這些不證明兒童吸引力、native timing 或 G1～G4。原始命令、來源與圖像見 `docs/slices/GAME-05-verification.json`。

## GAME-03／GAME-04：玩法重想

GAME-03 原生跳島草稿：50 core／24 App（含 7 個獨立 presentation fixtures）通過；一般 light 與最大字級 dark 各 3 個原生流程通過。App 測試在單純鼓墊高度／識別碼修正前完成，模型及 authority 未變；保留最初 compile failure 和 2 個 native UI failures。確切來源邊界見 `docs/slices/GAME-03-verification.json`。這不代表 GAME-03 玩法被接受；owner 已拒絕，簽署 build 6 未安裝，手機仍為先前 build 5。

GAME-04 以隔離的瀏覽器救援跑酷概念重新檢查玩法。概念音訊／判定／生命只供試玩，不接入原生時間軸、星星或保存。真正遊戲的原生實作需新契約，不能把瀏覽器結果當成真機精度、兒童吸引力或 G1～G4 驗收。個人 skill 已保存五個官方參考及 owner 回饋。

## GAME-02 遊戲夥伴與冒險呈現

GAME-02 已加入貓咪／機器人／恐龍夥伴、三個冒險場景與篇章徽章；最新 BeatLab 0.1.0（5）已原地安裝於 owner iPhone 16 Pro。啟動被手機鎖定阻擋，待 owner 解鎖。 三種夥伴、三個場景、路線及篇章徽章沿用真實 grade／已保存星星。只改 PracticeView 與新增五個原始 imagesets；來源與 52-file manifest、簽署/profile、素材打包、install 已確認；launch 狀態以此節摘要與 receipt 為準。

一般 light 原有 3 個練習流程通過，選擇卡片修正後重驗旅程流程通過；最大字級＋dark 採組合證據：修正前不進入選擇器的每日流程通過，修正後夥伴旅程與零輸入結果共 2 個流程通過。不是單一最終 3 測試套件；保留中斷與失敗結果。 最終一般／大字深色的選擇器、場景、鼓墊與實際零輸入失敗畫面已檢視。修正 sheet 可視範圍／fail-fast 測試腳本與大字卡片後重跑，未改音訊／輸入／評分。歷史 core 50／App 17 未重跑，不能累計成新增流程。完整原始與來源邊界見 `docs/slices/GAME-02-verification.json`。

兒童吸引力仍需試玩；真機遊戲操作、物理 timing、成功徽章畫面、完整 VoiceOver／Reduce Motion、最小螢幕與 G1～G4 仍待驗收。

## GAME-01 原生遊戲介面

「節奏旅程」已套入原生 App：三篇章十關、真實星星與解鎖、準備／圓形鼓墊挑戰／結果、保存重試與放棄。既有 audio/input clock、matching、評分與 persistence 未修改。50 core tests、17 App tests、最終 6 個 UI 流程 PASS；最大 accessibility 字級＋dark 重跑 3 個練習流程 PASS。保留 package resolution 中斷及祖先識別碼覆蓋造成的 2 個 UI 失敗，修正後通過；App 與最終 UI 為分開執行，沒有單次 full-suite 全綠宣稱。

Debug iphoneos 0.1.0（4）建置／簽署／owner profile coverage PASS，42 個 production files 與 build manifest 一致；已原地安裝並成功啟動於 owner iPhone 16 Pro。契約與精確結果見 docs/slices/GAME-01.md、docs/slices/GAME-01-verification.json。原生截圖檢視與大字捲動操作通過，不代表完整 accessibility 或真機操作驗收。真機音畫／輸入 timing、兒童體驗、最小螢幕／最低 OS 與 G1～G4 仍待驗收。

## MET-01 圖片參考功能

逐拍重音／一般／靜音、三種合成音色、擺針、畫面／震動及 tempo undo／redo 的契約在 docs/slices/MET-01.md。50 項 core tests、actual store macOS harness、C focused／UBSan 與 468 組離線長測通過；Debug iphoneos 0.1.0（3）build 與簽署通過。模擬器重啟後已取得 15 項 App tests、7 個 UI 流程的通過證據（含修正後 focused rerun），最大字級／dark 控制流程通過。保留原先 startup 中斷、UI 失敗與後續修正證據，不宣稱單次 full-suite 全綠。原生截圖與精確結果在 docs/slices/MET-01-verification.json。 0.1.0（3）已由 devicectl 原地安裝並成功啟動於 owner iPhone 16 Pro；本次安裝未執行額外真機 timing 或功能驗收。

手機驗收需涵蓋：四種拍號逐拍切換、靜音包含細分與數拍、下一小節生效提示、音色播放中切換、Gap／Ladder 組合、volume 0 的畫面／震動模式、關閉／背景／中斷不再產生提示、Reduce Motion 保留高亮但停用擺針與 pulse、VoiceOver 逐拍狀態、大字 reflow、undo／redo 與重啟保存。新音色與逐拍靜音改動需重新取得受影響 G1 output／sync evidence；離線 sample 與 UI haptics 不能作物理精準度宣稱。

## 每個 slice

契約記錄目的、scope、風險、依賴、邊界、failure paths、測試與 rollback。
報告包含 framework pin、產品 commit（未 commit 寫 uncommitted）、裝置／OS／build、命令／結果、原始 artifact、未測項。
缺證據 NOT RUN／UNKNOWN；失敗 FAIL，不當 PASS。低風險文字修改不需 implementation-mirroring tests。

## G0 — Freeze Governance Baseline

Static governance checks PASS、framework lock／gitlink／nested HEAD 一致、G0 提交後 working tree clean。Runtime smoke failure 作 KNOWN DEBT，不阻塞 BL-001。初始 unborn repo 需先有 provenance commit，再由官方 refresh 記錄來源；不造 source_commit。

## BL-001 Done Gate

App launches；Home → Metronome → Practice navigation；configuration 單一 source of truth；tempo／timeSignature／subdivision／accentEnabled 跨 relaunch 保存；domain boundary tests；無 audio scheduling；iOS build + tests PASS。
Swift package tests 僅證明 domain／storage，不可代替 simulator App launch／UI test。缺 Apple toolchain 時 BL-001 維持 IN_PROGRESS。

## BL-002A — Engineering Timing Sanity Check

BL-002 後、BL-003 前，60／120／180 BPM 各連續 5 分鐘。保存原始 timestamps／capture、裝置／OS／route／build／sample rate／方法。報告 interval distribution、max deviation、cumulative drift、interruption recovery。
這是工程 evidence，不是產品 SLA：review 後判 GO（架構值得繼續）、FIX（先修 scheduler）、STOP（方法／架構不足）。原規則為沒有粗量測證據不進 BL-003；2026-10-04 owner 明確授權整批 S0～S17 先實作、後 Mac 驗收，此 implementation gate 已調整，BL-002A acceptance 仍 NOT RUN；正式產品數字仍由 BL-006 的 G1 驗收。

## G1 — BL-006 後，進互動前

固定 iPhone／iOS／build／route，至少內建喇叭路徑；Bluetooth 不作第一版 timing／score 精準度宣稱。
BL-002 先建立量測工具，G1 不只看 callback log。

| 面向 | 程序 | 初始驗收預算／標準 |
|---|---|---|
| Scheduler | 30／60／120／240 BPM、全支援拍號／細分，虛擬時間或 offline render 各 15 分鐘 | 無漏／重拍；理想 sample index 誤差 ≤1 sample；比較起點與末端，不只看平均間隔 |
| 真機 audio | 60/4-4/quarter、120/4-4/16th、240/4-4/16th、60/6-8/base 各連續 15 分鐘；外部 capture onset 比理想時序 | 扣除一次固定 output offset 後 error p95 ≤5 ms、max ≤10 ms；末一分鐘 residual median 相較首一分鐘 ≤5 ms；零可歸因 engine 的漏／重拍 |
| 音畫同步 | 同步記錄聲音 onset 與畫面高亮，至少 100 beats；量測解析度足以支撐結果 | error p95 ≤33 ms、max ≤50 ms；解析度不足 UNKNOWN；Reduce Motion 保留高亮 |
| Live changes | 另測 BPM 30↔240、全拍號／支援細分、快速連點，保存 effective boundary log | phase 連續；無漏／重拍；拍號下一小節；BPM／細分下一未承諾拍；pending／applied 一致 |
| Lifecycle | Stop/Start 20 次、背景／前景、中斷、route change | stop 後无舊 queue；無 double-start；安全停止；route／interruption 需重新 Start |

數字為初始產品預算，未經真機驗證。capture 自身 clock drift／noise／resolution 必須記錄；未校驗儀器不能宣稱 engine 精準度。
全列 PASS 才通過；單一長跑不取代矩陣。保留原始 capture／timestamps／分析方式／結果／簽核。
使用者或指定 reviewer 接受實測才驗收 M2；本次 owner 另授權在驗收前完成 M2～M4 原始碼，不等於 gate PASS。engine／timing contract 改動重跑受影響項。

## G2 — BL-010 互動驗證

- target matching：early/late、tie、miss、extra、休止、重複 tap、最後一拍；一 target 最多一次。
- error = calibrated input time − target audible time。聲音 onset 校正與 input 路徑假設皆記錄，不只減 scheduled time。
- calibration 綁 route／sample rate，換 route 作廢。未校正可練習，不顯示已校正精準 ms 成績。
- 已知 injected offsets 與獨立真機 capture 驗證；不能把所有 tap 校正成 Perfect。
- Perfect 初始 ±50 ms；Early <−50、Late >50，為體驗設計、非硬體準確度。matching window／評分 threshold 分開。
- mean signed error／MAE／standard deviation／miss／extra 分別記錄，Beginner 隱藏 ms。
- 最少三位目標年齡使用者短時觀察，採監護人同意、不保存身分／影音：理解 beat、完成 tap、理解回饋、願意再玩。探索結果不等於普遍有效。

## G3 — BL-013 課程驗證

10 lessons walkthrough；非法 JSON／未知版本；不改 UI 新增課程；星星／解鎖／best score 重啟保存；損壞資料回復／migration。
過關包含 hit rate／miss／extra，不能只用已配對 taps 平均誤差。

## G4 — BL-018 Release Gate

BL-001 固定 OS；release 至少測最低支援 OS／目前支援 OS 真機、最小支援螢幕／較新 iPhone。
audio matrix、Gap 回拍、Ladder／手動、語音、長時間／lifecycle、保存、10 關／daily practice、Dynamic Type／Reduce Motion／VoiceOver／contrast／觸控、crash、素材授權。
background playback 納入就驗證 route／lock screen／interruption，否則安全停止。
逐列 PASS／FAIL／NOT RUN，不自動勾選。TestFlight 上傳另需使用者授權／Apple provisioning 環境。


目前完整來源驗收入口：docs/mac-acceptance.md。S17 來源含安全 background stop、VoiceOver controls、Reduce Motion、Dynamic Type 配置與 release checklist；Apple rendering／device checklist 尚未執行。

GAME-04 瀏覽器操作與完整通關檢查通過：開始／暫停／重試、零輸入失敗且不給能量、實際敲擊命中、重複／多按後果與成功抵達；320px 深色／Reduce Motion 版型已檢視。只證明概念可操作；owner 接受與兒童試玩仍待確認。精確來源、方法及保留嘗試見 `slices/GAME-04-verification.json`。

PHONE-06（2026-10-04）：既有簽署 build 6 的 52 個來源檔與 executable／Assets.car hash、簽章及 owner profile coverage 驗證通過；原地安裝 PASS，開啟因 Locked 阻擋。未重建、未刪除資料；真機操作與既有 timing／child／release gates 未因此通過。見 `slices/PHONE-06-verification.json`。

GAME-07：11 項呈現 fixtures 通過；修正後一般尺寸 2 個流程、最大字級 dark 1 個可達性流程、iPhone SE 3 短螢幕 2 個版面／真實觸控跨障礙／重新開始流程通過。保留初次元件 ID 檢查失敗與零測試 filter 的結果；零測試不算驗證。完整矩陣、來源／簽章與尚未安裝狀態見 `slices/GAME-07-verification.json`。沒有改 timing／matching／星星／保存權威；focused checks 不代表好玩、child／full accessibility／G1～G4 或 release 通過。

GAME-07 補驗：專用 SE 3 模擬器實際設定「減少動態效果」開啟，真實觸控命中／重新開始 1 個流程通過，截圖已檢視；設定恢復關閉。僅本次擁有的兩台模擬器恢復偏好並關機，其餘模擬器未變動。

PHONE-07（2026-10-05）：來源／artifact hash、簽章、bundle/build/platform 與 owner profile coverage／有效期通過；既有 GAME-07 build 7 已原地安裝並成功啟動。沒有重建或重跑未改動測試，未刪除 learner data；安裝／啟動不等於真機遊戲體驗或 timing／release gates 通過。見 `slices/PHONE-07-verification.json`。
