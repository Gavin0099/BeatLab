# PLAY-01 — A/B共同基準與隔離

Status: DEFINED / NOT IMPLEMENTED。Risk: L2。Dependencies: GAME-34、QA-RETENTION-01來源基準。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本次只寫規格；以下allowed是未來本片實作界線，並非source已改。

## 行為與UI

只在DEBUG比較入口使用第二／第三關原譜；約38.82秒播放，兩段count-in及每關結果各自保留。原型不寫入正式進度，也不替手機解鎖。音訊、targets、校準、matching與結果由共同session提供，A/B只切換presentation。有效press與TimingHit為兩個事件，按下反應／鼓聲不等於成功。記錄所按鼓墊作為試玩觀察，先不新增左右正確性評分。

## Allowed files

BeatLab/App/PracticeStore.swift；BeatLab/App/PracticeComparison.swift（new）；BeatLab/Views/PracticeView.swift（DEBUG入口）；BeatLabTests/PracticeStoreTests.swift；BeatLabUITests/PracticeUITests.swift；BeatLab.xcodeproj/project.pbxproj（new檔案引用）。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/PLAY-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

正式catalog、threshold、TimingSession、ProgressRepository／進度schema、發布設定與素材；Release不提供DEBUG入口；不得從scene/collision建立targets。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

normal journey守原有unlock/save；比較session只能2/3且永不寫repository，取消／終了／切版均不授星。音訊失敗／中斷取消、不計分；rapid/duplicate仍由原matcher判。

## Checks / gate

獨立fixture列出第二16、第三32個目標及各自time間隔；A/B相同IDs/times/窗口、模擬相同press取得相同summary。正常旅程仍locked、failed-save仍locked；比較成功／失敗／取消後owner defaults byte-equivalent；count-in窗口邊界、非有限輸入、重開／切版不殘留聲音；DEBUG/Release編譯界線。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

撤比較入口与adapter，正常旅程原路徑恢復；不清除進度。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。
