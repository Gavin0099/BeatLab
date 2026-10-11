# PLAY-02 — 方案A雙軌落下式

Status: IMPLEMENTED / LOCAL_VALIDATION_PENDING。Risk: L2。Dependencies: UI-GAME-01、SOUND-01。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本批source已實作，尚待當次本機回歸及適用真機gate；以下是實作界線。

## 行為與UI

兩條清楚的L/R軌道，底部固定判定線與對應鼓墊。提前兩個quarter beats顯示未來targets；半拍為每拍兩格。座標僅讀host/session projection；判定線通過時刻與既有matcher中心及校準處理一致，不二次套offset。休止顯示空格／格線，不生成可按音符。matched ID才移除/命中與觸發角色，extra只按壓，miss窗口關閉才顯示。原有跑酷保留，A從DEBUG比較入口開啟。

## Allowed files

BeatLab/Views/FallingRhythmScene.swift（new）；BeatLab/Views/PracticeComparisonView.swift（new）；BeatLab/Views/PracticeView.swift（DEBUG routing）；BeatLab/App/PracticeComparison.swift（read-only projection）；BeatLabTests/PracticeStoreTests.swift；BeatLabUITests/PracticeUITests.swift；BeatLab.xcodeproj/project.pbxproj（new檔案引用）。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/PLAY-02亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

正式EggMission motion、audio graph/transport、UIKit host conversion、matcher／targets/catalog/star/save；不做同時雙音／長按／滑動，不增加wrong-pad扣分。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

frame skip改目標time、miss在窗口未關時提前判、校準偏移套兩次、倒數期已合法early被UI攔截、兩軌互相遮蔽、cue與按鈕位置移動；不能將touch region當身體手別偵測。

## Checks / gate

獨立time/coordinate oracle：lead2beats、命中中心、窗口前／後、早按／晚按／重複／extra／miss、rest/反拍、count-in、可變frame步長和calibration0/非0。實際左右交替／取消／重開，固定線／鼓墊bounding frames；執行QA-PLAY-01A與原尺寸手動檢視。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

撤A DEBUG routing，既有B runner繼續可用；不改進度。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。
