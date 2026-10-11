# QA-PLAY-01 — 逐片本機與真機A/B驗收

Status: LOCAL CANDIDATE PASS / DEVICE_CHILD_ACCESSIBILITY PENDING。Risk: L2。Dependencies: PLAY-01、UI-GAME-01、SOUND-01；A或B各自來源。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
此批已進入實作/驗證；以當次原始輸出為準，不沿用歷史PASS。

## 行為與UI

QA-A跟隨PLAY02，QA-B跟隨PLAY03，不等所有UI做完才測。最終A/B使用相同chart/audio/version，交換試玩先後避免先玩優勢。分列本機、真機與兒童gate，不做單一fake PASS。

## Allowed files

BeatLabTests/PracticeStoreTests.swift；BeatLabTests/MetronomeAudioTests.swift；BeatLabUITests/PracticeUITests.swift；Tests/BeatLabCoreTests/PracticeTests.swift（spam regression only）；Tests/TimingCaptureTests/test_capture.py（若既有schema適用）；docs/verification.md；本片verification JSON／canonical evidence；TestResults/QA-PLAY-01。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/QA-PLAY-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

為通過測試改threshold/window、寫owner unlock fixture、重設手機資料、全域kill音訊／模擬器、GitHub Mac／Apple upload；測試不得注入成功冒充physical touch。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

隨機有限敲擊剛好合法命中不可武斷稱作弊：只以真實匹配與extra規則判。test seed與獨立時刻fixture記錄；零／過早／過晚／全程高頻spam、故意duplicate、count-in、雙鼓墊快速交替、中斷／route change、取消重開、failed-save／restart。

## Checks / gate

本機full Core/App及兩版focused UI；多tempo/offset/reproducible seed spam矩陣，assert命中／extra／miss／star與persist，不只mock callback。真機內建喇叭onset/觸控/到線錄影与校準metadata、interval/p95/p99/max長幀/掉幀/恢復原始資料。兒童年齡段、提示次數、錯按、完成與自願重玩逐次紀錄，未招募/未試玩標NOT RUN。數值與主觀體驗不互相替代。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

測試可分片回退但保留失敗來源／原始輸出；不回退已有手機進度。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。

舊UI regression也需跟隨已核准的新UI契約：live固定鼓墊/判定線取代舊拍格、暫停/退出移至HUD、最大字級不要求装飾角色。更新舊測試的元件/幾何/文字檢查，不刪除判分/保存/觸控/重試/鎖定回歸，也不將未執行歷史case算PASS；native component可與UITest-only change做exact-byte equivalence，但最終UI與候選仍bind新source。

Retained journey UI first attempt: after held-coordinate drag, picker disappeared and dinosaur row query failed; raw current-ui retained. Test helper now uses actual picker scrollView swipe with sheet-still-open assertion, as course browser already does. Only UITest delta; product/native-test bytes stay identical. Root cause beyond observed gesture/closure is not claimed.

Retained viewport first attempt failed before bounds assertions because OS did not export a StatusBar AX element. Same primary-window fallback already used by other helper is now applied to this independent viewport test; fixed line/pad/HUD containment assertions remain. Raw first attempt retained; no product or viewport dimensions changed.

Ten-lesson retained UI first attempt reached preparations1–9 then last row failed helper visibility: helper excluded an invented30pt from sheet bottom even on SE with no home indicator. Remove artificial margin; retain observed window bounds, row enabled/hittable, exact selected lesson and actual Start/Stop/progress gates. Only UITest change; first10-run result retained (7 pass/3 fail), final implicated5-case rerun required.

First implicated rerun reveals transition race: after selected companion tap, underlying journey exists while picker nav is still dismissing; reveal treated journey row as picker row. Wait on actual nav disappearance before opening another row/picker; no fixed sleep. Installed UITest binary SHA matched compiled SHA, so stale-binary hypothesis rejected. iPad first two cases fail only pre-entry TabBar lookup: observed _UIFloatingTabBarItemView is Other; helper now selects the real visible label regardless of native tab class, with destination assertions retained. Raw failures retained; production remains unchanged.

Second implicated rerun: course swipe oscillates above/below quarter-rest row; helper must choose a real hittable row whose activation center and at least44pt are inside the observed viewport, then assert exact prepared lesson. Use bounded no-hold native drag toward observed center instead of full-height flings; no score/time injection or production layout change. Preserve second rerun raw failures/crash and repeat all current UI cases.

iPad corrected-tab run enters A successfully but an8-tap batch yields zero actual matches. Batch duration cannot guarantee any input in the legal window; do not infer a clock defect or silently force success. Replace positive-input batch with up to12 genuine individual pad taps, checking the observable matched count after each; assert nonzero and retain raw result/capture on failure. Negative spam/extra/window tests remain unchanged. Only affected UI input case requires a fresh SE rerun; unaffected9 final SE cases remain exact-byte test-function evidence.

## 此批真實證據（2026-10-11）

2026-10-11：八個功能slice已實作並通過本機候選檢查；QA本機部分通過，真機/兒童/完整Accessibility仍未接受；已原地安裝並成功開啟。A雙軌為正式旅程預設，B跑酷在DEBUG練習設定的「操作比較」保留，使用原2/3關同譜、同聲音與判分且不保存試玩成績。版本0.1.0（14），驗證來源5580a14；簽署包來源96ad73a，所有product/native-test inputs SHA256相同，最後變動僅UITest。此批沒有Apple上傳/PR/merge，TestFlight仍為GAME23舊13。

驗證：Core59、原生App126；10個不同UI流程，以9個未改動case＋最終SE觸控重跑組合。通過執行15次＝完整SE10次＋iPad一般/最大字級2次＋Dark一般/最大字級2次＋最終SE觸控1次，包含重複；不稱15個不同case。Debug/Release與簽署iphoneos建置皆在本機Mac。 實際原始結果、初次失敗、來源與候選包雜湊見 [本批驗證](RHYTHM-PLAY-BATCH-verification.json)。前兩關門檻、後八關譜與評分、手機資料schema不變。

注意：本機與安裝結果不證明physical timing/FPS、兒童吸引力、完整VoiceOver或系統Reduce Motion；G1–G4仍未接受。
