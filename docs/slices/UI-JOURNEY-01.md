# UI-JOURNEY-01 — 選關與準備頁產品化

Status: IMPLEMENTED / LOCAL CANDIDATE PASS / DEVICE ACCEPTANCE PENDING。Risk: L1。Dependencies: QA-PLAY-01本機及適用真機gate；owner選定A/B。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本批source已實作，尚待當次本機回歸及適用真機gate；以下是實作界線。

## 行為與UI

將選定方案接入既有十關，不新增內容。只讀既有targets與session投影；若接入時需要改時計／input boundary，先升L2並補契約，不以L1界線實作。選關以章節/路徑、星星、目前關/鎖定原因呈現；卡片只留節奏類型、BPM、一句目標。準備頁有可理解的操作預覽、四拍預備說明、實際一星條件、角色與開始，其他設定集中入口。型態由catalog讀取，沒有虛構Easy/Hard模式或難度適齡宣稱。

## Allowed files

BeatLab/Views/PracticeView.swift；BeatLab/Views/PracticeComparisonView.swift（promotion routing only）；BeatLab/Views/FallingRhythmScene.swift或RunnerRhythmScene.swift（所選版read-only ten-profile配置）；BeatLab/Views/HomeView.swift（continue destination only）；BeatLab/Design/BeatLabStyle.swift；BeatLabTests/PracticeStoreTests.swift（native layout fixtures）；BeatLabUITests/PracticeUITests.swift。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/UI-JOURNEY-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

改catalog/BPM/門檻、從prototype結果寫正式progress、解鎖fixture、角色素材／新模式、主節拍器重設、加商店/排行/account。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

選關星星與保存不同步、prototype污染推薦關卡、locked lesson被圖示按入、稀疏與密集譜使用錯誤預覽、首頁繼續指到不存在關卡、設定重複／大字截斷。

## Checks / gate

所選版四分／八分／四格／休止／反拍預告密度与ID/time不變的獨立fixture，十關全部準備／開始／取消smoke、locked/future/corrupt progress與保存後reload、首次啟動／首頁繼續、正常及最大字級窄手機/iPad/Light/Dark；準備預覽與catalog ID/type/BPM/門檻fixture一致。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

還原原journey/preparation路由，保留正式progress；A/B比較入口仍隔離。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。

Owner已選A預設；B仍DEBUG比較。此次正式旅程UI導入是local/device candidate，待QA真機與兒童接受，並非提前接受產品gate。Allowed PracticeStore.swift僅選定presentation狀態/全螢幕route，不改目標/判分/save；PracticeComparisonView.swift承載共用遊玩容器。

整合界線补充（本次編輯前）：allowed RootView.swift僅首頁「今日挑戰」入口選擇已保存progress.recommended後再開準備；禁止改星星/保存/target。現有入口只切tab，DEBUG比較退出後可能保留locked trial selected而打開錯關；回歸從B退出→首頁今日挑戰→原推荐關準備/正常開始，鎖定不改。回退只撤首頁routing，不清進度。

## 此批真實證據（2026-10-11）

2026-10-11：八個功能slice已實作並通過本機候選檢查；QA本機部分通過，真機/兒童/完整Accessibility仍未接受；已原地安裝並成功開啟。A雙軌為正式旅程預設，B跑酷在DEBUG練習設定的「操作比較」保留，使用原2/3關同譜、同聲音與判分且不保存試玩成績。版本0.1.0（14），驗證來源5580a14；簽署包來源96ad73a，所有product/native-test inputs SHA256相同，最後變動僅UITest。此批沒有Apple上傳/PR/merge，TestFlight仍為GAME23舊13。

驗證：Core59、原生App126；10個不同UI流程，以9個未改動case＋最終SE觸控重跑組合。通過執行15次＝完整SE10次＋iPad一般/最大字級2次＋Dark一般/最大字級2次＋最終SE觸控1次，包含重複；不稱15個不同case。Debug/Release與簽署iphoneos建置皆在本機Mac。 實際原始結果、初次失敗、來源與候選包雜湊見 [本批驗證](RHYTHM-PLAY-BATCH-verification.json)。前兩關門檻、後八關譜與評分、手機資料schema不變。

注意：本機與安裝結果不證明physical timing/FPS、兒童吸引力、完整VoiceOver或系統Reduce Motion；G1–G4仍未接受。
