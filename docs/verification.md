# BeatLab 驗收與證據

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
