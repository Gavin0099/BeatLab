# Rhythm Swing 參考：BeatLab 下一輪六個 slice

日期：2026-10-07。Owner：「好的，先幫我切出 slice」。本輪授權是切分與文件化，以下實作狀態全部 PLANNED；沒有開始 App、素材、判分或新 TestFlight 上傳。

## 本次規劃的範圍與驗證

風險 L0，僅修改本文件、docs/slices/GAME-16.md 至 GAME-19.md、QA-02.md、TF-05.md、PLAN.md，以及 canonical writer 產生的規劃 milestone memory／evidence。ignored TestResults/RHYTHM-SWING-PLAN-01 僅存來源快照與文件檢查收據。
禁止本輪修改 App/Core/DSP/音訊/測試/資源/project、既有交付證據、protected base／framework或個人 skill。檢查六片的依賴、exact-file 邊界、失敗／rollback、驗收 gate與95個原生輸入未改。規劃回退只移除本次新增規劃與 PLAN 新章，memory保留歷史而不直接刪改。這些檢查不證明遊戲好玩或 iOS timing。

## 核對過的起點

- 個人 TestFlight 最新交付：0.1.0（11），TF-04，GAME-15 e2aeec5；手機更新與流暢度接受仍待 owner，不能推定本輪已玩過或已拒絕（11）。
- `PracticeStore.start` 的任務入口限定 `first-beat` 且60 BPM。課程是4拍數拍、4小節×4拍=16個右手目標，挑戰約20秒，加既有判分結束窗口；不是新建30秒關卡。
- 目前已用 SpriteKit 持續場景、host-time呈現、8個跑步／6個跳躍動作幀，並有三角色／物品／目的地、命中提示與原星星結果。不是從靜態貼圖或零遊戲狀態開始。
- 仍有第一關硬編碼的障礙／漏拍／BPM／總數呈現；既有窄畫面／XXXL與physical profiling未過項目不能被新 slice 覆蓋。

## 官方參考與採用範圍

2026-10-07已核對官方說明與 play／practice 示範靜態畫面，沒有實機試玩、量測其FPS或輸入延遲：

| 來源 | 核對到的內容 | BeatLab 採用提案 |
|---|---|---|
| [Learn](https://rhythmswing.com/index.php/learn/) | 新節奏短教學、看與聽樂句後再練習 | 本輪用短操作引導及既有4拍數拍；不新增教學影片系統 |
| [Practice](https://rhythmswing.com/index.php/practice/) | 音符對錯、太早／太晚／長度不足／漏拍原因 | 遊玩中簡短回饋，結果解釋實際錯誤；練鼓保留一次敲擊一次判定 |
| [Play](https://rhythmswing.com/index.php/play/) | 跟拍前進、錯拍跌落、3錯結束 | 借用可見前方路線及操作後果，沿用既有星星成敗；不採3次錯誤生命制 |

採用玩法結構，不複製其角色、背景、音樂、品牌或關卡。官方畫面上方樂句／下方冒險的分區是構圖參考；BeatLab先讓場景與短拍點提示清楚可見。KidsCharacterKit仍依 owner 指示延後，不先引入。

## 執行順序

| 順序 | Slice | 交付物／風險 | 通過才往下 |
|---|---|---|---|
| 1 | [GAME-16](../slices/GAME-16.md) | 第一關可操作短概念，L1（隔離瀏覽器） | 真實輸入的成功／失敗／重試；owner看懂目標與下一拍、願意再試 |
| 2 | [GAME-17](../slices/GAME-17.md) | 原生節奏路線與只讀事件，L2 | target／音樂／障礙同一時間來源；QA-02A |
| 3 | [GAME-18](../slices/GAME-18.md) | 原生起跳、落地、失誤銜接，L1／clock更動升L2 | 命中／extra／miss後動作連續且下一拍可接；QA-02B |
| 4 | [GAME-19](../slices/GAME-19.md) | 引導→挑戰→結果→重試，三角色共用，L1 | 三角色、尺寸、真實結果與保存失敗路徑；QA-02C |
| 橫跨2–4及最後 | [QA-02](../slices/QA-02.md) | 原生回歸、真機同步／frame pacing／兒童試玩，L2 | 分開記錄工程PASS與owner／孩子接受；既有未過項不可隱藏 |
| 6 | [TF-05](../slices/TF-05.md) | 已接受候選的本人TestFlight交付，L1 | 精確包／Apple處理／本人群組可下載分別成立 |

QA-02不是第五步才開始。GAME-16的 owner concept gate 不等於原生動作接受；每個 native slice 都需自己驗證。任何 gate 未通過，修當片或停在具體缺口，不以增加內容跳過。

## 這一輪固定規則

聽拍→預判→敲擊→即時起跳／失誤回饋→看到目的地接近→依真實結果通關／再試。命中目標只處理一次；extra不清障礙、不推進獎勵；miss保持miss，恢复只讓下一拍可玩；休止不敲且不生成命中障礙。

視覺連續行進不是成績。動畫、落地位置與碰撞不得決定判分、targets、音訊節拍或保存。既有early／late但matched的輸入仍依原判定成功，不改成Perfect-only。

GAME-17至GAME-19第一輪仍限定現有第一關60 BPM；其他BPM／九關保持現有練習路徑，必須smoke確認沒有退化。一般化資料不等於已授權全面跑酷、新模式、更多角色／skin／貨幣／生命／曲庫。

最終成功標準：首次10秒內知道要做什麼；能預判下一個拍點；按下與角色反應有明確因果；整句失敗可以理解並重試；真機動作與音樂同步；實際孩子能理解跟拍且願意再玩。10秒是驗收目標，不是已量測結果。

## 授權與交付邊界

本輪六片皆PLANNED，只完成可審閱的切分。後續依 owner 執行指示啟動；不得把切分完成當作新App／素材實作或TF-05上傳授權。TF-05僅既有本人內部測試，公開TestFlight／App Store與PR／merge另立交付決策；TF-03及G1-G4仍pending。
