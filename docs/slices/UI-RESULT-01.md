# UI-RESULT-01 — 结果與快速重試

Status: IMPLEMENTED / LOCAL_VALIDATION_PENDING。Risk: L1。Dependencies: UI-JOURNEY-01。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本批source已實作，尚待當次本機回歸及適用真機gate；以下是實作界線。

## 行為與UI

結果主角為真實星星、命中目標數、miss/extra与最佳紀錄；初學模式一句可行回饋，Standard才露現有誤差統計且不稱硬體精度。精準連擊如展示需只讀本局定義，沒有新保存欄位。成功且保存後才顯示下一關；未過關突出再試，保存失敗突出重試保存／明確捨棄。沿用真实到達數與角色收尾，過關不冒充抵達全部。

## Allowed files

BeatLab/Views/PracticeView.swift（result panel only）；BeatLab/Views/GameResultView.swift（new）；BeatLab/Views/EggMissionView.swift（result composition only）；BeatLab/Design/BeatLabStyle.swift；BeatLabTests/PracticeStoreTests.swift；BeatLabUITests/PracticeUITests.swift；BeatLab.xcodeproj/project.pbxproj（new檔案引用）。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/UI-RESULT-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

PracticeProgress/schema／stars／bestBPM／save retry邏輯、audio/targets/motion算法；不換算虛構score或送免費星星，不用結果特效修改finished時刻。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

一星partial pass顯示全到達、舊最佳被低分覆蓋、未保存先跳下一關、失敗結果正向文字與0star矛盾、結果/tab/重試重疊、反覆retry仍播放前局特效。

## Checks / gate

0star／新1star12/16／2star／3star獨立fixtures與成功/失敗保存；best preserved／reload／末關無下一關、取消不出結果、快速重試回到四拍count-in。原尺寸light/dark/最大字級結果与可達按钮、VoiceOver首次聚焦、Reduce Motion有限收尾。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

恢復原結果panel，保存與真實結果不變。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。
