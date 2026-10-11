# UI-GAME-01 — 全螢幕舞台與遊戲HUD

Status: IMPLEMENTED / LOCAL_VALIDATION_PENDING。Risk: L1。Dependencies: PLAY-01。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本批source已實作，尚待當次本機回歸及適用真機gate；以下是實作界線。

## 行為與UI

使用現有暖白／森林綠／暖黃品牌與共同元件，將舞台和節奏軌道放在主要可視範圍。HUD顯示關卡、BPM、實際播放進度、退出；四拍倒數清楚。鼓墊位置固定、L在左R在右，按下反應獨立於判定；Perfect/Early/Late/Extra與Miss語言一致。現有Perfect streak明稱「精準連擊」，不新增總分。遊玩時隱藏正式tab／navigation，多尺寸退出後恢復。

一般字級直式畫面採上方單列HUD、中間連續舞台與軌道、下方固定雙鼓墊；不用大型文字卡把舞台切斷。判定文字預留固定高度，左右按鈕同寬，舞台與判定線不因combo或miss出現而位移。最大字級可改行／縮減非必要HUD，但不縮小鼓墊字到不可讀；正式觸控時鐘不依UI layout。精準命中以短亮光／角色動作回應，extra只有按壓，miss有可辨失誤；Reduce Motion提供靜態輪廓與文字替代。

## Allowed files

BeatLab/Design/BeatLabStyle.swift；BeatLab/Views/GameHUD.swift（new）；BeatLab/Views/PracticeView.swift；BeatLab/Views/EggMissionView.swift（composition/HUD only）；BeatLab/Views/RootView.swift（tab visibility only）；BeatLabTests/PracticeStoreTests.swift（native layout/presentation fixtures）；BeatLabUITests/PracticeUITests.swift；BeatLab.xcodeproj/project.pbxproj（new檔案引用）。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/UI-GAME-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

audio／input timestamp／targets／匹配／保存／星星、既有motion算法與角色資產；不加假分數／生命／currency；CONTROL前不出現Resume或把cancel叫pause。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

窄尺寸、大字壓縮、判定字造成舞台resize、tab擋鼓墊／結果、timer重設節拍、場景色蓋過提示、多次退出tab不恢復；圖示不可單靠顏色／箭頭。

## Checks / gate

SE窄螢幕与iPad、一般与最大字級、Light/Dark、Reduce Motion/VoiceOver實際流程。可觸控區>=44pt、左右文字可讀、hit/extra/miss及切版不移動判定位置／鼓墊；中途和結果的原尺寸PNG檢視，不能只看準備畫面。Perfect連擊／命中數來源oracle一致。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

回退新HUD／容器、恢复原tab visibility，音訊與保存不動。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。

整合allowed PracticeComparisonView.swift（共用容器）與PracticeComparison.swift（read-only HUD model）；PracticeStore.swift僅press展示與read-only session snapshot，涉及clock實作屬PLAY/CONTROL的L2界線。

最大Accessibility字級隱去非必要角色景觀、將空間給軌道與鼓墊；命中/連擊分兩行，回饋列依字級預留固定雙行高度，grade變化不得移動鼓墊。一般字級保留角色既有動作。
