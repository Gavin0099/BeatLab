# GAME-17 — 原生節奏路線與事件對齊

Status PLANNED，2026-10-07。依賴GAME-16 owner concept gate；baseline GAME-15／TF-04。Risk L2：audio／input／UI clock邊界，即使新增欄位只讀仍按L2驗。

目的／契約：上方短拍點預覽與下方障礙引用同一份實際session targets、原audio-host epoch與真實matched／expired結果。將presentation中的4／16／1秒猜測收斂成只讀資料。第一輪入口仍限first-beat60 BPM；保留4拍count-in、原endTime／matching窗口／calibration semantics。target到固定跨越點的時間由target timestamp決定；提早matched不讓未到點石頭消失；分離目前拍點、音符設定、accepted狀態。

Allowed exact files：`BeatLab/App/PracticeStore.swift`（只讀presentation資料）、`BeatLab/Views/EggMissionView.swift`、`BeatLab/Views/PracticeView.swift`（只接資料）、`BeatLabTests/PracticeStoreTests.swift`、`BeatLabUITests/PracticeUITests.swift`；必要時新增 `BeatLab/Views/RunnerPresentation.swift` 及 `BeatLab.xcodeproj/project.pbxproj` 僅檔案membership；本slice／`docs/slices/GAME-17-verification.json`、PLAN、canonical evidence／memory、ignored `TestResults/GAME-17/**`。
Forbidden：`BeatLab/Audio/**`、`Sources/**`、課程／分數／校正／星星／保存規則、UIKit timestamp/input path、signing/version/assets；不擴大其他BPM或關卡的跑酷入口，不把動畫／碰撞變成音訊或判定時鐘。

Checks／QA-02A：独立fixture驗first-beat4秒首拍、16targets、最後19秒目標與原結束窗口；matched早／晚、tie、extra／duplicate、expired、calibration有效／無效、count-in邊界、非finite clock、取消／重啟／中斷／route change。驗零輸入實際miss、early accepted cue仍到點、既有Core及適用App／UI回歸；不得只驗mock欄位。native小屏／XXXL／dark／Reduce Motion立即驗，實機音訊拍點、marker、障礙到點先作同步sanity。
Failure：targets未就緒時顯示準備／停止入口，不能自己生成假拍點；expired資訊無法安全只讀時記具體缺口，先修契約，不放宽matching或提前判miss。資料generalized不等於其他lesson已verified。
Rollback：回復本片presentation adapter／view，不碰progress schema；可恢復build11行為，保留新增失敗回歸。禁止重設資料、改音訊timebase作補救。
