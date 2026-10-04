# Mac／iPhone 一次驗收

本批涵蓋 S0～S17 原始碼。Windows 已執行 C kernel／source／capture analyzer checks；Swift typechecking、App build、UI、真人與真機 gate 一律 NOT RUN。先跑自動測試，再依 gate 順序判斷 GO／FIX／STOP。來源完成不等於可發行。

## 1. 自動測試

在 Mac 解壓 source 包或開 repo 根目錄，安裝 Xcode 與一個 iPhone simulator：

```sh
bash scripts/run_macos_checks.sh
# 或指定實際可用裝置
xcrun simctl list devices available
bash scripts/run_macos_checks.sh <SIMULATOR_UUID>
```

脚本依序執行 `swift test`、原始 C kernel 長測、simulator build、App/store/UI tests。結果在新的 `TestResults/<UTC timestamp>/`，不覆蓋舊結果。SwiftPM resources 會載入 versioned 10-lesson JSON；無 App 第三方套件。CI workflow 已準備，尚未上傳或執行。

若失敗，保留 build.log／core-tests.log／app-tests.log／MVP.xcresult。不要將 syntax PASS 當 compile PASS。AVAudioEngine tests 需 simulator 有可用音訊輸出；音訊失敗要修正／記錄，不自動 skip 為 PASS。

## 2. 真機安裝與 timing

用 Xcode 開 BeatLab.xcodeproj，選 shared BeatLab scheme、自己的 signing team、唯一 bundle ID 與實體 iPhone。最低 iOS 16；沒有 microphone／MIDI／背景播放權限。先用內建喇叭，精準 timing 不使用 Bluetooth 路徑。

- BL-002A：60／120／180 BPM 各 5 分鐘，記 device／OS／build／route／sample rate、interval distribution／max／drift／interruption recovery；判 GO／FIX／STOP。
- G1：依 docs/verification.md 固定矩陣外部錄製聲音與畫面，各 15 分鐘；BPM／拍號／細分快速切換；20 次 Stop/Start；背景／前景、來電中斷、耳機拔插、route／media reset。
- Gap：4 小節出聲→1／2 靜音→回來，不重啟 phase；畫面保留大拍與靜音提示。
- Ladder：60→65→70，每 2／4／8 小節；240 clamp；手動 slider／Tap Tempo 退出升速；與 Gap 組合。
- Voice：Click／Voice／Both，quarter 的 1 2 3 4、eighth 的 1 & 2 &；其他細分數大拍。素材由裝置 Apple speech 預渲染；首次等待準備。驗 intelligibility、onset、clipping／高速截字、失敗 fallback Click；不是 realtime TTS 排拍。

外部 capture 分析可提供 CSV `expected_seconds,observed_seconds`，同一固定 offset、已知儀器解析度：

```sh
python3 scripts/analyze_capture.py capture.csv --fixed-offset-ms 20 --resolution-ms 0.5
```

20 ms 是命令例子，必須換成這次實測固定 offset，不能為 PASS 調值。先獨立排查 missing/extra 與配對，再分析；解析度或錄製長度不足是 UNKNOWN。分析器的 numeric PASS 不等於 G1 接受。

## 3. 跟拍與課程

- G2：所有 ties、重複／extra、miss、休止與最後一拍；輸入使用 finger-down。Perfect ±50 ms 是體驗門檻，不代表硬體精準度。
- 標準模式「跟拍對齊」先聽 4 拍再跟 20 拍；足夠樣本／穩定才保存。換 route／rate 作廢，Bluetooth 不顯示 calibrated ms。這是 user alignment estimate，包含人的偏差；獨立 input/output latency 實測另記。
- 標準 summary 可匯出 target／tap／error JSON，標明 calibrated estimate 或 uncalibrated；全部留本機，只有使用者 Share 才匯出。
- G3：10 關從頭玩完；quarter→eighth→rest→16th→R/L。R/L 是手別提示，不做手部辨識。過關包含 hit/perfect/extra；大量點擊不能通關。
- 星星解鎖、繼續練習、最佳成績／通過時的最佳 BPM，terminate/relaunch 後保留。標準模式可提高 challenge BPM；失敗不更新 best BPM。
- 至少三位目標年齡使用者短測：看懂拍、知道休止、理解回饋、想再玩。監護人同意，不保存個資／影音；探索觀察不當普遍有效。

## 4. Release gate

逐列填 docs/release-checklist.csv；最低／目前 OS、小螢幕／較新 iPhone、Dynamic Type、Reduce Motion、VoiceOver、亮暗模式、所有聲音與練習長跑／恢復。入門模式隱藏 ms 與 advanced Gap/Ladder，切回入門關閉兩者；標準模式開放完整控制。

所有裝置 gates 與 child checks 尚未接受，TestFlight 未上傳。TestFlight upload／PR／push／merge 需另有授權；目前包是可編輯來源。


## UIUX-01 native 驗收

最新 UI/UX 已套用到 SwiftUI；docs/design/interface-preview.html / interface-overview.png 是設計參考，不是 native screenshot。自動 tests 新增 transport 捲動後仍可操作、course sheet／locked 說明、unsaved progress 保留／重試，XCTest screenshot attachments 會隨真實 Mac test 產生。

真機逐項驗：

- 小螢幕首頁主動作、推薦課程／繼續／自由節拍器可找到；沒有 fabricated streak。
- 節拍器上下捲動時 Start/Stop 仍可用；展開節奏設定才看到 meter/subdivision；語音準備可切回 Click。
- Practice 在準備／playing／finished 切換時回到頂部；四拍 count-in、R/L/rest 圖例、session progress 清楚。
- 普通字級 Tap Pad 固定可點，大字模式自然捲動；16th 的每個 beat 分組與 active dot 清楚。
- Complete／retry／第十關／未保存／校正成功或失敗各有正確下一步；未保存不可誤顯示已解鎖。
- Future-schema reset 與 catalog missing recovery 分開；sheet dismiss／確認對話框後焦點回到發起動作；結果 title 是 VoiceOver 的新焦點。
- Light/dark、增加對比、最大 Dynamic Type、Reduce Motion、VoiceOver／Switch Control：無截字／遮住按鈕／失去 reading order。靜態對比結果不替代 real-device pixel sampling。

參考預覽的 33 layouts、26 palette pairs 通過，不是上述 native acceptance 的 PASS。檢查記 docs/release-checklist.csv 的 G4 行與 actual screenshot／xcresult。
