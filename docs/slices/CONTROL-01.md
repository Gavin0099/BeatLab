# CONTROL-01 — 真正的暫停與續玩

Status: IMPLEMENTED / LOCAL_VALIDATION_PENDING。Risk: L2。Dependencies: PLAY-01與選定UI；實作前需再核對DSP pause/phase契約。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本批source已實作，尚待當次本機回歸及適用真機gate；以下是實作界線。

## 行為與UI

暫停當下停止輸出並凍結有效練習位置，不判未來Miss、不保存半局。續玩先聽四拍，再從凍結位置接回；已判target IDs保留，只判剩餘targets。主選單提供續玩／重新開始／退出；重開與退出取消原局、不給星。中斷／route change／背景依既有安全取消處理，不自動恢復。CONTROL完成前UI只標退出，沒有假Resume。

## Allowed files

BeatLab/App/PracticeStore.swift；BeatLab/App/PracticeTransportProjection.swift（new）；BeatLab/Audio/MetronomeAudio.swift；Sources/BeatLabCore/TimingPractice.swift（explicit resume snapshot import only）；Sources/BeatLabDSP/include/BeatLabDSP.h；Sources/BeatLabDSP/BeatLabDSP.c（只限pause/phase，路徑已核對存在）；BeatLab/Views/PracticeView.swift；BeatLab/Views/GameHUD.swift；BeatLabTests/PracticeStoreTests.swift；BeatLabTests/MetronomeAudioTests.swift；Tests/BeatLabCoreTests/PracticeTests.swift；Tests/BeatLabCoreTests/DSPTests.swift；BeatLabUITests/PracticeUITests.swift；BeatLab.xcodeproj/project.pbxproj（new檔案引用）。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/CONTROL-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

任意挪動畫面當節拍authority、從UI timer播續玩count-in、改matching/Perfect/星星門檻、清除已判hits／加pause miss、progress schema／auto-resume背景／Bluetooth精度宣稱。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

保存原audio musical phase與immutable logical targets；new audibleEpoch投影到凍結session位置，input恰好轉換一次；暫停時及resume count-in非合法區輸入不算extra。實作前把逐拍/拍間/窗口內暫停、對齊offset、重新開音訊及pending buffer規則寫成獨立數值oracle，未完成DSP檔案界線與phase方案不得動source。

## Checks / gate

暫停前/窗口中/小節邊界、重複pause/resume、count-in early邊界、長暫停、末拍／finished、音訊重啟失敗、中斷／route change及background；已命中不重判/未来不漏判、logical errors/star unchanged、結束僅一次。實際手機resume第一拍phase與聲畫同步是L2必需gate，沒有真機證據只能標local candidate。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

回原取消／重開／退出功能，隱藏pause/resume；不reset進度。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。

## 實作前phase oracle與界線補充

停止graph後讀最後完整BLClock，凍結於(renderStartFrame+frameCount)/sampleRate的rendered位置；此位置可能比手指可見時間早/晚一個buffer及輸出延遲，不能宣稱硬體精準。原RenderKernel保留，resume音訊callback先render四拍臨時count-in kernel，sample邊界之後render原kernel，不跳cursor、不重設音色/原bed。聲音排程不靠UI Timer；兩段buffer在callback分割，原host stamp依frame偏移轉換。

獨立oracle：60BPM/rate48000，pause cursor228000即4.75秒；resume audible count-in epoch200，四拍後204秒對應原4.75，下一拍原5.0對應204.25。原logical epoch100，原target105在raw204.25映射105；已判target不重判。65BPM count-in以sample count round(4*60/65*rate)量化、誤差僅定義sample rounding非實測精度。count-in輸入忽略；frozen timeline待resume crossing才前進。中斷/route/background取消，不自動恢復。

另外allowed BeatLab/App/BeatLabApp.swift僅active-session configuration guard；PracticeComparisonView.swift僅pause UI/scenePhase安全退出。新kernel bridge屬MetronomeAudio.swift內、只限practice resume，不改BLDSP transport，因此本片不需改DSP/Core matcher。
