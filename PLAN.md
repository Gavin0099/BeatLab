# BeatLab — iOS MVP Roadmap
<!-- governance-baseline: overridable -->
> **最後更新**: 2026-10-05
> **Owner**: BeatLab owner
> **Freshness**: Sprint (7d)

## Current Phase

目前內部試玩版為「拍拍冒險」TestFlight 0.1.0（10），已完成 Release 封存、實際上傳包驗證、Apple 處理與「本人試玩」分發。2026-10-05 owner 以手機截圖確認首頁風格，並指出節拍器／練習風格仍不一致；本輪要求功能盤點、後續 slice 與目前進度 commit／branch push。S0～S17 來源、MET-01 控制、GAME-07 runner 與 HOME-01 首頁均保留；G1～G4、物理 timing／兒童體驗／完整 accessibility 未接受。治理 runtime 自動化仍為既有非阻塞 debt。當前功能與切分見 [功能盤點](docs/design/FEATURE-AUDIT-20261005.md)。

以下為歷史迭代／拒絕結果，來源與當時交付狀態保留：
GAME-03 跳島呈現已建置為 0.1.0（6），owner 判斷玩法不足；其後 PHONE-06 已依明確要求安裝供試玩，仍為未接受草稿。GAME-04 改以可玩「恐龍救援跑酷」概念先確認玩法，並建立 `beatlab-rhythm-game-design` 個人 skill。
GAME-04 畫面被 owner 拒絕；GAME-05 已參考 Nintendo／PlayStation 官方畫面，製作原創森林背景與場景主導的 HUD／操作介面。owner 已拒絕配色與遊戲體驗，尚未套入 App／安裝。GAME-06 先診斷與詢問畫面／核心玩法偏好，替代方向未接受。
GAME-07：owner 真機回報 build 6 節奏格被截斷且仍不像遊戲，並選擇「恐龍跑酷」。已改為單一高度感知遊玩畫面、接近的障礙與跟拍跳躍；既有 matching／星星／解鎖／保存不變。0.1.0（7）已簽署建置，並經 PHONE-07 原地安裝／啟動於 owner iPhone；一般版面／零輸入失敗、最大字級 dark 及短螢幕實際命中／重開 focused checks 已通過；減少動態效果下的實際命中／重開流程也通過。畫風與遊戲體驗仍待 owner 試玩，不宣稱已接受。
產品目標：節拍準、孩子看得懂、練習有成就感。先驗證時間軸，再做互動與課程。

## Active Sprint

本次授權：G0 已提交；owner 明確選擇「完成整個 iOS MVP S0～S17，再統一到 Mac 驗收」，因此允許跨 M1～M4 實作；不代表接受 device gates。主線：G0 → BL-001 → BL-002 → BL-002A → BL-003 → BL-004 → BL-005 → BL-006 → Device Timing Gate → GO / FIX / STOP。
依 owner 最新指示，先完成所有來源實作，再按 BL-002A／G1→G2→G3→G4 順序驗收；缺 PASS 不標 VERIFIED／DONE、不發行。

| PR Slice | 原始 Slice | 範圍與依賴 | 完成標準／證據 | 風險 | 狀態 |
|---|---|---|---|---|---|
| BL-001 Project Foundation | S0 | BeatLabApp、Home／Metronome／Practice；Tempo／TimeSignature／Subdivision／MetronomeConfiguration；四項設定保存；不做 audio scheduling | launch／三頁導航；configuration 單一權威；tempo／拍號／細分／accent 重啟保存；domain boundaries tests；build + tests PASS；無 audio engine | L1 | IN_PROGRESS |
| BL-002 Metronome Audio Engine | S1 | 依 BL-001；BPM 30–240、Start/Stop、sample/host timeline、click scheduling | 30/60/120/240 scheduler 測試；啟停無殘留 click；時間不累加浮點誤差；真機 baseline；中斷／route change 安全停止並需重新 Start | L2 | IN_PROGRESS |
| BL-002A Engineering Timing Sanity | S1 engineering evidence | BL-002 後、BL-003 前；60／120／180 BPM 各 5 分鐘；中斷與復原 | interval distribution／max deviation／cumulative drift／recovery 原始資料；GO／FIX／STOP；不是產品 SLA | L2 | IN_PROGRESS |
| BL-003 Beat Visualizer | S2 | 依 BL-002A GO；4/4 大拍點、高亮、Reduce Motion | UI 讀 engine beat/time snapshot；不另起節拍 clock；音畫同步量測保留原始資料 | L1 | IN_PROGRESS |
| BL-004 Controls + Tap Tempo | S3 | 依 BL-003；slider、±1/±5、tap tempo、音量 | clamp 30–240；顯示 pending BPM；下一個未承諾拍生效；异常 tap/reset 測試；手動改 BPM 清 tap history；音量只影響 gain | L1 | IN_PROGRESS |
| BL-005 Time Signature + Accent | S4 | 依 BL-004；2/4、3/4、4/4、6/8、首拍 accent | 下一小節原子生效；舊小節完成；新小節首拍只有一次；6/8 定義見 Decision Log | L2 | IN_PROGRESS |
| BL-006 Subdivision Engine | S5 | 依 BL-005；Quarter、8th、16th、Triplet | 同 transport 分拍；下一拍生效；快速切換無漏／重拍；6/8 不適用選項不可選；進 G1 | L2 | IN_PROGRESS |

每個 slice 開始前定義 allowed/forbidden files、行為、failure paths、驗證、rollback。
TODO → IN_PROGRESS → VERIFIED → DONE；缺陷標 BLOCKED。實作與測試才可 VERIFIED；必要 review／交付完成才可 DONE。
PR、merge、push 依使用者授權；roadmap PR 名稱本身不代表發送授權。
詳細 gate：[docs/verification.md](docs/verification.md)。

## Backlog

保留四個 milestone 與 S0～S17；BL 編號為交付順序。

| Milestone | PR／Slice | 範圍 | 驗收與依賴 |
|---|---|---|---|
| M1 正常可用節拍器 | BL-001～006 / S0～S5 | 基礎、clock、視覺、控制、拍號、細分 | G1 真機 timing gate PASS 才進 M2 |
| M2 鼓手互動 | BL-007 / S6 | Count Voice：Click / Voice / Both；1 2 3 4、1 & 2 & | 預備 voice PCM、同 clock；onset 個別量測；不依即時 TTS callback 排拍；素材授權；不足分拍 voice 明示 |
| M2 鼓手互動 | BL-008 / S7 | 固定 rhythm lane、R/L、休止符 | 最小 versioned pattern model，lane／target 共用；休止無 target；S10 不重寫 pattern |
| M2 鼓手互動 | BL-009 / S8 | 螢幕 Tap、monotonic timestamp、target matching | engine 同時間 domain；tie-break、最大配對窗、一 target 一次；extra／miss 保留；finger-down timestamp；不從動畫倒推 target |
| M2 鼓手互動 | BL-010 / S9 | Early / Perfect / Late、校正、平均誤差、穩定度、summary | calibration 綁 route，換 route 作廢；signed error／MAE／標準差／miss 分開；threshold 可測；G2 |
| M3 產品 | BL-011 / S10 | Lesson JSON/model、條件、目標 BPM、pattern | 延伸 S7 model；schema version／非法 JSON／未知版本 failure path；新增課程不改 UI |
| M3 產品 | BL-012 / S11 | 10 lessons：四分→八分→休止→16分→R/L | 過關條件固定；10 關全程可玩；child playtest 檢查理解與成就感 |
| M3 產品 | BL-013 / S12 | 星星、解鎖、最佳成績、最佳 BPM | 重啟保存；損壞資料安全回復；best BPM 帶 pattern／accuracy 條件；G3 |
| M4 差異化 | BL-014 / S13 | Gap Click：4 小節 click→靜音 1／2→恢復 | 只 mute output，transport 不停、不重設 phase；預設 visual 繼續並明示 |
| M4 差異化 | BL-015 / S14 | Tempo Ladder：60→65→70，每 N 小節 | 下一小節變 BPM；clamp 240；Gap 組合測試；手動改 BPM 退出 ladder |
| M4 差異化 | BL-016 / S15 | Home / Daily Practice、繼續練習、自由節拍器 | 首開 5 秒知道下一步；無帳號／雲端；本機 continuity |
| M4 差異化 | BL-017 / S16 | Beginner / Standard UI | Beginner 隱藏 ms；手動選模式、不蒐集生日；tap／score model 不分叉 |
| M4 差異化 | BL-018 / S17 | Polish、latency、background、VoiceOver、真機、TestFlight | G4 裝置矩陣 PASS；非第一次處理 interruption／accessibility |

M2～M4 原 backlog 已依 owner 最新授權實作；所有 Apple 與真人驗收仍 NOT RUN。內容與裝置矩陣見 docs/slices/MVP-implementation.md 與 docs/mac-acceptance.md。

### 第一版排除

麥克風真鼓／Kick-Snare 辨識、Bluetooth MIDI、電子鼓 MIDI、帳號、雲端同步、排行榜、朋友系統、AI Coach、自動鼓譜、完整 notation editor。
不申請麥克風權限、不為排除項目搭預留服務；驗證 Tap Timing 後再評估。

## Decision Log

以下為本次具體化 roadmap 的設計預設；實作前可修訂，但需更新決策與測試。

- D01：Swift／SwiftUI、iOS first、本機保存。Windows 可編輯／跑治理；iOS build／真機需 macOS + Xcode + iPhone。deployment target 在 BL-001 固定。
- D02：audio engine 是 transport 時間權威；epoch + musical position 推導時間；UI refresh 只讀、不控制聲音。lead time／已排 buffer 撤回策略在 BL-002 定義。
- D03：2/4、3/4、4/4 BPM 單位為四分音符；6/8 為附點四分音符，每小節兩大拍、每拍三八分，畫面 1-la-li / 2-la-li。6/8 基礎細分為三八分；不直接沿用簡單拍 Quarter／8th／16th 選單，顯示 compound 選項並阻止歧義組合；MVP 不做 compound 六等分。30–240 指顯示大拍單位。
- D04：BPM／Subdivision → next beat boundary；Time signature／Accent pattern → next bar boundary。所有 change 送 engine，由 engine 決定並回報 applied boundary；UI 不決定時序。lead time 不可讓聲音在已宣告的 boundary 後才改，BL-002 定義 queued-buffer 策略；rapid latest request wins、同 boundary 原子套用，不回改已播放時間。
- D05：BL-002 就做 interruption／route change 安全 stop；背景預設停止。background playback 在 S17 決定是否納入與驗證。
- D06：S7 最小 rhythm pattern model，S10 擴展 lesson/conditions；S8 target 來自同 pattern/timeline。
- D07：起步即有大觸控目標、清楚 beat、Reduce Motion、VoiceOver labels；S16 處理資訊密度、S17 補齊 accessibility gate。
- D08：驗收數字是初始產品預算，未量測，不代表裝置保證；調寬需原因／原始證據，不能為 PASS 改門檻。

## Known Risks

- 排程準不代表喇叭 onset／觸控校正準，分別量測與報告。
- 6/8 不可做成六個四分拍；BL-005／006 明示 compound 語意。
- Voice 前導靜音影響 onset；S6 校正素材，Both 避免 clipping。
- 真機長測尚未跑；缺 macOS／真機證據標 NOT RUN，不以 Windows checks 取代。
- 孩子理解／好玩／replay 意願需 playtest；技術 gate 不等於產品驗證。
- 治理為 submodule consumer 初次導入；hooks、CI、平台 lifecycle、validator 分別記錄，檔案存在不代表 enforcement。

- G0：runtime smoke、hooks、領域 validator、memory 自動接線為已接受的非阻塞 KNOWN DEBT；不阻塞 BL-001。BL-002A 是第一輪工程量測，BL-006 是正式固定裝置 gate；本次 owner 將兩者延至整批實作後，沒有視為通過。

- D09：G0 凍結採初始化 a74c8cc → 官方 refresh 記錄該來源 → 凍結 d872bad；freeze checkpoint 工作樹乾淨。BL-001 在 codex/bl-001-app-foundation 實作，iOS 16.0／Swift 5 language mode／SwiftPM tools 5.9，單一 main-actor store 與本機 versioned settings。


- D10：owner 2026-10-04 明確授權 S0～S17 整批來源實作後再到 Mac 驗收，覆蓋舊 implementation stop；device／child／release acceptance 保留。後續 owner 已授權 App commit／GitHub branch push；PR／merge／TestFlight 未執行。
- D11：C11 sample renderer + AVAudioSourceNode；pre-render speech、原子控制／history；Gap 只 mute，Ladder 下一小節 +5；詳 docs/adr/0002-audio-and-practice-timeline.md。
- D12：共用 versioned rhythm JSON → lane／targets；UIKit touch-down 映射 audio host time；最近 target、tie earlier、已命中最近 target 的重複 tap 為 extra。±50 ms Perfect／180 ms 配對窗。過關包含 miss／extra。
- D13：對齊為 user alignment estimate，含人為偏差、route/rate 綁定；未校正／Bluetooth／VoiceOver input 不顯示 calibrated ms；独立 latency／child playtest 待 G2。
- D14：MET-01 每個大拍可循環重音／一般／靜音；整拍的 click／voice／subdivision 輸出一併靜音，transport 不重設。拍點 pattern 與拍號下一小節原子生效；音色下一拍生效。6/8 仍為兩個大拍。設定 v1 只讀載入，使用者編輯才保存 v2；回裝舊版會遇到新版設定鎖定，不自動降版覆寫。

### Implementation batch evidence

| 範圍 | 原始碼 | 尚待驗收 |
|---|---|---|
| S0～S5 / M1 | shell／保存、C render、拍點、Tap Tempo、拍號／accent／細分 | Swift compile/tests、BL-002A、G1 |
| S6～S9 / M2 | Apple speech PCM、lane、touch-down taps、grading／summary／alignment | Voice 清楚度／onset、input latency、G2、child playtest |
| S10～S12 / M3 | versioned JSON、10 lessons、星星／解鎖／best BPM／保存 | 真人 walkthrough／relaunch、G3 |
| S13～S17 / M4 | Gap、Ladder、daily／continue、Beginner／Standard、lifecycle／accessibility／icon／測試腳本 | 真機／VoiceOver／Dynamic Type／最低 OS、G4；未上傳 TestFlight |

Windows 實際 C renderer：156 組（44.1／48 kHz × 30/60/120/137/180/240 × 全支援 meter/subdivision），每組 15 分鐘、總計模擬 39 小時；無漏／重 onset、最大理想位置誤差 0.5 sample。live boundary／restart／silence／Gap／Ladder／voice fixture 與 undefined-behavior sanitizer PASS。這是離線 samples，不是喇叭或 UI 真機 evidence。
35 Swift files source syntax／89-object Xcode membership checks PASS；58 Swift test definitions 尚未執行。Python capture-analysis regression 3 tests PASS；source checks 不等於 Swift compiler。
Canonical evidence：docs/slices/MVP-source-check.json、MVP-dsp-tests.json、MVP-local-verification.json；Mac：docs/mac-acceptance.md。


### UIUX-01

Owner 另授權先完成 UI/UX。已套用 native shared styles/light-dark assets、Home 今日入口、metronome 固定 transport／progressive settings、Practice 準備／進行／結果／課程 sheet、Tap Pad 固定／大字 reflow、鎖定原因、unsaved progress retry／explicit discard。
風險 L1：presentation state/retry 保留 repository authority；不改 DSP／targets／scoring／framework pin。slice：docs/slices/UIUX-01.md。
37 Swift files／93 project objects／61 Swift test definitions，compile/tests NOT RUN；HTML reference 33 layouts 與 26 measured palette pairs PASS。原始 MVP DSP evidence 仍有效。Status IN_PROGRESS：UI source 完成，native rendering／accessibility／child acceptance 待 Mac。

### MAC-01 — First Mac build and phone installation

2026-10-04 owner 授權建置後先安裝到手機，也授權參考字樹花園的安裝、UI/UX、測試與上架流程；此參考不改變 BeatLab 的 timing gates，也不授權 TestFlight 上傳。

- Source：`1258740`；Xcode 26.6／Swift 6.3.3。42 項 SwiftPM tests、156 組 C renderer 長測、3 項 capture analyzer regression tests PASS。
- iOS simulator build 與 Debug iphoneos build PASS；簽署／profile 檢查 PASS。保留 bundle ID `com.beatlab.app`，personal team `P358EB3X9H`；profile 包含 owner 裝置。
- BeatLab 0.1.0（1）已安裝並由 devicectl 成功啟動於 owner iPhone 16 Pro；未解除安裝字樹花園或清除任何 App 資料。
- iOS 18 simulator tests 啟動停滯並中斷，結果 bundle 未完整保存；iOS 26.5 App／UI test attempt FAIL，原因為 testmanagerd socket 不存在、無法與 test runner 通訊。不把 test compile 或 build PASS 當 App／UI tests PASS。
- BL-002A／G1～G4 仍未驗收；安裝啟動不代表節拍／input latency／VoiceOver／兒童體驗／release readiness 通過。
- 下一步：先在手機試用主要流程，處理模擬器測試服務阻礙，再補 App／UI tests 與順序執行 timing、互動、課程和裝置驗收。
- 證據：`docs/slices/MAC-01-verification.json`；原始 logs／簽署／install／launch receipts 在 ignored `TestResults/20261004T094443Z/`。MAC-01 契約：`docs/slices/MAC-01.md`。

### MET-01 — Reference metronome controls

Owner 提供圖片要求加入功能；本輪補齊節拍器控制，scope clarification 的建議範圍已先明示。底部獨立調音器／歌曲清單不在本輪契約。

- 原始碼已實作：逐拍重音／一般／靜音、電子／木魚／機械合成音色、engine-phase 擺針、可選畫面 pulse／震動提示、速度 undo／redo（滑桿一個 gesture 一步）。入門／標準與原本數拍、Gap、Ladder 保留；Practice 使用原本指定 pattern。
- 風險 L2：輸出樣本、mailbox 與 settings v1→v2。失敗路徑包含非法 pattern／音色、快速變更、拍號與速度同時改、全拍靜音後恢復、future schema 鎖定及 undo 寫入失敗保護。契約：`docs/slices/MET-01.md`。
- 驗證：50 項 SwiftPM tests PASS；actual ConfigurationStore 的 macOS harness PASS；C focused harness + UBSan PASS；468 組各 15 分鐘音色長測（117 小時模擬）PASS，最大理想位置誤差 0.5 sample。這些不代表物理喇叭／震動精準度。
- 最新 Debug iphoneos build／codesign／profile PASS：0.1.0（3），com.beatlab.app，包含原生測試發現的識別碼修正。本輪重新確認裝置 available，42 個 production files 與 build manifest 一致；0.1.0（3）已原地安裝並啟動於 GavinWu0099 的 iPhone 16 Pro。install／launch receipts 在 `TestResults/MET-01/phone-build3/`；未解除安裝或重設資料。
- 模擬器 shutdown／boot retry 後成功啟動。原生 App tests 15 項通過；UI 7 個流程取得通過證據（完整重跑中的 6 項及剩餘流程的 focused rerun），不是宣稱單次 full-suite 全綠。最大 accessibility 字級＋dark 的新增控制流程也通過；已有真實 SwiftUI screenshots。
- 原生失敗與修正：DisclosureGroup 外層 identifier 覆蓋拍號／細分，已縮到 label，保存／重啟 regression 通過。拍點測試原先點到固定 transport 下方；改為檢查 viewport、雙向捲動及未載入元素後通過。保留所有失敗／中斷結果；大字測試採獨立輸出路徑與 simulator ad-hoc signing。
- Status IN_PROGRESS：來源、候選版與上述自動操作證據完成；物理 cue／timing、VoiceOver／Reduce Motion、最小螢幕與 G1～G4 驗收仍待完成。沒有新提交、push、PR、merge 或 TestFlight。
- 證據：`docs/slices/MET-01-verification.json`；可重現原始 logs／binary／source hashes 在 ignored `TestResults/MET-01/`。治理 module／canonical memory writer 在此 checkout 尚不可用，沒有手寫 session-derived memory 或宣稱 closeout。

### GAME-DESIGN-01 — Practice as a rhythm quest

2026-10-04 owner 要求設計遊戲式練習。完成無聲互動設計，建議「節奏旅程」，另提供簡潔的「練鼓工作台」選關方式；十關內容沿用現有 catalog，流程為選關 → 準備 → 四拍 count-in → 四小節鼓墊挑戰 → 結果。原生 App 未因本設計修改。

- 設計涵蓋 R/L/休止、即時拍點、停止不計分、過關/重試、最後一關、保存失敗重試與明確放棄。保留原生時鐘、matching、星星與保存成功才解鎖的 authority。沒有新增連擊評分或遊戲經濟。
- 驗證：Chromium 的 28 項檢查 PASS；兩種版型 × 四畫面 × 320/390/736px × light/dark × 1/1.75 倍字級，共 96 組無水平內容裁切、啟用按鈕至少 44px。26 組文字/背景 palette pairs 對比達 4.5:1，20 組結果 fixture 與既有門檻一致。七張截圖已目視檢查。host Tweak 控制未在實際宿主執行，獨立預覽只驗證 guard 與外部狀態還原。
- Status DESIGN_COMPLETE：此階段完成無聲設計稿，當時已安裝的 0.1.0（3）不含遊戲設計；後續 GAME-01 已將「節奏旅程」套入原生 App／0.1.0（4），見下方。瀏覽器設計驗證不代表真機 timing／音畫同步、VoiceOver 或兒童體驗驗收；G1～G4 仍待驗收。
- 契約：`docs/slices/GAME-DESIGN-01.md`；規格：`docs/design/GAME-DESIGN.md`；canonical evidence：`docs/design/game-design-verification.json`；可重現瀏覽器 harness/report/screenshots 在 ignored `TestResults/GAME-DESIGN/`。

### GAME-01 — Native rhythm journey

2026-10-04 owner 要求遊戲介面加入 App。已實作三篇章／十關節奏旅程、真實保存進度與星星、準備畫面、圓形鼓墊、四小節挑戰、實際結果與保存復原。Home 的每日／繼續入口會開啟所選課程的準備畫面；練習設定與完整課程清單保留。

- 風險 L1：只修改 PracticeView、RootView、RhythmLane 三個 production files。既有 audio epoch、elapsed、UIKit touch timestamp、matching window、評分、星星門檻與保存 schema 均未修改；數拍時保留原有 early matching-window allowance。
- 驗證：50 core tests、17 App tests、修正後 6 個 UI 流程 PASS；最大 accessibility 字級＋dark 重跑 3 個練習流程 PASS。App 與最終 UI 證據為分開執行，不宣稱單次完整 suite 全綠。原生截圖已檢視，長內容的鼓墊／停止透過捲動操作驗證。
- 原生測試發現祖先 accessibilityIdentifier 覆蓋關卡與星星識別碼；移除 map 祖先 ID，結果 ID 移到標題後，原先失敗的兩個流程通過。保留 startup 中斷與失敗結果。
- 已建置並驗證簽署 Debug iphoneos 0.1.0（4），42 個 production files 與 manifest 一致；devicectl install／launch PASS，已原地更新 owner iPhone 16 Pro，未解除安裝或重設資料。
- Status IMPLEMENTED_AND_INSTALLED_WAITING_FOR_UNLOCK：原生介面與手機安裝完成；真機遊戲操作、物理 timing、兒童體驗、完整 accessibility／最小螢幕與 G1～G4 仍待驗收。沒有新 commit、push、PR、merge 或 TestFlight。
- 契約：`docs/slices/GAME-01.md`；canonical evidence：`docs/slices/GAME-01-verification.json`；原始 logs／xcresult／screenshots／build／install receipts 在 ignored `TestResults/GAME-01/`。canonical memory writer 尚不可用，沒有手寫 session-derived memory；session end 未成立，沒有 closeout 宣稱。

### GAME-02 — 遊戲夥伴與冒險呈現

2026-10-04 owner 指出遊戲對兒童吸引力不足，並指定字樹花園的貓咪／機器人／恐龍。三個可選夥伴、起拍小島／回聲森林／星光舞台、彎曲路線與真實篇章徽章已加入。選擇只存在當次 View state，圖片是靜態 PNG 加簡單命中／通關回饋。

- Risk L1：相較 build 4 只修改 PracticeView 一個 production file；新增五個 imagesets（十個檔案），52-file manifest 確認其餘時計、UIKit 輸入、matching／評分／保存／catalog 未改。素材 bytes 與固定來源 commit／Git blob／SHA-256 一致，見 `docs/design/game-character-sources.json`。
- 驗證：一般 light 原有 3 個練習流程通過，選擇卡片修正後重驗旅程流程通過；最大字級＋dark 採組合證據：修正前不進入選擇器的每日流程通過，修正後夥伴旅程與零輸入結果共 2 個流程通過。不是單一最終 3 測試套件；保留中斷與失敗結果。 最終 light/dark 夥伴選擇卡片、場景、所選恐龍鼓墊與失敗結果截圖已檢視。歷史 core 50／App 17 保留但本輪未重跑。
- 根因：大字選擇卡片被測試腳本拿來與已被 sheet 蓋住的 tab bar 比較，導致誤報不可見；修正為 sheet viewport，超過捲動預算直接 throw。也縮短 AX 可省略的邀請文案並讓整張卡片可按；失敗與只中斷自己 test process 的紀錄保留。
- Debug iphoneos 0.1.0（5）build／signature／profile／source manifest 與五資產打包 PASS；devicectl install PASS，launch BLOCKED_DEVICE_LOCKED，原地更新，未解除安裝或清除資料。
- Status IMPLEMENTED_AND_INSTALLED_WAITING_FOR_UNLOCK：兒童吸引力仍需試玩；真機遊戲操作、物理 timing、成功徽章畫面、完整 VoiceOver／Reduce Motion、最小螢幕與 G1～G4 仍待驗收。 沒有新 commit／push／PR／merge／TestFlight。
- 契約與 canonical evidence：`docs/slices/GAME-02.md`、`docs/slices/GAME-02-verification.json`。原始候選／hashes／logs／xcresult／screenshots／install receipts 在 ignored `TestResults/GAME-02/`。canonical memory writer 尚不可用，未手寫 session-derived memory；session end 未成立。


### BRAND-01 — 拍拍冒險品牌採用

2026-10-05 owner 選定 A「拍拍冒險」與黃底綠色恐龍跳躍 icon。L0 presentation slice：套用 Debug/Release display name、首頁標題與相關提示，保留 com.beatlab.app 與原保存識別。選定原始圖與來源說明保存於 docs/design/branding；不更換遊戲角色或修改節奏／評分。Status IMPLEMENTED：simulator build 與既有 FoundationUITests 2 項通過；App 包內名稱與 icon 打包已確認。未變更 App Store Connect、未安裝手機、未上傳送審；名稱／商標查重未完成。契約 docs/slices/BRAND-01.md；證據 docs/slices/BRAND-01-verification.json。


### TF-01 — Owner TestFlight trial

2026-10-05 owner 明確授權上傳「拍拍冒險」到 TestFlight 供本人測試，再決定是否正式上架；不包含 App Store 送審或公開測試。L1：SystemBootTime 理由、加密宣告、build 9 與必要識別碼修正；不改時計／評分／保存。Status TESTFLIGHT_OWNER_TRIAL_AVAILABLE：50 core tests、Release 封存、發佈 IPA 與 53 個來源檔案檢查通過。com.beatlab.app 被 Apple 拒絕為已佔用，改用本人命名空間 com.gavin0099.beatlab；舊開發版紀錄不自動帶入。App 記錄 6819149808 與手動分發「本人試玩」群組已建立。2026-10-05 13:30 Xcode GUI 上傳 0.1.0（9）成功；實際上傳 IPA 已匯出並驗證 internal-only／distribution signature、icon 與 privacy。GUI recommended manageAppVersionAndBuildNumber=true，實際 build 仍 9。Apple 已完成處理；群組包含 1 位本人、1 個 build，版本狀態「正在測試」，本人「已邀請」，繁體中文測試內容已儲存。Owner 已回報下載並提供首頁截圖；安裝由 owner 執行，沒有新的 devicectl 安裝證據。只完成內部試玩分發；G1～G4／正式上架 readiness 仍未接受。無新 commit／push／PR／merge。契約 docs/slices/TF-01.md；證據 docs/slices/TF-01-verification.json。

### HOME-01 — 首頁品牌一致

2026-10-05 owner 回報已下載 TestFlight build 9，首頁仍紫色工具卡片、和黃底綠恐龍 icon 不一致。Status LOCAL_NATIVE_UI_CHECKS_PASS_OWNER_STYLE_PENDING：已依選定 icon 重做原生首頁，加入同角色衍生插畫、暖黃／深綠配色、今日冒險與實際進度；保留推薦／解鎖／設定／導航。最大字級標題使用全寬，整頁捲動與底部留白使操作可到達。最終 simulator build、4 項一般／最大字級 navigation 和設定重新啟動測試、2 項 iPhone SE 375×667 流程、1 項 dark 最大字級流程通過，共 7 項／0 失敗；已檢視原生截圖，列出的文字色對比最低 5.71。初次新 simulator 的 runner 啟動錯誤保留，不推論為 App 測試失敗；改用先前 BeatLab 專用裝置完成測試。臨時磁碟滿造成截圖複製失敗，清除本次未使用測試裝置後重試成功，其他裝置不動。61 個 production file hashes 核對通過，現有 production 只改 HomeView／RootView tint／BeatLabStyle 品牌 additions；icon 與 gameplay／timing／score／保存不變。新首頁未上傳 TestFlight／未安裝手機；手機已下載版仍 0.1.0（9）。畫風／兒童體驗、真機 timing、G1～G4／上架 readiness 待 owner 驗收；無新 commit／push／PR／merge。契約 docs/slices/HOME-01.md；canonical evidence docs/slices/HOME-01-verification.json；原始 receipts／xcresult／截圖在 ignored TestResults/HOME-01/。

### TF-02 — 新首頁 TestFlight 更新

2026-10-05 owner 已接受 HOME-01 原生截圖並明確授權推到 TestFlight。Status TESTFLIGHT_OWNER_TRIAL_AVAILABLE：Release 封存與實際上傳 IPA 的簽署、61 個 production hashes、新首頁素材、原 icon 與 privacy 核對通過；既有七項 HOME-01 native checks／50 項 core tests 以相應 source hashes 一致沿用，本輪未重跑。2026-10-05 14:28 Xcode GUI 成功上傳 0.1.0（10），recommended manageAppVersionAndBuildNumber=true，實際 build 仍 10。已匯出實際上傳包，Assets.car 與本次封存一致、internal-only=true；沿用 com.gavin0099.beatlab／P358EB3X9H。Apple 已完成處理，新版加入既有「本人試玩」一位內部 tester 群組，顯示「正在測試」，繁體中文新首頁測試說明已儲存；build 9 保留。新版手機更新／實機驗收待 owner 執行，G1～G4 與正式上架 readiness 仍未接受；無新增 tester／外部測試／App Store 送審／commit／push／PR／merge。契約 docs/slices/TF-02.md；canonical evidence docs/slices/TF-02-verification.json；實際 IPA／logs／screenshots 在 ignored TestResults/TF-02/。

### 2026-10-05 — 三頁風格一致：功能盤點與後續切分

Owner 確認首頁風格，但拒絕節拍器／練習與首頁的落差。本輪 PROGRESS-01 只整理功能與六個契約、保存目前來源；未改 App／build／規則。本人手機截圖未顯示版本號，不能從截圖確認精確 build；本人回饋視為首頁畫風接受，不能推廣成三頁／十關或 G1-G4 通過。

| 順序 | Slice | 範圍 | 風險 | 狀態 |
|---|---|---|---|---|
| 1 | UI-BRAND-01 | 共用品牌 tokens、按鍵、狀態、tab／sheet 與角色造型指南 | L1 | PLANNED |
| 2 | MET-02 | BPM／拍點／播放主次、聲音與提示、全控制回歸 | L1 | PLANNED |
| 3 | GAME-08 | 旅程、夥伴、關卡準備與 settings／sheet | L1 | PLANNED |
| 4 | GAME-09 | runner 場景、節奏、跳／停止、結果與保存復原呈現 | L1；時計／評分更動升 L2 | PLANNED |
| 5 | QA-01 | 三頁／十關／字級／亮暗／小螢幕與 accessibility；真機 gate 缺口 | UI L1／timing L2 | PLANNED |
| 6 | TF-03 | 接受新版候選後的本人內部 beta | L1 | PLANNED；等待候選與其交付授權 |

契約均列出 exact allowed/forbidden files、依賴、failure checks 與 rollback。本輪沿用已保存的節奏遊戲 skill，沒有重新廣搜參考／新增 artwork。core／C boundaries／capture 新跑結果、source manifest 和 Git delivery 以 docs/slices/PROGRESS-01-verification.json 為準；歷史 native receipts 保留但不算本輪重跑。Push 既有 codex/bl-001-app-foundation；不包含 PR／merge／新 beta 或 App Store 發行。
