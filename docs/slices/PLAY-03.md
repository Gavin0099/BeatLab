# PLAY-03 — 方案B時間驅動跑酷

Status: IMPLEMENTED / LOCAL CANDIDATE PASS / DEVICE ACCEPTANCE PENDING。Risk: L2。Dependencies: PLAY-02本機gate通過。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本批source已實作，尚待當次本機回歸及適用真機gate；以下是實作界線。

## 行為與UI

節奏物件按未來target time向固定操作位置移動，保留兩拍預告；物件間距反映原譜四分／八分／休止，而非只依已抵達小島數。B與A使用同鼓墊、聲音、判分和操作線語意；命中引發已接受的角色跳/落地，miss承接不中斷節奏。場景進度与target時間線分開，不能失誤後下一音符改拍。只從DEBUG比較入口切換；原正式十關先不取代。

## Allowed files

BeatLab/Views/RunnerRhythmScene.swift（new）；BeatLab/Views/PracticeComparisonView.swift；BeatLab/Views/EggMissionView.swift（existing motion reuse adapter only）；BeatLab/App/PracticeComparison.swift（read-only projection）；BeatLabTests/PracticeStoreTests.swift；BeatLabUITests/PracticeUITests.swift；BeatLab.xcodeproj/project.pbxproj（new檔案引用）。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/PLAY-03亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

重做素材／改角色已接受動作、audio/input clock／判分/save/catalog；不新增戰鬥生命、currency或collision score；不把L/R改成上下攻擊種類。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

角色跨島進度拖動音符時機、miss/extra後障礙間隔縮短、落地成第二次判定、攝影機跳動讓操作位置變動；B單獨增加背景曲造成A/B不公平。

## Checks / gate

和A同target IDs/times/grades/聲音，在相同輸入錄列得到相同summary；多次miss/extra後future target到線仍不變。獨立rest/dense/quarter spacing oracle、角色連續命中與恢復樣本；實際交替／停止／重開＋QA-PLAY-01B。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

移除B比較adapter，保留A與原正式runner，音訊／進度不動。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。

## 此批真實證據（2026-10-11）

2026-10-11：八個功能slice已實作並通過本機候選檢查；QA本機部分通過，真機/兒童/完整Accessibility仍未接受；已原地安裝並成功開啟。A雙軌為正式旅程預設，B跑酷在DEBUG練習設定的「操作比較」保留，使用原2/3關同譜、同聲音與判分且不保存試玩成績。版本0.1.0（14），驗證來源5580a14；簽署包來源96ad73a，所有product/native-test inputs SHA256相同，最後變動僅UITest。此批沒有Apple上傳/PR/merge，TestFlight仍為GAME23舊13。

驗證：Core59、原生App126；10個不同UI流程，以9個未改動case＋最終SE觸控重跑組合。通過執行15次＝完整SE10次＋iPad一般/最大字級2次＋Dark一般/最大字級2次＋最終SE觸控1次，包含重複；不稱15個不同case。Debug/Release與簽署iphoneos建置皆在本機Mac。 實際原始結果、初次失敗、來源與候選包雜湊見 [本批驗證](RHYTHM-PLAY-BATCH-verification.json)。前兩關門檻、後八關譜與評分、手機資料schema不變。

注意：本機與安裝結果不證明physical timing/FPS、兒童吸引力、完整VoiceOver或系統Reduce Motion；G1–G4仍未接受。
