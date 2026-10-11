# QA-PLAY-01 — 逐片本機與真機A/B驗收

Status: DEFINED / NOT IMPLEMENTED。Risk: L2。Dependencies: PLAY-01、UI-GAME-01、SOUND-01；A或B各自來源。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本次只寫規格；以下allowed是未來本片實作界線，並非source已改。

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
