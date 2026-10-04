# BeatLab — iOS MVP Roadmap
<!-- governance-baseline: overridable -->
> **最後更新**: 2026-10-04
> **Owner**: BeatLab owner
> **Freshness**: Sprint (7d)

## Current Phase

Planning / Governance baseline READY；G0 已凍結於 d872bad（純治理）。S0～S17 全 MVP 原始碼已建立，狀態 IN_PROGRESS（實作完成、Apple／真機／使用者驗收待跑）。Runtime 自動化未完成為非阻塞 KNOWN DEBT。
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
