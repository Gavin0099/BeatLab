# GAME-19 — 引導、結果、重試與三角色整合

Status PHONE_PREVIEW_INSTALLED_NATIVE_UI_PARTIAL_OWNER_PENDING，2026-10-07。依賴GAME-18及QA-02B。Risk L1：journey／copy／三角色呈現；保存或score規則更動不在本片，需另立L2契約。

目的／契約：沿用現有第一關入口，準備頁用一句任務＋短拍點圖说明「聽拍再跳」，接既有4拍count-in；遊玩中場景與下一拍為主，詳細錯誤放結果。結果以真實stars／summary决定送達／再試，說明早／晚／漏拍／多打；原save retry／discard可見。成功／失敗都可重試，取消不計成績。恐龍送蛋、貓咪送魚、機器人送能源共用同一loop，角色性格／場景可不同但時間、判定、任務結果一致。

Allowed exact files：`BeatLab/Views/PracticeView.swift`、`BeatLab/Views/EggMissionView.swift`、GAME-17建立後的 `BeatLab/Views/RunnerPresentation.swift`、`BeatLab/Design/BeatLabStyle.swift`（既有tokens／尺寸）、`BeatLabUITests/PracticeUITests.swift`、`BeatLabUITests/InterfaceUITests.swift`、`BeatLabTests/PracticeStoreTests.swift`（既有result/save可見行為fixture）；本slice／`docs/slices/GAME-19-verification.json`、PLAN、canonical evidence／memory、ignored `TestResults/GAME-19/**`。
Forbidden：PracticeStore／Core／DSP／音訊／lesson及progress schema、星星／解鎖改動、Home／Metronome redesign、增加learn影片／獨立練習或挑戰模式、角色／skin／資源、signing/buildmetadata。不要把3次錯誤結束直接移植。

Checks／QA-02C：三角色各ready／playing／miss／extra／success／failure／retry／cancel；真正失敗不可顯示成功送達，視覺旅程完成不等於通關。真实保存／重開／保存失敗retry/discard，第二關鎖定與另外九關練習入口smoke。小屏（至少SE尺寸）、wide、XXXL、light/dark、Reduce Motion、VoiceOver：scene／短lane／pad／stop同時可及、safe-area不遮蓋，需滾動時整體內容一起滾；不可把大字縮小當通過。
Failure：字卡、cue或浮動tab遮場景／停止、不同角色碰撞／高低線索不一致、未保存誤顯解鎖均需修本片或停止在資料缺口，不碰保存authority。
Rollback：回復本片journey／文案／layout，保留GAME-17/18資料和動作；原進度、角色偏好、關卡schema不变。

## Owner 直接 iPhone 試玩調整（2026-10-07）

Owner明確指示「直接安裝到iphone比較快」：允許跳過browser owner acceptance作為此次個人手機preview的前置，先把GAME-16概念接原生再安裝，沒有宣稱玩法／QA gate已接受。三片只合併最小phone-preview範圍：GAME-17只讀real targets／accepted／expiry adapter與四格route；GAME-18保留現動作，修有效early起跳及只讀expiry recovery；GAME-19只改第一關準備文案／練習中的四格與matched進度，保留真實結果／保存／retry與三角色。未完成項仍pending，先安裝供owner驗收。

本候選exact edit set：BeatLab/App/PracticeStore.swift只增read-only accessor；BeatLab/Views/EggMissionView.swift內嵌adapter（不增檔membership）；BeatLab/Views/PracticeView.swift準備文案；BeatLabTests/PracticeStoreTests.swift；BeatLabUITests/PracticeUITests.swift僅補live cue斷言；本三slice／GAME-17-verification.json／PLAN／canonical evidence與memory；ignored TestResults/GAME-17/**。禁止音訊/Core/input timestamp/matching/score/save/assets/version/signing變更。用既有same bundle/team development簽署，fresh paired Wi-Fi install/launch，無uninstall/reset/upload。

Checks：原真實matching＋new read-only adapter獨立fixture（失效資料、校正expiry、early／late／duplicate／miss、cancel／restart）、實際App regression／小屏和大字flow／zero-input failure及touch、build與signed frozen hash/device綁定。實機同步／流暢度與child gate由owner接續；不得將安裝當accepted。Rollback只回復此exact edit set，保留失敗與learner data。

## 個人手機 preview 交付（2026-10-07）

Source d13697b；signed Debug0.1.0(11) Wi-Fi install／launch PASS，保留資料，TestFlight不變。只完成上述minimum preview，完整slice gate未接受。App unit56／dinosaur UI3 PASS；initial companion2 FAIL後縮短harness，final robot PASS、cat再次開始counter缺失FAIL；narrow dark最大字級1 FAIL（查停止時已到結果），empty retry0 tests不接受。Cat失敗hierarchy仍是準備頁且保留停止notice，根因未確定；不宣稱只是harness。Physical timing／流暢度／child／public與full10關回歸pending。詳GAME-17-verification.json；narrow已restore light／shutdown，沒有重置其他simulator。
