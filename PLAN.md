# BeatLab — iOS MVP Roadmap
<!-- governance-baseline: overridable -->
> **最後更新**: 2026-10-09
> **Owner**: BeatLab owner
> **Freshness**: Sprint (7d)

## Current Phase

Owner已釐清卡點為「拿不到一星解鎖」。GAME-34調整前兩關一星：16拍至少命中12拍、最多多按4次，不要求Perfect；二／三星精準門檻保留，第三至十關及音訊／匹配窗口／保存schema不變。本機Core59/App115/實際UI3已通過，含保存失敗／重試；來源39f39d1的matching簽署Debug13已透過Wi-Fi原地安裝並成功開啟，未上傳Apple；真機timing/FPS／兒童接受仍pending。[評分切片](docs/slices/GAME-34.md)。

2026-10-09 owner真機回報第二關左右控制區顛倒，並詢問解鎖／下一關難度。GAME-33已修正左手在左、右手在右，原本反向的測試期待也已改正；本機窄螢幕一般Light、最大字級Light/Dark共3個實際流程通過，R/L音樂序列、判分與進度規則保留。來源ac9893c的修正版已本機簽署、透過Wi-Fi原地安裝並成功開啟；未更新TestFlight。當時診斷前兩關一星需命中14/16、Perfect9/16、最多多按1次，第二→第三操作間隔0.923→0.5秒；後續owner釐清為一星解鎖，前兩關門檻現已由GAME34調整，關卡節奏未變。[修正契約](docs/slices/GAME-33.md) · [難度診斷](docs/slices/GAME-33-difficulty-analysis.md)。

以下是上一個十關整合交付基準：十關來源與本機整合Gate已通過，來源1acee70的「拍拍冒險」Debug 0.1.0（13）已透過Wi-Fi原地安裝；自動開啟被手機鎖定擋住。TestFlight仍是之前GAME23的0.1.0（13），本批沒有Apple上傳。GAME26–31已接入第二至第十關與共享動作／結果收尾；保留第一關素材、音訊／輸入時間軸、匹配、評分與保存。新操作驗證8項通過，加上相同元件的三角色操作3項、原生2項、App113/Core53證據，不能稱最終新編譯host完整重跑113。G1～G4、真機timing/FPS、完整Accessibility及兒童體驗仍未接受；治理runtime自動化仍是既有非阻塞debt。[十關切分](docs/slices/NIGHT-01-lesson-plan.md) · [本機驗證](docs/slices/QA-NIGHT-01-verification.json) · [手機交付](docs/slices/PHONE-10-verification.json) · [試玩清單](docs/slices/NIGHT-01-owner-trial.md)。

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
| 1 | UI-BRAND-01 | 共用品牌 tokens、按鍵、狀態、tab／sheet 與角色造型指南 | L1 | IN_PROGRESS；foundation QA 當片 |
| 2 | MET-02 | BPM／拍點／播放主次、聲音與提示、全控制回歸 | L1 | IN_PROGRESS；native QA 與 owner 接受分列 |
| 3 | GAME-08 | 旅程、夥伴、關卡準備與 settings／sheet | L1 | IN_PROGRESS；native QA 與 owner 接受分列 |
| 4 | GAME-09 | runner 場景、節奏、跳／停止、結果與保存復原呈現 | L1；時計／評分更動升 L2 | IN_PROGRESS；視覺 feedback，音效／真機仍待 |
| 5 | QA-01 | 三頁／十關／字級／亮暗／小螢幕與 accessibility；真機 gate 缺口 | UI L1／timing L2 | IN_PROGRESS；foundation／A／B／C 當片與 Final |
| 6 | TF-03 | 接受新版候選後的本人內部 beta | L1 | PLANNED；等待候選與其交付授權 |

契約均列出 exact allowed/forbidden files、依賴、failure checks 與 rollback。本輪沿用已保存的節奏遊戲 skill，沒有重新廣搜參考／新增 artwork。core／C boundaries／capture 新跑結果、source manifest 和 Git delivery 以 docs/slices/PROGRESS-01-verification.json 為準；歷史 native receipts 保留但不算本輪重跑。Push 既有 codex/bl-001-app-foundation；不包含 PR／merge／新 beta 或 App Store 發行。

### 2026-10-05 — 產品化 alpha 與 embedded QA

Owner 修訂：UI-BRAND-01 只建立 design system 與共用元件，不變成整頁 redesign。執行順序為 foundation → MET-02／QA-01A → GAME-08／QA-01B → GAME-09／QA-01C → QA-01 Final → TF-03 delivery-only。功能完整，產品級 timing validation 尚未完成；背景／前景、中斷、live changes 与實機判分還需完整 gate。

TF-03 前不新增關卡、Skin、角色或模式。成功條件是三頁一致、首次使用者 10 秒內知道開始、孩子第一關理解跟拍、真機節拍与判分無 regression。GAME-09 要有聽拍→預判→操作→即時視覺／聲音回饋；呈現-only combo 不改星星，音訊路徑更動先升 L2。不要用更多內容掩蓋任一未過 gate。

## Public 方向的當前工作（2026-10-05）

Owner 指示「繼續做下去，直到可以推到 public」。目的地（App Store／TestFlight public invitation link／GitHub Release）已提出確認問題，尚待答覆。GitHub repo 已只讀確認 PUBLIC；App 並未因此公開發行。

品牌 tokens 與 tab／sheet 已改為暖白／深綠；節拍器拍號細分移至拍點附近、音量常駐、音色與提示可展開；練習入口與所有恐龍引用沿用 HomeDinosaur。跑酷新增一張原創暖黃／綠小島 scene，accepted hits 驅動跳躍、連續 Perfect 呈現 combo，未跨過障礙給 recovery 提示；沒有新增聲音路徑、score、課程、Skin 或角色。

原生編譯、core 50、App/store/呈現 31 tests、十關實際 graph 啟動／取消／恢復 smoke 通過。完整 wide regression 49 項中 47 通過／2 失敗，失敗的 offscreen tap／錯關 fixture 修正後，6 Foundation＋精確核對十關的 1 smoke 共 7／0 通過。小螢幕一般跨障礙／重開／版面 2／0，明確最大字級的四區塊／停止在兩次真實挑戰 1／0，實際 Reduce Motion toggle 下 matched touch／restart 1／0；原生最大字級失敗保留，根因包含 fixture 沒指定字級與人造 30pt SE 底部禁區。停止鍵實測 maxY662.5 位於 667pt viewport 內，native cancel 通過。不能稱全 suite 單次綠燈、owner 新畫風接受或 G1-G4 通過。

目前 iPhone 為 unavailable，已請 owner 恢復 USB／Wi-Fi 連線；外部 capture、音畫／touch／frame pacing、三位目標年齡試玩與最低 OS 真機仍 NOT RUN。公開交付準備與 Apple 官方流程見 docs/release/public-release-plan.md；沒有新 upload、Beta App Review submit、public link、App Store submit 或 GitHub Release。

當前 UI 工程 checkpoint：詳見六個 slice 的 verification JSON 與 `docs/design/branding/previews/manifest.json`。最新 unsigned Release iphoneos compile 通過；沒有封存／安裝／上傳。聲音回饋仍未實作，下一步需另立 GAME-09A L2 契約補齊既有要求的 input feedback，再驗負載／遮蔽／lifecycle 與真機；不新增玩法／角色／課程。

UI checkpoint 已提交 8bd9453，canonical milestone companion 52820b5；原分支 push 因遠端新增兩個 CI-only commits 被拒絕。改以 `product-alpha/ui-checkpoint` 保存並 push，remote SHA 52820b59985d4257d0b2ea1181be95be75ab8914 已核對；沒有 PR／merge。此分支不符合既有自動 push 的 main／codex filter，沒有重新啟動 hosted macOS job。原 default branch CI 調整保留。canonical memory writer／run-guard 已實際執行，無 blocker；consumer 的工具探索／證據根目錄及歷史覆蓋 warnings 保留，未宣稱完整治理／memory DONE。

GAME-09A 已先建立 L2 exact-file 契約，開始實作既有要求的短 input feedback。這片改音訊 graph 與判定後副作用，不能沿用先前「所有 Audio／App authority paths 未修改」作新的全片 claim；Sources/DSP、判定／targets／保存公式仍禁止改。真機及 public gate 待驗。

GAME-09A 本機回歸：focused 9／0；完整 App tests 36／0 加實際 UIKit matched／extra／重開與零輸入流程 2／0，共 38／0。實際 AVAudioEngine offline output 證明音效有輸出、20 次連點不累積長 queue、gain0 靜音；實際 graph 檢查 count-in／校正禁用、mute 不重設節拍、中斷清理與重開。36 App 與 2 UI 由同次 test action 執行；不擴大成完整 UI suite 或真機 timing PASS。37 Swift files／104 test definitions source check 通過；18 條 protected paths 與 UI checkpoint bytes 一致。未新增內容或公開分發。

同一來源 unsigned Release iphoneos compile 通過，bundle／build 維持 com.gavin0099.beatlab／0.1.0（10）；未封存／驗 distribution signature。工程證據記錄於 docs/slices/GAME-09A-verification.json；目前 source 與已分發 build10 不同，不能拿舊 IPA 當新候選。

### 2026-10-05 — 最新 alpha 手機安裝

Owner 明確要求安裝。INSTALL-ALPHA-01 只交付目前 source 6a9677e，不改 App／bundle／team／build／progress schema。66 個來源檔案在 build／install 前後 hashes 一致；Debug iphoneos 建置、development signature、profile 有效期與本人裝置覆蓋核對通過。devicectl install 成功原地更新 GavinWu0099 的 com.gavin0099.beatlab，沒有 uninstall／reset／Apple upload。版本仍 0.1.0（10），來源包含新版三頁與 GAME-09A，和 TestFlight distributed build10 不同。首次 launch 被實際 Locked error 拒絕；已請 owner 解鎖，下一步只重試 launch。本機 candidate／signature／install／launch receipts 在 ignored TestResults/INSTALL-ALPHA-01/BUILD.json；安裝不代表物理 timing、玩法或 public gate 接受。

Owner 再次明確要求重裝：核對同一份 source／artifact hashes 與 development signature 後，直接重用候選，沒有重建或改來源。22:44 原地重新安裝通過，22:45 devicectl launch 通過，首次鎖屏的開啟阻擋已解除。重裝與開啟 receipts 為 install-repeat1.json／launch-repeat1.json，同一 BUILD.json 保留歷史結果；沒有清除 learner data、新上傳或 release gate 接受。

### 最新 owner 試玩回饋 — 畫面一致，遊戲吸引力未接受

Owner 提供新版真機 screenshot，明確表示「畫面是一致了」，但仍覺得不像遊戲、吸引力不足，要求先研究網路 App 做法與分析。此為三頁風格一致的 owner 回饋，不能推廣成 timing／兒童／首次使用 gate 通過；GAME-09／09A 的玩法接受仍未通過。當前工作轉為 analysis-only：核對 Duet Cats、Geometry Dash、A Dance of Fire and Ice 的官方 App Store 說明／宣傳圖，以及 Simogo 的 Beat Sneak Bandit 開發紀錄；沒有實際試玩參考 App。原生 source 確認固定背景、同張角色圖位移與既有 lesson clock 驅動進度。任務目標、角色動作、世界隨節拍的反應與簡短音樂 loop 屬待評估提案，未授權或實作新增玩法／內容；本輪不改 App、不安裝、不 build、不 push、不公開分發。

### 2026-10-06 — GAME-10 送蛋回巢試玩

Owner 接受前輪提案並指示「好，這樣做做看」。開始實作第一關送蛋回巢：可見目標、動作素材、匹配／漏拍／多打後果、真實結果與重試、原創簡短鼓組。先可操作概念再 native；新增 L2 exact-file 契約 `docs/slices/GAME-10.md`。不增加關卡／角色／skin／模式／保存規則；音樂使用原有 DSP cursor，動畫與碰撞不取得 timing/score authority。Status IN_PROGRESS；本輪工程驗證、owner 遊戲接受与硬體 timing 均尚未完成，未授權公開分發。

GAME-10 已落地並原地安裝開啟 owner iPhone：首頁第一關、恐龍、60 BPM 的約20秒「把恐龍蛋帶回家」。原創九格 alpha atlas 保留與 icon 的恐龍身份；新的跑／跳／接蛋／抵達動作、可見巢與靠近的石頭、Perfect 蛋亮與連續拍、extra 小跳／miss 安全接蛋，結果與保存仍用原分數。原創四小節 kick/snare/hat PCM 在 graph.start 前完成，在 C render 的既有 cursor 上於四拍數拍後混合；gain/mute/transport transitions 不改 timing authority。12 條 core/input/configuration paths 與6a9677e bytes相同；DSP與音訊/PracticeStore則確實因配樂而改，不宣稱全authority路徑未改。

驗證：可玩瀏覽器概念15項，真实clock-cued16次輸入達成16命中／15Perfect／0extra，零輸入失敗／重試／取消及duplicate通過。core53、capture3、C renderer468組各900秒與UBSan boundaries通過。凍結來源的 SE / dark / 系統Reduce Motion ON 原生App41＋UIKit input/restart、一般viewport、明確最大字級分兩輪到達scene/rhythm/pad/stop3項，共44／0；最大字級 stop maxY659在667pt viewport內。寬機零輸入／重試與一般viewport另驗。39 Swift files／112 test definitions／project membership結構檢查通過。初始語法/欄位錯、冷啟動/取消、兩次測試查詢超過真實20秒挑戰、building DB contention的失敗均保留；沒有延長課程、改判分或假成功。實際圖示裁切/場景背景intrinsic width造成的接縫已修正並納入凍結來源。

Debug iphoneos 71來源檔案／artifact hashes、簽章／team／本人裝置profile覆蓋檢查通過；GavinWu0099的 com.gavin0099.beatlab install與launch PASS，既有學習資料未重設。版本仍0.1.0（10），為直接安裝的新source，TestFlight distributed build10未更新。Status IMPLEMENTED_AND_INSTALLED_LOCAL_CHECKS_PASS_OWNER_PENDING；物理音畫/input timing、audibility/frame pacing、VoiceOver與兒童是否想重玩仍NOT RUN，不能稱public readiness。凍結與安裝收據在ignored TestResults/GAME-10/；canonical evidence見docs/slices/GAME-10-verification.json。只推工程分支；沒有PR/merge/Apple upload/public link/App Store submit。

凍結來源的寬機實際零輸入／重試／保留第二關鎖定與一般viewport停止另跑2／0通過；最後工程證據為SE44／0＋wide2／0的組合，不稱完整UI suite全綠。SE測試後appearance已還原light；Reduce Motion原值OFF，目前ON。CUA還原時Mac實際Locked，已請owner解鎖，這項測試環境還原仍待；不影響已安裝手機。未動其他模擬器／手機的輔助使用設定。

### 2026-10-06 — GAME-11 流暢度改善

Owner 表示 GAME-10 有比較好但仍不夠，要求參考市面 App 流暢度。已核對 Simogo 官方 animation/follow-through 開發紀錄、ADOFAI 官方單鍵路徑說明與 Halfbrick 官方跑酷/影片來源；沒有實際試玩或量測這些商業 App，不能引用其 FPS/latency。程式觀察：scene 目前隨30ms published elapsed更新、背景每8秒回跳、extra會覆蓋matched跳躍，腳底與文字版面也可能跳動。立 GAME-11 L2 exact-file 契約，先做可玩的舊/新比較，再以原audio-host epoch只讀呈現、scene-only animation schedule與動作follow-through修正；原聲音、input、score/save/課程禁止改。Status IN_PROGRESS；真機性能尚待量測。


GAME-11 已實作連續場景呈現、共用腳底的快取 sprite、跑姿/落地交叉淡化、有限陰影/塵土/壓縮。只讀既有 audible-host epoch，scene TimelineView請求60Hz；不是測得60FPS。真正inputTime決定跳躍年齡，extra不能截斷、延長或落地後重播accepted動作；保留最長cue高度。原Audio/DSP/Core/TapPad/score/save/目標/結束時間/其他九關不改，26 protected paths與9a7c62d bytes一致。可玩舊/新比較與官方來源永久保存於 docs/design/runner-fluidity/，商業App未實際試玩或benchmark。

驗證：browser22含真實16/16Perfect/0extra、零輸入失敗/重試/停止；core53；wide原生App44+UIKit3共47/0；SE actual touch/restart+一般viewport初次2通過、最大字級最終四輪真實關卡到達scene/rhythm/pad/stop1/0、dark viewport1/0。最大字級前三次失敗保留：無geometry的application root、查詢超過真實20秒預算，以及六像素靜態rhythm列被要求hittable；修正primary-window fixture、每區獨立真實挑戰與靜態可見/按鈕可操作條件，未改App或課程判分。39 Swift files/115 test definitions source結構與85source-copy hashes通過；Xcode root遞迴warm-up卡住，以exact-byte temporary copy建置，沒有改project/package或刪歷史。原生操作錄影與light/dark/最大字級畫面已保存。SE Reduce Motion原值OFF已透過CUA還原並核對，appearance light；GAME-10還原待辦已解除，歷史記錄保留。

同source signed Debug iphoneos候選68production inputs/全artifact hashes、簽章/team/owner profile覆蓋核對通過。原地安裝嘗試FAIL：CoreDevice找不到配對裝置，fresh inventory unavailable；launch NOT RUN。因此手機仍是上一輪候選，新版未裝入。Instruments phone attach timeout/offline、simulator Hitches unsupported保留，物理FPS/frame pacing/音畫/input timing與兒童重玩意願均未接受。Status IMPLEMENTED_LOCAL_CHECKS_PASS_INSTALL_BLOCKED_OWNER_PENDING，不稱VERIFIED/DONE/public ready。詳見 docs/slices/GAME-11-verification.json；只推既有工程分支，不做PR/merge/TestFlight/public分發。手機USB/解鎖就緒後可核對同一凍結候選直接安裝，再做硬體性能與owner試玩。

### 2026-10-06 — GAME-12 持續繪製與動作曲線

Owner再次表示比較好但仍不夠流暢，要求修改。先立GAME-12 L2 exact-file契約，不新增玩法/美術/課程。來源可證明跑步兩姿勢大部分時間held且僅最後50ms交叉淡化、sin跳躍到地面時速度突然歸零；實際掉幀原因尚未測得。改用單一持久SpriteKit node graph作場景呈現，原UIKit/input/audio-host epoch與判分不改，修正持續步態與零速度落地。先可玩比较再native，測實際SKView callback但不得當手機FPS。GAME-11手機安裝仍未成功，不能把owner回饋當成已試玩那份手機候選。Status IN_PROGRESS，硬體與owner gate未接受。

### 2026-10-06 — GAME-12 動作修正安裝候選

Owner具體回覆「跑步、跳躍像在換圖片」，據此把contract限縮到同恐龍/同蛋連續動作。新透明16幀圖集：8跑步、6跳躍、準備/壓縮落地；持久SpriteKit graph只讀原host/audio epoch，原觸控/判分/音訊/存檔不改。零速度落地與整條小場景弧線縮放；固定眼睛/腳底對齊。Video發現相鄰alpha混合双眼/雙腳，先修成單一opaque角色，再重新build/實際測；中間候選未安裝。初始化super.init提前didChangeSize造成未建圖越界，graphReadyguard修正並由actualSKView/scene/lifecycle regression覆蓋。這是呈現架構決策，不改timing authority。

Final App47/Core53/browser25（16真實clock-cued input16Perfect/0Extra）通過；final-source wide49pass/1fail、narrow2pass/1fail的大字查詢超過原20秒關卡保留，停止build/錄影後同source/fixture串行重測各1pass，final dark1pass。沒有延長課程或更改UI測試。87source/83protected/70phone inputs bind；新候選已安裝同bundle/team0.1.0(10)，沒有uninstall/reset，auto-launch因手機鎖定FAIL。Simulator callback只作觀察，不宣稱真機FPS。Status IMPLEMENTED_INSTALLED_LOCAL_CHECKS_PASS_OWNER_PENDING；G1-G4、physical timing/owner/child replay仍未接受。未更新TestFlight/public。根因與決策使用canonical review-log/daily/active-task-summary；writer不支援knowledge-base surface，不宣稱03知識庫已規範化。詳GAME-12-verification.json。

### 2026-10-06 — GAME-13 貓咪／機器人連續動作

Owner要求兩個夥伴也採用連續跑跳且風格不同。先立 exact-file L2 契約，第一關60 BPM共用GAME-12 renderer／既有真實判分；貓咪柔軟雲端送魚、機器人蠟筆科技平台送能源。新的任務物件只作呈現，不增加關卡／模式／保存規則。先 playable concept 再 native；Status IN_PROGRESS，owner／硬體 timing／public gates 尚未接受。

### 2026-10-06 — GAME-13 美術與動作實作完成，驗收仍有缺口

貓咪獨立暖桃雲端送魚、機器人獨立蠟筆藍色科技平台送能源；第一關60 BPM共用既有節拍／判分／保存，8幀跑步＋6幀跳躍與快取SpriteKit素材。App49/Core53/browser20及final wide兩個角色真實tap／cancel／restart2/0 PASS；final narrow50/2保留大字application crash與robot零命中。Simulator CoreAudio RPC timeout發生在未改音訊停止路徑，根因尚未確定，不宣稱真機缺陷或只有環境問題。大字旅程／caption修正、fixture24次viewport-first scroll檢查保留所有失敗候選；final generic build PASS，explicit device build因destination unavailable FAIL。95source／83protected bind；Status IMPLEMENTED_BUILD_PASS_FINAL_UI_PARTIAL_OWNER_PENDING。手機新inventory tunnel unavailable，未簽署build／安裝／launch／TestFlight／public；G1-G4與owner／child／physical timing仍未接受。下一步先完成小螢幕大字與真機驗收；不得以兩個wide PASS消除narrow失敗。canonical writer只支援daily／review-log／active-task-summary，不宣稱03 knowledge-base已寫入。詳GAME-13-verification.json。

### 2026-10-06 — GAME-13 Owner 指定現版手機測試

Owner 決定 KidsCharacterKit 完成後再導入統一美術，先安裝目前版本。來源6019be7、signed iphoneos Debug0.1.0(10)、78production inputs及frozen app signature/hash核對後已成功覆蓋安裝原bundle/team，保留進度；devicectl自動launch因device locked FAIL，解鎖後待owner實際試玩。沒有App source變更／重跑足夠的既有測試／TestFlight／public；GAME-13小螢幕大字失敗與G1-G4仍未接受，不把installation PASS當作physical timing/FPS/兒童喜好證據。詳GAME-13-verification.json phone_delivery_20261006，安裝流程依install-garden-on-iphone skill套用BeatLab。

### 2026-10-06 — GAME-14 障礙間隔修正

Owner 澄清問題是石頭看起來不是60BPM、間隔不一樣。來源position本身等距且read-only host epoch，但accepted會立即hide upcoming rock，early hit可能造成未到拍已消失的視覺空缺；尚無physical capture證明實際audio/arrival不均。先立L2 exact-file契約與native failing regression，再做保留石頭至固定到拍後淡出、固定floor marker；不改audio/input/score/tempo/assets。Status IN_PROGRESS；KidsCharacterKit仍deferred，既有narrow XXXL與physical gate仍未接受。


### 2026-10-06 — GAME-14 實作 checkpoint

提早命中保留石頭至原定 crossing，之後0.25秒淡出；新增固定 floor marker，不改石頭位置公式或 audio／判分／存檔。Pre-fix native 1 test／2 assertions FAIL；final native build PASS、wide55/0（App52＋實際UI3）、browser30 PASS（真實16Perfect／0Extra）。95source／93protected unchanged bind；小螢幕第一個class filter錯誤已中止不接受，corrected run與phone delivery仍pending。Status IMPLEMENTED_FINAL_WIDE_PASS_NARROW_PHONE_PENDING；KidsCharacterKit deferred、prior XXXL失敗／physical sync／G1-G4不接受。使用canonical writer保留root cause與owner方向，不手改03 knowledge base。


### 2026-10-06 — GAME-14 交付狀態

實作a6e1869，wide55/0與browser30通過。Corrected narrow dark UI run沒有有效測試結果，數分鐘無test execution後中止，small-screen PASS不宣稱；只停止owned xcodebuild，narrow light／initially-off shutdown恢復成功，沒有重置shared service／Garden。Signed iphoneos build PASS／78production frozen inputs；新inventory paired owner但install FAIL_DEVICE_NOT_FOUND，launch NOT RUN，已請owner解鎖／USB連線，待回覆使用同候選續安裝不重build。Status IMPLEMENTED_BUILD_PASS_WIDE_CHECKS_PASS_NARROW_INCOMPLETE_PHONE_BLOCKED。根因只證明early accepted cue消失的display defect，不證明physical audio interval原因；prior XXXL、G1-G4、physical／child acceptance仍pending。KidsCharacterKit deferred，沒有TestFlight/public更新。


### 2026-10-06 — GAME-14 Wi-Fi 安裝成功

Owner 明確要求透過 Wi-Fi，fresh inventory localNetwork paired device、devicectl 實際 install／launch 均 PASS。沿用 a6e1869 frozen signed0.1.0(10)／78production inputs，未重建；來源／artifact／signature安裝後再次核對，保留bundle/team/learner progress。之前 unavailable失敗receipt與blocked snapshot保留。Status IMPLEMENTED_WIFI_INSTALLED_OPENED_NARROW_INCOMPLETE_OWNER_PENDING；physical60 BPM stone/click同步由owner測試，narrow／prior XXXL／G1-G4不因此接受。KidsCharacterKit仍deferred，沒有TestFlight/public更新。


### 2026-10-06 — GAME-15 動作连续性

Owner 已玩Wi-Fi安裝GAME-14，回報動作仍不流暢。分類問題的optional問答未回覆，先處理可重現漏拍換圖：native pre-fix1 test／13 assertion FAIL，跑步中途切舊atlas或companion static frame16，geometry／bob／run phase突變。Contract限定EggMissionView／PracticeStoreTests呈現，不動audio/input/判分/石頭時程/assets；漏拍持續既有run cycle、短暫cosmetic tint＋既有文字，Reduce Motion static highlight，action立即清tint。Browser33 checks、真實16Perfect／0Extra通過；第一個繼承的early visibility比較因checkbox跨過4秒失敗已保留，改同步控制＋actual RAF後重測。真機Animation Hitches無線device boot timeout，未錄到gameplay，不宣稱physical frame pacing。Status IMPLEMENTING_VALIDATION_PENDING；8跑步／6跳躍素材數未改、不宣稱全部動畫已變平滑；KidsCharacterKit deferred／prior small-screen與physical gates不接受。


GAME-15 final generic native build PASS、wide57/0（App54＋實際UI3）、browser33／真實16Perfect0Extra。95source／93protected bind；漏拍角色continuity修正成立，但8／6張動作幀數未增加、physical profile timeout未取得實際FPS，不宣稱整體流暢度已達標。Status IMPLEMENTED_NATIVE_BUILD_PASS_WIDE57_PASS_PHONE_PENDING；待綁定source commit、簽署新候選並依owner Wi-Fi偏好更新手機。


GAME-15 source e2aeec5，signed phone build PASS／frozen78production inputs signature bind；actual wireless install FAIL_DEVICE_NOT_FOUND／launch NOT RUN，已請owner解鎖同Wi-Fi就緒再續裝。手機目前仍GAME-14 a6e1869；新候選不重build、不uninstall/reset。Status IMPLEMENTED_WIDE57_BROWSER33_PASS_PHONE_READY_CONNECTION_BLOCKED。GAME-14「動作仍不流暢」是owner拒絕驗收，不以測試或安裝成功覆蓋；GAME-15修復已重現miss pose snap，不宣稱frame-count限制或physical frame pacing解決。


### 2026-10-06 — GAME-15 Wi-Fi 安裝並開啟

Owner回覆就緒後，fresh paired localNetwork inventory、actual devicectl install／launch均PASS。沿用e2aeec5 frozen signed0.1.0(10)／78production inputs，沒有rebuild/uninstall/reset；來源／artifact／signature安裝後再核對。先前unavailable失敗與blocked snapshots保留。Status IMPLEMENTED_WIFI_INSTALLED_OPENED_FLUIDITY_ACCEPTANCE_PENDING；owner可在第一關故意漏拍比較三種角色銜接，未把安裝當physical frame pacing或流暢度驗收。8／6張動作幀數、KidsCharacterKit deferred、prior small-screen/XXXL／G1-G4／child/public gates仍待處理，沒有TestFlight/public更新。

### 2026-10-06 — TF-04 本人 TestFlight 動作候選

Owner 明確授權先上 TestFlight，交付 GAME-15 e2aeec5 的既有個人試玩候選。Fresh ASC latest 0.1.0（10），本次 App build number 11；95 native／78 phone inputs 已核對，僅變更 project build metadata。契約 docs/slices/TF-04.md；Status SIGNED_DISTRIBUTION_READY_XCODE_SIGN_IN_REQUIRED。Release archive／distribution signature／internal-only／95來源 hashes／icon privacy檢查 PASS；只有 build metadata 10→11，沿用此前57 native與33 browser，未重跑。Xcode目前Apple Accounts沒有帳號且拒絕上傳存取，已開啟登入並請owner登入；upload／Apple processing／本人group assignment／測試說明保存／手機TestFlight更新 NOT RUN。build metadata commit8831537，封存與IPA保留，登入後繼續同一候選，不重複任何未知結果上傳。TF-03 公開／產品驗收 gate、實機 FPS/timing 與兒童体验仍 pending。

### 2026-10-06 — TF-04 TestFlight 本人試玩可下載

Owner 已登入；Xcode原有發佈流程完成，Organizer 14:48 上傳0.1.0（11）。未重複上傳或重新編譯。实际GUI IPA已匯出／驗證internal-only、distribution签署與get-task-allow=false、原icon/privacy、archive Assets.car相同、95來源hashes。Apple處理完成build a3d8f2aa-aec6-49e7-9d8c-26c0c3caedbc，已加入既有本人試玩一位内部tester，繁體測試說明已儲存，版本列表「正在測試」。Status TESTFLIGHT_OWNER_TRIAL_AVAILABLE；本人手機TestFlight更新及動作驗收 pending，G1-G4／實機 timing/FPS／兒童体验／public readiness不因此接受。此前登入阻擋與packaging receipt保留為歷史。契約／canonical evidence docs/slices/TF-04.md、TF-04-verification.json；ignored logs/IPA/screenshots TestResults/TF-04。

### 2026-10-07 — Rhythm Swing 參考切分

Owner 指示先切slice；本輪L0規劃文件，實作皆PLANNED。對照程式確認任務入口限定first-beat／60 BPM，現有4拍數拍＋16目標約20秒，三角色／目的地／SpriteKit與8跑6跳幀已存在。Rhythm Swing官方學習／練習／遊戲結構及示範靜態畫面已核對，沒有實機試玩或引用其FPS。下一輪先驗同一第一關的目標／預判／操作後果／真實成敗，不增生命、貨幣、模式、關卡或KidsCharacterKit。完整範圍與reference保存在 [Rhythm Swing六片總覽](docs/design/RHYTHM-SWING-SLICES-20261007.md)。

| Slice | 目標 | Risk／依賴 | 狀態 |
|---|---|---|---|
| GAME-16 | 可操作的第一關短概念，先看owner是否理解且願意再玩 | L1 isolated browser；既有第一關規格 | CONCEPT_BROWSER60_PASS_OWNER_PENDING |
| GAME-17 | 原生短拍點／障礙路線共用真正target與只讀結果 | L2 audio/input/UI clock邊界；GAME-16接受＋QA-02A | PHONE_PREVIEW_INSTALLED_NATIVE_UI_PARTIAL_OWNER_PENDING |
| GAME-18 | matched起跳／落地、extra／miss銜接與可見後果 | L1，若clock更動升L2；GAME-17＋QA-02B | PHONE_PREVIEW_INSTALLED_NATIVE_UI_PARTIAL_OWNER_PENDING |
| GAME-19 | 引導→數拍→挑戰→結果→重試，三角色整合 | L1；GAME-18＋QA-02C | PHONE_PREVIEW_INSTALLED_NATIVE_UI_PARTIAL_OWNER_PENDING |
| QA-02 | A/B/C嵌入前片，Final原生／真機／兒童與公開缺口 | L2；不等最後才QA，不把工程PASS當owner接受 | PLANNED |
| TF-05 | 本人TestFlight交付，owner於新版試玩後驗收 | L1 delivery-only；本次本人alpha明確授權 | TESTFLIGHT_OWNER_TRIAL_AVAILABLE（2026-10-08） |

Exact-file contracts：docs/slices/GAME-16.md、GAME-17.md、GAME-18.md、GAME-19.md、QA-02.md、TF-05.md。每片包含allowed／forbidden、依賴、失敗路徑、驗證與rollback；本輪不實作App或上傳。GAME-17–19先只改第一關60 BPM，其餘九關／非60仍用原練習且要smoke；新score／保存／教學影片／三錯結束需另切與授權。TF-04 build11仍為既有交付，G1-G4／physical／child／public gates及KidsCharacterKit延期不變。

### 2026-10-07 — GAME-16 可操作第一關

Owner「好，往下走」後完成隔離browser短試玩：4拍數拍＋16真實目標、四格樂句／固定黃色腳印、matched才跳與送蛋進度、實際early/late/extra/miss、零輸入失敗、取消／重試。Final60 checks PASS，實際16Perfect/0Extra；12組ready＋12組live尺寸／深色／放大字、Reduce Motion／鍵盤／素材失敗守護。初版結算重複巢穴修正並保留截圖；READY圖未可見時不給開始、引導移出場景避免遮住角色。95原生inputs hash未變；不重跑native tests、不聲稱physicalFPS或child appeal。Status IMPLEMENTED_CONCEPT_BROWSER60_PASS_OWNER_PENDING。入口docs/design/rhythm-swing-concept/play.html與本機7820；owner理解／再玩接受後才進GAME-17，GAME-17–19/QA-02/TF-05仍PLANNED。TestFlight build11不變、KidsCharacterKit仍延期、public gate未接受。詳docs/slices/GAME-16-verification.json。

### 2026-10-07 — Owner 改用 iPhone 驗概念

「直接安裝到iphone比較快」授權GAME-17/18/19最小phone preview先做再安裝，browser owner gate對此候選延期，不是玩法接受。三slice新增exact-file與failure/check/rollback範圍；只讀real target/accepted/expiry、四拍路線、有效early起跳與準備文字，保留現三角色素材／native音訊／input／grade／save。Status PHONE_PREVIEW_IN_PROGRESS；Wi-Fi個人安裝，無TestFlight／public。

### 2026-10-07 — 原生第一關 Wi-Fi preview 已安裝

Source d13697b9156314679db32cf834de601e49ea4307；只讀actual targets/hits/epoch/expiry接四拍route與石頭、matched進度、有效early起跳及準備文字，Core/audio/input/score/save/assets/project版本均未變。95source／78production frozen bind、90protected unchanged；build-for-testing與signed Debug0.1.0(11) PASS，actual paired localNetwork install／launch PASS，不uninstall/reset，TestFlight build11仍舊候選。Initial fixture scope compileFAIL修復後App unit56 PASS、dinosaur UI3 PASS；initial companion2 FAIL（操作超過20s）保留，final robot整段PASS、cat實際命中與取消成立但再次start counter缺失FAIL，hierarchy仍是準備頁且停止notice保留，根因未確定；narrow dark XXXL1 FAIL（停止查詢已進結果），其後empty0-test不接受。三片minimum preview已交付供owner第一關60BPM試玩，fullslice／QA-02／physical timing/FPS／child/public未接受，不能稱all-green。Owned narrow restorelight＋shutdown；其他simulator不動。KidsCharacterKit仍deferred；無TestFlight/public上傳。詳docs/slices/GAME-17-verification.json。

### 2026-10-07 — Owner 拒絕原生 phone preview 的遊戲方向

Owner 貼已安裝新版截圖（78B8245D-AC3B-4D0D-A35C-891358CA0C09），指出仍不像指定 Rhythm Swing。畫面四格與matched counter確認是GAME17最小preview；install/build/test通過不等於玩法接受。Owner接受狀態 REJECTED_CURRENT_GAME_PRESENTATION；四拍資料與時間對齊可保留，但沿用固定角色＋橫向石頭＋大pad的跑酷構圖沒有達成參考的逐拍行進／可見跌落後果。此次為診斷，重核官方Play/Practice說明，未操作商業App或量測FPS，沒有修改原生或重裝。下一個核心互動候選應先定角色逐拍移往下一平台、miss可見安全回復、場景主要區域的exact-file與grade/clock邊界；不將新增生命／3錯結束／音樂或新素材視為已授權。既有cat重啟／narrowXXXL、physical/child/public gates不變；完整GAME17–19未接受。

### 2026-10-07 — GAME-20 跨島互動實作開始

Owner接受角色逐拍跨落腳點/場景主體/漏拍跌落接回提案，明確授權實作後直接安裝。建立GAME-20 L2 exact-file contract：first-beat60、三角色、pure matched-driven world步數與延後camera、real expiry跌落、既有美術runtime crop、compact phrase；不改audio/input/score/save/asset/version。Status IN_PROGRESS；持續保留GAME17 rejected gameplay、cat restart/narrowXXXL和physical/child/public pending。Wi-Fi本人preview授權明確，不重詢。

GAME-20 原生觀察修正（2026-10-08）：c1f9152 first signed candidate未安裝。App61/0成立；初次UI cat start FAIL，wide其它流程/小屏當時未完整執行，停止only owned xcodebuild保留logs。Actual owned screenshot確認跨島已渲染，但cue在scroll下方且背景stretch；在相同allowed範圍修scene高度/aspect-fill、避免相同texture/text每幀重設，新增背景比例assert。UI未開始/未結果原因尚未確認，不以Mac負載或App61 PASS代替UI gate。新fixed候選必須重新build/freeze與viewport/touch驗證；原95/78source與未安裝舊簽署包保留。

### 2026-10-08 — GAME-20 手機 preview 交付（QA partial）

Source 0e83ed34efa4a0e5576eee6ff52fb0c011042e94：第一關改成實際matched橫跨分開平台、落地後camera跟進、miss可見跌落回原島、extra不前進；compact樂句/固定跳躍與停止。準備/結果三theme沿用美術，修過高scene與background stretch。95source綁定、78production signed包、91protected paths對GAME17 unchanged；同bundle/team Debug0.1.0(11) Wi-Fi install PASS，launch BLOCKED_DEVICE_LOCKED（手機鎖定，已問unlock，只重試launch）。不清學習進度。

驗證：pre-layout App61/0、cat初start FAIL；fixed App5中1case/3assertions背景比例floating-round FAIL，已以1e-6獨立比例界限修test；finalApp PASS 61/0。Fixed真實no-input/16miss/0星/retry歸零/next locked流程PASS；actualtouch/wideviewport、小屏darkXXXL仍INCOMPLETE，only-owned測試停在preparing，不推定原因；robot/full10/physical timingFPS/child fun/public NOT RUN或pending。Owned narrow restoredlight/shutdown；wide保留原Booted。完整可查docs/slices/GAME-20-verification.json，不能宣稱QA全綠或上架完成，TestFlight未更新。

### 2026-10-08 — Owner 拒絕 GAME20 動作，GAME21 修正

Owner指出GAME20比舊跳躍更差、動作不順。Gameplay/motion acceptance REJECTED；source0e83ed3與本人安裝仍是歷史事實，不能因61App PASS稱順暢。GAME21 exact-file L2 contract先修camera落地後倒滑、sin落地速度硬停、sprite pose硬切以及live configure重複render；不換玩法/美術、不改audio/matching/score/save。Status IN_PROGRESS；同bundle個人Wi-Fi安裝授權沿用，既有UI/physical/child/public未接受。

GAME21 source驗證：保持既有單一opaque角色guard；初次雙圖trial65測試中3case/6assert FAIL且native樣本實見ghostheads/limbs，已撤回且未安裝。Final65case/0fail PASS（包含4新增motion regression與三theme實際SKView），native3theme圖片無雙影。Camera flight同phase、C2起落/漏拍回復、live configure不額外render、theme一次texture預熱；既有pose素材未改，不能稱骨架動畫或商業遊戲流暢度。Status SOURCE_TESTED_OWNER_PREVIEW_PENDING，freeze/install/physical驗收仍須分開記錄。

### 2026-10-08 — GAME21 tested/frozen, phone delivery pending

Source fd1e75f54a6688365f571466507059398539d8d2；65App/0fail PASS，雙圖trial3cases/6assert FAIL與實見重影均保留，未安裝且撤回。Final三theme native樣本單角色無重影；只證明原生呈現fixture與callback，沒有fullAppUI/physicalFPS證據；姿勢仍使用既有素材。95source/78production/93protected未變與signed/profile綁定PASS。iPhone fresh inventory unavailable/缺transport，install NOT RUN、launch NOT RUN；已問同Wi-Fi與unlock，READY frozen候選不因docs再build，手機仍GAME20來源0e83ed3。Status SOURCE_TESTED_PHONE_DELIVERY_BLOCKED；既有cat/narrow/touch/child/G1-G4/public gaps保留、TestFlight未動。Owned wide本來Shutdown且最終已Shutdown，shutdown嘗試149表示alreadyShutdown。完整evidence见docs/slices/GAME-21-verification.json。

### 2026-10-08 — GAME-22 優先補連續姿勢

Owner要求先完成圖片畫格密度。32-cell/theme候選：12跑步/.5s、12飛行/.48s、4落地/.16s、4ready；目標24–25有效姿勢/s，60fps仍是場景請求值。新imagesets保留舊素材，素材品質與native連續播放先驗，再建置；不改audio/input/matcher/save/玩法。契約 docs/slices/GAME-22.md；DEFINED / ART_IN_PROGRESS，尚未宣稱真機流暢或接受。

GAME-22 source gate: 新三套32格PNG與read-only對齊接入完成；實際motion28格（run12/flight12/landing4）＋固定ready28，沒有把未播放ready29–31當作flow提升。Final App69/0 PASS；原生fixtures確認每格使用＋真實SKView callback姿勢前進、停用/Reduce Motion；84段原生姿勢截圖已匯出，六張apex/landing與Chrome循環接點檢視。Phone Debug簽署build PASS。保留robot首次裁切失敗與Swift推斷compile failure；修正版不改transport/matcher/save/原素材。真機FPS/owner流暢/舊full UI、兒童及public gates仍pending；手機paired/unavailable、install NOT RUN。

GAME-22 source333012c：來源與手機候選完整性已封存，簽署/profile/new3Assets.car PASS；App69/0 evidence與memory已記錄。手機unavailable，尚未安裝；TestFlight仍GAME15/build11。memory guard無current diff blocker，既有background warnings見verification，不宣稱full治理/上架驗收。

### 2026-10-08 — TF-05 GAME-22 本人試玩交付

Owner 明確要求推 TestFlight 後試玩，授權 GAME-22 三角色高密度姿勢候選的 Release / internal-only 上傳、既有「本人試玩」群組與 zh-Hant 測試說明；玩法／流暢度接受仍待試玩，不將 owner acceptance 前提當成本次 delivery blocker。Status IN_PROGRESS / BLOCKED_LOGIN：fresh Xcode Apple Accounts 空白、ASC 登出，已請登入；遠端最新 build 尚未讀取，版本號不猜測、未改 build metadata、未開始上傳。先綁定101 source hashes和既有69/0工程證據，製作測試說明。保留既有 full UI / physical / child / G1–G4 / public 缺口，不增功能或 tester，不提交公開 App Store。

TF-05登入續行：Xcode已恢復既有Developer Team；ASC網頁仍登出，已請owner只補網頁登入。101來源已隔離，metadata未改、archive/upload/availability未執行；當前阻擋為ASC登入。

TF-05 本機建置與上傳（2026-10-08）：owner網頁登入完成並要求所有build/test在本機，fresh ASC最新11，App metadata commit b814321 僅build11→12，GitHub iOS push/PR事件移除、Mac job `if: false` 保留腳本但不配置runner。本機App69/0、Core53/0、capture3/0、DSP468離線matrix PASS；Release12 archive／actual uploaded distribution IPA／internal-only／new3dense assets／icon/privacy與101來源一致 PASS。Xcode15:46上傳成功，Apple處理中，試玩群組availability仍pending。Python YAML缺模組與隔離複本缺capture helper初次setup失敗保留，Ruby解析／補unchanged helper後final PASS；own simulator已restore Shutdown，其他sim未動。工程PASS不代表physicalFPS/timing/fullUI/child/public接受，手機TestFlight更新待owner。

TF-05 本人TestFlight可下載：Apple build 5ba3107d-7dca-4f5c-9a19-f058b613c1d1（0.1.0/12）處理完成，已加入原本人試玩1位internal tester，列表「正在測試」；繁體說明「已儲存」。實際上傳IPA SHA256 adb0f9ca84a235670db0aaad7a54c164d441084f8bb6123cd8b145444a5afc40，internal-only distribution/source/icon/privacy檢查PASS。Status TESTFLIGHT_OWNER_TRIAL_AVAILABLE；手機更新／動作與physical timingFPS/child/public接受仍pending。所有本次build/tests在本機，GitHub無dispatch；workflow停用屬目前分支，未merge main。詳TF-05 verification與canonical delivery receipt。

### 2026-10-08 — GAME-23 掉落修正

Owner 在TestFlight12確認跳躍尚可，但掉落不真實且不順。只修掉落／承接／回平台和对应反馈，不改已接受的跳跃、節拍/判分/保存或素材。根因：對稱跳躍曲線反用為下墜、ready站姿、跟著角色移動的承接與提前顯示已接回。範圍／失敗路徑／本機native regression與rollback先定義於 docs/slices/GAME-23.md。Status DEFINED；手機體感與public gates不因先前測試PASS而接受。

GAME-23本機來源Gate：101 source inputs，其中99與TF05不變；App73/0與Core53/0 PASS，4個新增掉落回歸、123原生三theme序列/尺寸/light-dark specimens、實際callback進度與suspend／Reduce Motion靜態檢查。下墜與承接速度連續、25pose/s下降素材、托盤回平台、miss/extra不前進和下一個early hit恢復通過。檢圖後修正標記遮臉與extra晃動，final全App再跑73/0。簽署Debug候選0.1.0(12)已凍結，此build metadata未加號、不可誤認為新的TestFlight。Status SOURCE_TESTED_SIGNED_READY；physical/owner/public acceptance pending，未安裝／未上傳。

### 2026-10-08 — TF-06 掉落修正版本人交付

Owner明確要求「改好再幫我傳上去讓我測試」，授權GAME23 source73dcb17 Release與既有本人試玩內部分發。本機App73/Core53與來源101已備；先fresh ASC核對版本，再選build號封存，所有build/test維持本機。精確scope/失敗路徑/rollback見docs/slices/TF-06.md。Status REMOTE_PREFLIGHT；玩法、真機FPS與public接受仍pending，不增加內容或tester。

TF-06 local gate PASS：App73/0、Core53/0、來源101（100與GAME23不變）、sim restore。build13 metadata1545fcb；第一次本機archive自訂輸出路徑冲突保留失敗log/partial，標準archive重跑Release13 PASS。Xcode TestFlight Internal Only上傳分析中，Status UPLOAD_IN_PROGRESS；Apple processing/group availability、owner phone update pending。

TF-06本人可下載：0.1.0(13)、GAME23掉落／托盤承接／回平台修正版，Release與actual uploaded distribution IPA/internal-only/assets/source101/icon/privacy PASS。App73/Core53本機通過，未dispatch GitHub Mac；Apple build43e88b95-fdb8-4657-a17c-57884820d405已處理並顯示正在測試、本人試玩1位原tester、zh-Hant說明已儲存。Status TESTFLIGHT_OWNER_TRIAL_AVAILABLE；owner手機更新、真機流暢度/timing/FPS、fullUI/child/public gates保持pending。首次archive路徑失敗已保留，標準命令重跑PASS。

### 2026-10-08 — GAME-24 第一關掉落表情

Owner接受TestFlight13掉落動作，要求角色表情對應掉落；明確目前只有第一關做好，預設十關，待第一關完成再排其餘slice。本片只第一關facial feedback，保留已接受曲線與三角色motion/body資產，原關卡內容不擴展。先定義scope/checks/failure/rollback於GAME24 contract。Status DEFINED；第一關完整體感/child/timing仍未接受，第2–10關待後續規劃。

GAME24表情本機完成：source2a77e49、107來源／99原始輸入不變，原JourneyRecovery/JourneyMotion/PlatformJourneyFrame/DenseAnimationFrame/DenseCharacterAtlas byte-text exact保留。三角色新增驚訝／閉眼承接／放鬆／ready faces，只inset face region覆蓋，原PNG/body腳部保留。最終App76/Core53、24 native表情尺寸/light-dark specimens、pixel changes與feet unchanged、state reset/missing/reduced及既有callback/paused PASS；sim全部state恢復。三次native76/0（shader同identity不重設、missing body不套臉保護），第一次evidence helper缺PIL保留，stdlib metadata/alpha檢查final PASS。Status SOURCE_NATIVE_TESTED；TestFlight最新仍13未含本片，未安裝／上傳。Owner接受13掉落，不等於第一關完整接受；只第一關收斂，2–10關slice等第一關完成才排。

### 2026-10-08 — PHONE-08 表情修正版 Wi-Fi 安裝

Owner明確要求透過Wi-Fi安裝。107來源已測試候選以本機簽署Debug建置，保留0.1.0(13) metadata及既有bundle/team/data；此source含GAME24，與TestFlight13不同。Fresh paired iPhone localNetwork已連線，Status BUILD_IN_PROGRESS；契約見PHONE-08。完成安裝和啟動後才記錄交付，第一關體感/physical FPS/timing/public仍pending，第2–10關不排新slice。

PHONE08：本機signed Debug build／107來源綁定／手機profile／compiled三角色expression assets／原icon與privacy PASS。Fresh localNetwork Wi-Fi安裝PASS；launch實際回覆Locked，Status INSTALLED_LAUNCH_BLOCKED_DEVICE_LOCKED，已請owner解鎖，只重試啟動。未uninstall/reset或更新TestFlight；GAME24表情修正版已在手機，體感與第一關完整接受仍pending。

### 2026-10-09 — 第一關完整動作循環 review

Owner實際回報跳／掉落較順，但兩跳之間沒有動作；這是局部接受，不是第一關完成。唯讀review與本機production Swift抽樣確認：正常60BPM每兩跳間ready28固定.36s，early→late可.72s；三角色共用stationary branch且沒有anticipation；第一拍合法early已移動卻被elapsed≥4 guard保持站姿，t4才切flight16。既有native test明確要求static28，76/0不能證明完整motion loop。部分通過14/16得2星會直接切step16終點與舊慶祝素材，另有結果接點缺口。完整報告docs/reviews/2026-10-09-motion-review.md；Status REVIEW_COMPLETE_IMPLEMENTATION_PENDING。App/assets/timing/score/save/metadata未改、未build/install/upload；physical FPS/input latency仍未量測。建議先補第一關land→idle→anticipation→flight以及回復後銜接，保留已接受跳／掉落曲線；第2–10關slice仍deferred。PHONE08自動launch仍locked歷史，不補造成功receipt。

### 2026-10-09 — PHONE-09 同 Wi-Fi 重裝

Owner明確要求現在同Wi-Fi安裝。重用PHONE08已簽署GAME24 Debug0.1.0(13)，107來源／frozen包／簽章／原手機profile／compiled表情assets PASS，fresh paired localNetwork確認；不因review文件重建或加build號。Status INSTALL_PENDING；此次不是兩跳間動作修正版，已向owner說明。契約PHONE09；保持data/container、第一關接受pending及第2–10關deferred。

PHONE09交付：in-place Wi-Fi install PASS、devicectl launch PASS，App已啟動（process receipt可查）；原版本／來源107不變、未reset/uninstall，未build或上傳TestFlight。Status INSTALLED_AND_LAUNCHED_FOR_TRIAL；PHONE08原locked launch仍保留歷史，本次成功另記。下一步仍是第一關完整idle/anticipation循環實作與體感／physical驗證，不將再次安裝當作修好或first-level完成。

### 2026-10-09 — GAME-25 兩跳之間銜接實作

Owner明確授權「做下去幫我安裝」。先定GAME25 exact-file L2 contract：補grounded呼吸／局部tail-ear-antenna連續動作、real upcoming note蓄力、landing/recovery淡入及有效first early優先顯示flight。保持originalPNG/anchors與已接受flight/recovery曲線、音訊/input/grade/save不變；full App/Core及native整段/像素/脚點檢查後才Wi-Fi安裝。Status IMPLEMENTATION_IN_PROGRESS；F5結果接點另留pending，不擴第2–10關，不上傳TestFlight/public。

GAME25 source/native gate通過：107來源isolated/current一致、105個GAME24輸入不變，八個既有曲線／atlas／route block完全保留。App81/Core53、實際觸控與stop/restart UI1 PASS；333 native specimens涵蓋三角色四跳、回復與尺寸/light-dark。原生像素證明grounded上半身改變、脚點固定；scene-local cached shader及paused/reduced reset檢查PASS。Status SOURCE_NATIVE_TESTED / WIFI_INSTALL_PENDING。25samples/s重播不是physical FPS證据；first-level體感/physical timing及F5結果接點仍pending。

GAME25交付：source cdc2e1e，以本機signed Debug0.1.0(13)候選凍結並綁定107測試來源，compiled motion/expression/icon/privacy、原手機profile及fresh localNetwork PASS。in-place Wi-Fi install與launch皆PASS，未reset/uninstall，與TestFlight13來源不同。三角色grounded上半身motion、蓄力、landing/recovery回接、first early顯示已實作；Status INSTALLED_AND_LAUNCHED_FOR_TRIAL。原飛行／掉落travel、音訊/input/判分/save不變；實機FPS、體感、第一關完整接受pending，F5結果接點及第2–10關延後。未上傳TestFlight/public，未用GitHub Mac。

### 2026-10-09 — GAME-26 第二關左右接力跨島

Owner明確開始第二關，僅第二關解除之前2–10關deferred；不把這個指示當作第一關physical/child驗收。保留既有quarter-hands65BPM／4bars／16 R,L,R,L與unlock/star/save。新片準備/HUD/scene交替R/L與双鼓墊，原生timestamp/matcher仍依拍點、無手別偵測；原飛行/回復/素材/audio不改，60BPM music bed留第一關。契約GAME26先定allowed/forbidden/failures/checks/rollback；Status IMPLEMENTATION_PENDING。其餘3–10關、F5結果接點及public gates待後續，build/tests本機。

### 2026-10-09 01:10 — 約十小時無人值守工作授權

Owner將睡覺，要求切續工作並持續做下去，疑慮十小時後集中確認。起點2026-10-08T17:10:43Z（台北10/09 01:10:43），集中回報時間約2026-10-09T03:10:43Z（台北11:10:43）。先完成第二關及獨立檢查，再按既有十關catalog逐片推進；3–10關原先等待條件在此授權下改為工程驗證依賴，不臆造第一關physical/child接受。每片先契約、檢查再本機實作/驗證，保存來源/失敗/進度、commit及branch push。需owner決定的玩法/素材或真機鎖定等記錄後做獨立工作，這段時間不反覆詢問。仍不做未授權功能、PR/merge/TestFlight/public，不把機器測試當physical驗收，不重跑無新增理由的測試填滿時間。

GAME26 engineering進度：App87/0、Core53/0通過；後續僅R/L場景提示opacity固定1、native斷言及UI章節腳本修正，最終候選另驗native1/0、actual touch/stop/restart UI2/0。保存失敗/重試/恢復與原第三關lock成立。首次App86pass/1fail（fractional65BPM提示相等點10assertions）及首次UI1pass/1fail（harness查錯篇章）原始證據保留；不稱所有嘗試皆綠。Status FINAL_LARGE_TEXT_GATE_PENDING。第二關phonetrial尚未安裝；Night後續stage已定third/fourth密拍契約，待此gate完成。

2026-10-09 01:38 GAME26 engineering gate: full App87/0 before opacity-only delta; final focus1/0 plus UI3/0, Core53/0 unchanged. Source e801bc4; no phone build/install/upload. Largest-text actual screenshots reveal actor below fold, dark mission contrast and result/tab overlap: separate responsive presentation slice required; physical timing/FPS/child acceptance not claimed. NIGHT01 continues GAME27 levels3/4 density.

2026-10-09 GAME27 implementation starts after GAME26 engineering evidence03f1cc1. Exact scope: authored level3/4 base profiles; validated read-only density grid, continuous overlapping accepted arcs, pooled >16 island path,32-target HUD and instructional R/L. Music-bed flag remains first-only. Shared responsive layout/F5 require separate later scope.

2026-10-09 01:58 GAME27 source complete, local App92/0 and added viewport overlap1/0, initial focus5/0. UI1passed first-level regression/1failed new harness before input because XCTest gesture max10 versus12 requested. Corrected test to10 only; production unchanged; final real dense UI gate pending. Raw source/results preserved.

2026-10-09 02:01 GAME27 second UI attempt sent all10 native touches within first~2.6s of four-beat count-in and correctly got0 hits. Harness now observes actual visible count-in completion (no injected route/targets), then uses10 single-pad or5right+5left native taps. Production unchanged. Both failed UI attempts retained; final gate pending.

2026-10-09 02:04 GAME27 ENGINEERING_GATE_PASSED: production20a99b8/final test1a29f8d. Full App92/0, added native overlap1/0, Core53 component unchanged; final dense UI1/0 + earlier first UI1/0.102 native PNGs,4 actual dense UI screenshots; all raw failure attempts preserved, all sim states restored. Physical pending; GAME28 proceeds.

2026-10-09 02:07 GAME28 starts fromd69e2a2, exact presentation-only contract. Remove gameplay scene from cropping scroll region; compact essential HUD at AX sizes while full speech labels retained; fixed warm/light mission capsule; result bottom scroll clearance. Also bound dense backdrop parallax to actual overscan on compact late scenes, no actor/clock change.

2026-10-09 02:21 GAME28 initial native failed only wrong test anchor55% versus reviewed55.1%; background cover passed. Initial narrow UI failed absent StatusBar AX before viewport assertions (raw log/bundle retained; new summaryDBError but legacy object readable). Corrected harness window-top fallback and expected baseline. Presentation now reserves scaled feedback height and uses concise AX action text with full speech labels to prevent dynamic scene resizing; final local gates pending.

2026-10-09 02:30 GAME28 narrow largest2/0 plus nativefocus1/0; actual PNG review finds result scene capsule covering character head. Fix scene caption singleline AX caption style, retain full speech label. This final UI delta must be validated; prior passed roots/evidence preserved. Same-xcresult exports sequential after shared SQLite index race identified.

2026-10-09 02:55 GAME28 final engineering gate: native compact background1/0, real-touch normal dark2/0, largest primary-dark2/0 and narrow-light2/0.107 inputs/103 unchanged; scene/motion prefix exact except scoped backdrop clamp/caption. Actual PNGs whole actor/input/stop and result stars clear tab; all owned sim states and booted light appearances restored. Initial native wrong-anchor0/1 and narrow statusbar harness0/2 retained; no phone build/install/upload. GAME29 rests proceeds; physical/F5 pending.

2026-10-09 02:57 GAME29 begins after responsive gate33665f6; authored5/6/9 only, readonly rest cells/count-in/next hand/path. Input/audio/matcher/catalog/save unchanged; first4 equivalence required.

2026-10-09 03:13 GAME29 engineering gate: authored5/6/9 rest cells and target-count paths8/20/16 implemented, four-beat count-in from grid origin (initial rest supported), matching feedback precedes wait. Local full App101/0 including7 new failure/native/save tests; actual UI2/0 covering3levels real rest/touch/cancel/restart and ninth0star/lockedtenth.54native/10UI PNG, source107/103unchanged,11motion blocks exact, Core53 unchanged component. Owned simulator restored Shutdown/light; phone/public/physical pending. Automated fine-note soundtrack not claimed; quarter click unchanged. NextGAME30 existing7/8/10.

2026-10-09 03:15 GAME30 starts after7548d92: authored7/8/10,64/64/40 actual targets with64gridcells. Readable grouped4×4 cue and existing dense arc/pool; closest-neighbor acceptance/continuity and mixed-rest legal early checks required. No audio/core/save/art change.

2026-10-09 03:28 GAME30 initialfocus8/1 (6 native top bounds assertions). High-density burst dino/cat body rotation exceeds200pt viewport~1–2pt; scoped high-only hop amplitude14% instead16%, full burst-pose native check, first6/9 unchanged. Failure evidence/root retained; final gates pending.

2026-10-09 03:40 GAME30 engineering gate: existing levels7/8/10 now use authored64/64/40-note island journeys, four groups of four musical cells and full speech; original audio/input/score/save/art unchanged. Native9/0 plus actual UI3/0,72native/10UI captures; all owned states/light restored. Initial8/1 native bounds failure retained; high-only trajectory14% gives rotated sprite margin, no clipping/FPS claim. Full App101 applies GAME29 source only, Core53 unchanged. Phone/Public pending. Next scopedGAME31 fixes existing result teleport without fake travel/score.

GAME30 evidence correction: original native9/UI3 observed but first canonical binding check failed20 missing temp files; build log proves lessons/privacy copies existed at build, retention cause unknown. Premature memory PASS label explicitly superseded by canonical correction record. Original roots/results/failedreceipt retained. Persistent107-input freeze rebuild and gates pending; no final source-binding completion claim until checked.

GAME30 persistent rebind complete: exact107 current/git4eb1adb/frozen inputs, new local build/native9/UI3 gates; all ownedsimstates/light restored. Prior failedcanonicalreceipt and temporary retention gaps kept in TestResults/GAME-30/pre-retention-gates; original tests are observed historical attempts, final completion requires fresh canonical checker PASS. No production source delta during rebound; physical/phone pending.

2026-10-09 03:51 GAME31 begins after72dbf4d persistent GAME30 gates. Fix actual-end result terrain/pose teleport and truthful partial achievement; bounded<=.80s purely cosmetic settle, no clock/target/score/save change. Contract exact files and failure/pause/reset gates defined before edits.

2026-10-09 04:13 GAME31 engineering gate passed: native7/0 plus actual largest-dark/compact-light UI2/0;108native/4UI PNG show actual end-position, partial14/16 and28/32 stay2stars, real late64/final miss63 settle without fake target/score/transport. Local signed phone candidate pending final QA. Source103/107 unchanged;9 motion blocks exact, dense optional bounded tail guard/default0 and atlas numeric ULP display-end guard explicit. Initial test build API/try failure and focus6pass/1fail27assertions preserved; final native ground1e-5pt representation tolerance, atlas1e-9 tolerance not timing precision. Owned states/light restored with baseline provenance documented. No physical acceptance or Apple upload; next full local App/Core + ten-lesson UI walkthrough.

2026-10-09 04:15 QA-NIGHT01 full local App/Core begins afterGAME31 engineering gates2e71d1d. Candidate107 current/frozen/git1949867 equal; reuse exact local built App/test executables, no source delta. Ten-lesson real UI walkthrough and three-page settings/cold-launch follow once App gate completes. Source/schema/audio/save/metadata unchanged; no physical readiness claim.

04:27 QA-NIGHT01 initial fullApp113=97pass/16fail plus host crash retained. Failures point to old cache/Dead bundle while fresh installed/frozen107 resources match; unchanged-source clean-process retry in progress, hypothesis not proven. Core53/0 fresh local PASS. ActualUI and signed phone candidate not yet run; no owner prompt before deadline.

04:33 QA-NIGHT01 clean-process fullApp113/0 and Core53/0 passed onunchanged107 source1949867. Firstattempt97/16+crash retained, stalebundleURL cause remains hypothesis. Ten-lesson UI and3surface checks next; package/install not yet executed.

QA-NIGHT01A defined for companion UI harness: original10tap gesture finishes before realcount-in onfastAX and correctlygets0; bothcat/robot fail, sequentialactualtouchcasepassed. WaitexistingrealjumpCue (finite8s), no clocks/hits/production changes. Initialbundle must remain and new107 freeze/build/fullApp/UI gates bind corrected harness.

09:12 owner「繼續」後續行：sourcea55d1b8只修UITest真實count-in與hiddenStatusBar fallback。107 persistentQA凍結中106與GAME31相同，本機重新build-for-testing進行中；早先113/Core53不誤稱為新編譯包測試。最遲11:10後集中待確認事項，不宣稱期間持續執行時數或真機流暢度。

09:25 QA-NIGHT01B defined after newcompiled a55 fullApp callbackcase fails fixed350ms pausedcheck then receives terminalcallback during80ms countcheck; laterpausedsamekeyassertionpasses. Preserve rawattempt; no provenGPU/OS cause or physicalFPS inference. Test-only finite2s observeactualpause+realcallback+unchangedstopcount assertions; allproduct/clock/save remain exact. New107 freeze/build/fullApp/UI gates next after currentnative completes.

10:00 GAME32 defined beforeedit: QA42a5 App113/actual4walkthrough pass, but25PNGmanualreview identifies croppedfirstheading/invisiblecount in actualrobot/dinosaur shots. Essentialrowsfixedverticalsize+Scenepriority−1; largestshortviewport wholeScrollView200scene, no physics/audio/input/score/save change. Actual3theme rowvisibility regressions +tenlesson/surfaces +primary/narrowlargest gates requiredbeforephonecandidate.

10:03 QA42a5 App113/actualwalkthrough4/surfaces5/callback1 allPASS; Core53samecomponent. ManualmatchingPNGs stillcroppedheading/count; sourcef4a499e isolatedSwiftUIcompositiononly, wholeScene/motionprefixexact/104inputsunchanged. Persistent107newlocalbuild/gates running; phonepackageawaitsfinalQA. No physical/public claim.

10:25 GAME32 finalfullApp113=111pass/2fail: actualresultcallback2s deadline thenlaterpause, and nativeAudioToolbox RemoteIOStop RPCabortduringhighdensityactualfinish. Rawresult/crash/source retainedinitial-RPC-attempt. Stack provesAVAudioEngine.stop site, notrootcause. Onlyownedprimaryshutdown/boot; samecompiledsourcefocused2 thenfullregression retrydefined; no product/audiochange ordeliveryclaim.

10:43 GAME32 unchangedcompiledsource afterownedcoldboot: focusedfailed2/0 andfreshfullApp113/0 passed. Initial111/2 RPC/callback failure/crash remainsretained; rootcause unproven, not claimedfixed. Actual4walkthrough/5surfaces/primary+narrowlargest1each underway; no signedphonecandidate/installyet.

11:02 original-resolution review corrects false cropped-preview diagnosis: QA42/f4 Robot bothfull; f4 all3 PNG actualcue/count pixelrows present. QA01C definedbeforeedit: restoreentireEggMissionView byte-exact42; tenSmokeonlydirecthittableStop toavoidabsentnavqueries nearrealend. Initialf4UI3pass/1fail atthirdStop retained, event/finishorderunproven. f4signedstagingnotinstalled/superseded; new107build/UI/focus/sourcebindingrequired; App113/Core53 mayonlyreuse exactQA42nativecomponent, nofreshfullsuiteclaim.

11:26 QA-NIGHT01D defined beforetest-onlyedit: newC threeactualrole cases passed, ten-smoke failed attenthStop after~21s genuineevent versus shortlesson normalend. Actualall10headings/count-in captures retained; no productioncancel defect or resource rootcause claimed. Start/Stop smoke now genuineStop immediatelyafterStart; preparationidentity/return unchanged10progress remainrequired. Newpersistent107/UI8 with exactC three-role/nativefocus2 and QA42App113/Core53 componentbasis; phone/sourcebinding pending. C diagnostics retained; no phoneinstall.

11:45 D ten-smoke initialexit65: "Test crashed with signal term.", observedprep1–7; postterminationoriginalownedprimary/narrowShutdown, pipelinehadnotcalledshutdown. Rootcause/actorunproven; samplewronglymatchedshellrejected. Same107Dimmutablelocalbuild willretryonnewuniquetask-ownedsimulators, cleanupowncreationonly; no source/window/deadlinechange or globalservice/otherprojectkill. Signedphone remainswaitingQA.

12:07 QA-NIGHT01D samecompiledsource1ace unique-device retry passedfreshUI8/0 (ten-smoke1, surfaces5, primaryDarklargest1, narrowLightlargest1); actual12originalspecimens reviewed, ownedtempdeviceslight/shutdown/deleted, originalownedstatesunchanged/externaldeltas preserved.107 current/frozen/git1ace/equivalent7cdac;106unchangedQA42. App113 QA42/Core53 QA194 exact-component evidence only, Cnativefocus2 andthreeindividualrolePASS exactmethodbasis; no newhostfull113 claim. CanonicalQA-NIGHT01 checkerexit0 linked7cdac. Retain C3/1lateStop, D0/1signalterm, initialRPC/stalehost/callback failures; rootcausesunproven. NewmatchinglocalDebug13 phonebuild inprogress, installation/physical/child/public pending.

12:12 PHONE10 matching source1ace /107 inputs/13 frozen package files passed local Debug13 build, signature/profile/resource/catalog checks. Fresh exact owner device localNetwork connected; actual in-place install exit0/success, automatic launch exit1/Locked. Canonical PHONE10 candidate/install PASS has this limited boundary; separate locked-launch FAIL retained. No uninstall/reset/phone fixture, no Apple upload. Retained owner progress not yet observed; physical timing/FPS/child/public pending. All ten source and applicable local engineering gates complete; branch push authorized, public/PR/merge not performed.
