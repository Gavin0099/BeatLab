# GAME-17 — 原生節奏路線與事件對齊

Status PHONE_PREVIEW_INSTALLED_NATIVE_UI_PARTIAL_OWNER_PENDING，2026-10-07。依賴GAME-16 owner concept gate；baseline GAME-15／TF-04。Risk L2：audio／input／UI clock邊界，即使新增欄位只讀仍按L2驗。

目的／契約：上方短拍點預覽與下方障礙引用同一份實際session targets、原audio-host epoch與真實matched／expired結果。將presentation中的4／16／1秒猜測收斂成只讀資料。第一輪入口仍限first-beat60 BPM；保留4拍count-in、原endTime／matching窗口／calibration semantics。target到固定跨越點的時間由target timestamp決定；提早matched不讓未到點石頭消失；分離目前拍點、音符設定、accepted狀態。

Allowed exact files：`BeatLab/App/PracticeStore.swift`（只讀presentation資料）、`BeatLab/Views/EggMissionView.swift`、`BeatLab/Views/PracticeView.swift`（只接資料）、`BeatLabTests/PracticeStoreTests.swift`、`BeatLabUITests/PracticeUITests.swift`；必要時新增 `BeatLab/Views/RunnerPresentation.swift` 及 `BeatLab.xcodeproj/project.pbxproj` 僅檔案membership；本slice／`docs/slices/GAME-17-verification.json`、PLAN、canonical evidence／memory、ignored `TestResults/GAME-17/**`。
Forbidden：`BeatLab/Audio/**`、`Sources/**`、課程／分數／校正／星星／保存規則、UIKit timestamp/input path、signing/version/assets；不擴大其他BPM或關卡的跑酷入口，不把動畫／碰撞變成音訊或判定時鐘。

Checks／QA-02A：独立fixture驗first-beat4秒首拍、16targets、最後19秒目標與原結束窗口；matched早／晚、tie、extra／duplicate、expired、calibration有效／無效、count-in邊界、非finite clock、取消／重啟／中斷／route change。驗零輸入實際miss、early accepted cue仍到點、既有Core及適用App／UI回歸；不得只驗mock欄位。native小屏／XXXL／dark／Reduce Motion立即驗，實機音訊拍點、marker、障礙到點先作同步sanity。
Failure：targets未就緒時顯示準備／停止入口，不能自己生成假拍點；expired資訊無法安全只讀時記具體缺口，先修契約，不放宽matching或提前判miss。資料generalized不等於其他lesson已verified。
Rollback：回復本片presentation adapter／view，不碰progress schema；可恢復build11行為，保留新增失敗回歸。禁止重設資料、改音訊timebase作補救。

## Owner 直接 iPhone 試玩調整（2026-10-07）

Owner明確指示「直接安裝到iphone比較快」：允許跳過browser owner acceptance作為此次個人手機preview的前置，先把GAME-16概念接原生再安裝，沒有宣稱玩法／QA gate已接受。三片只合併最小phone-preview範圍：GAME-17只讀real targets／accepted／expiry adapter與四格route；GAME-18保留現動作，修有效early起跳及只讀expiry recovery；GAME-19只改第一關準備文案／練習中的四格與matched進度，保留真實結果／保存／retry與三角色。未完成項仍pending，先安裝供owner驗收。

本候選exact edit set：BeatLab/App/PracticeStore.swift只增read-only accessor；BeatLab/Views/EggMissionView.swift內嵌adapter（不增檔membership）；BeatLab/Views/PracticeView.swift準備文案；BeatLabTests/PracticeStoreTests.swift；BeatLabUITests/PracticeUITests.swift僅補live cue斷言；本三slice／GAME-17-verification.json／PLAN／canonical evidence與memory；ignored TestResults/GAME-17/**。禁止音訊/Core/input timestamp/matching/score/save/assets/version/signing變更。用既有same bundle/team development簽署，fresh paired Wi-Fi install/launch，無uninstall/reset/upload。

Checks：原真實matching＋new read-only adapter獨立fixture（失效資料、校正expiry、early／late／duplicate／miss、cancel／restart）、實際App regression／小屏和大字flow／zero-input failure及touch、build與signed frozen hash/device綁定。實機同步／流暢度與child gate由owner接續；不得將安裝當accepted。Rollback只回復此exact edit set，保留失敗與learner data。

## 個人手機 preview 交付（2026-10-07）

Source d13697b；signed Debug0.1.0(11) Wi-Fi install／launch PASS，保留資料，TestFlight不變。只完成上述minimum preview，完整slice gate未接受。App unit56／dinosaur UI3 PASS；initial companion2 FAIL後縮短harness，final robot PASS、cat再次開始counter缺失FAIL；narrow dark最大字級1 FAIL（查停止時已到結果），empty retry0 tests不接受。Cat失敗hierarchy仍是準備頁且保留停止notice，根因未確定；不宣稱只是harness。Physical timing／流暢度／child／public與full10關回歸pending。詳GAME-17-verification.json；narrow已restore light／shutdown，沒有重置其他simulator。
