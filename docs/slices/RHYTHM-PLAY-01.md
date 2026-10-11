# RHYTHM-PLAY-01 — 演奏手感與完整遊戲 UI

2026-10-11 owner要求先切slice，並把主流節奏遊戲的UI納入下一輪導入。
本文件最初為L0切分；owner後續授權十片實作，source已接入A預設與B比较、本機回歸及交付進行中，尚未驗收。
依據目前程式及已保存beatlab-rhythm-game-design參考，不以市場研究代替真機證據。

本次規格編輯allowed：本總表與下列逐片md、PLAN.md、docs/verification.md、
canonical memory/evidence、ignored TestResults/RHYTHM-PLAY-01。
forbidden：App/Core/tests/assets、個人skill、既有manifest/失敗receipt、
手機資料、Apple上傳、PR/merge。既有branch commit/push授權沿用。
檢查：所有切片的檔案界線、依賴、失敗路徑、驗收及回退齊全；依賴無循環、
原型隔離與UI/音訊/判分界線一致；git diff --check。此輪不跑無變更的App測試。
Rollback：只回退本批規格與PLAN指標，保留歷史證據與canonical紀錄。

## 產品方向

讓玩家提前看見節奏，在固定位置敲擊，聽見自己的鼓聲，再看到真實命中
引發角色與特效回應。先做A双軌落下式，再以同一音訊／譜／判分比較B跑酷。
恐龍／貓咪／機器人沿用現有素材；恐龍島嶼暖白、森林綠、暖黃為共同UI基準，
其他角色只更換既有場景與角色強調色，文字、狀態、觸控區與版面規則相同。
不複製其他遊戲的圖像、音樂、關卡或品牌。

## 已核對的基礎

- PracticeStore從audio.audibleEpoch建立host-time目標；UIKit觸控timestamp映射
  至同一host domain；SpriteKit每幀讀presentationElapsed，不是動畫判分。
  這是程式架構，非實測音畫同步或毫秒精度。
- 現有聲音按Perfect/Early/Late/Extra產生短提示音；新的演奏鼓聲需獨立SOUND片。
- 現有拍格顯示當前小節、下一拍提示；小島位置跟隨已抵達進度，沒有固定判定線。
- L/R鼓墊均呼叫同一tap時間匹配；不辨識身體手別，也不檢查選中哪個鼓墊。
- targets要求時間嚴格遞增；每鼓墊目前單touch。雙音同時目標非現成功能。
- 前兩關一星12/16命中、<=4extra、不要求Perfect；二三星／後8關不放寬。
  已有duplicate/extra/zero/spam失敗測試，尚需多速度／偏移／隨機模式矩陣。
- UI原本顯示的streak是Perfect連續命中，不能改名成所有命中的combo。

## Slice與執行順序

| 順序 | Slice | 交付範圍 | 風險／依賴 |
|---|---|---|---|
| 1 | [PLAY-01](PLAY-01.md) | 約40秒A/B基準、DEBUG隔離、共同預告資料與演奏事件 | L2／GAME34來源 |
| 2 | [UI-GAME-01](UI-GAME-01.md) | 全螢幕舞台、HUD、倒數、固定鼓墊、判定／精準連擊元件 | L1／PLAY01 |
| 3 | [SOUND-01](SOUND-01.md) | 穩定敲擊鼓聲，與判定效果分開；兩手同鼓同音色 | L2／PLAY01 |
| 4 | [PLAY-02](PLAY-02.md) | A雙軌落下式，固定判定線與兩拍預告 | L2／UI-GAME01、SOUND01 |
| ↳ | QA-PLAY-01A | 本機A流程／輸入／尺寸檢查；新包真機單版基準 | 執行QA-PLAY01對應項目 |
| 5 | [PLAY-03](PLAY-03.md) | B時間驅動跑酷，沿用A同譜／聲音／判分 | L2／PLAY02本機gate |
| ↳ | QA-PLAY-01B | 本機B流程／輸入／尺寸，A/B對等核對 | 執行QA-PLAY01對應項目 |
| 6 | [QA-PLAY-01](QA-PLAY-01.md) | 完整本機回歸、真機量測、兒童A/B觀察 | L2／A/B；分開記錄各gate |
| 7 | [UI-JOURNEY-01](UI-JOURNEY-01.md) | 選關／準備，接入選定操作方式與現有十關 | L1／owner選定A或B |
| 8 | [UI-RESULT-01](UI-RESULT-01.md) | 結果、最佳紀錄、真實解鎖、重試／下一關 | L1／UI-JOURNEY01 |
| 9 | [CONTROL-01](CONTROL-01.md) | 真正暫停／四拍預備續玩、重新開始與退出 | L2／已選定UI |
| 10 | [DELIVERY-PLAY-01](DELIVERY-PLAY-01.md) | 分階段全新簽署包、SHA256、Wi-Fi交付證據 | L1／各當次本機gate |

DELIVERY可在A本機gate通過後先執行一次，再交B，使用不同candidate ID。
手機可測不代表A/B勝負或公开接受；UI-JOURNEY接入正式旅程前先取得owner的
操作方式選擇。不因等待手機/兒童證據而重寫其他關卡或增加內容。

## 主流遊戲UI必備範圍

| 畫面 | 必備元素 | 狀態與行為 |
|---|---|---|
| 選關 | 既有章節、關卡節奏類型、BPM、星星、鎖定理由、繼續入口 | 精準反映已保存結果；不虛構Easy/Hard模式 |
| 準備 | 單句操作示範、節奏預覽、一星條件、角色、開始 | 不堆疊重複設定摘要；設定另入口 |
| 倒數 | 四拍音訊預備、即將到達音符、可辨的開始訊號 | 原有合法early窗口保留，不能因視覺倒數漏收輸入 |
| 遊玩 | 大舞台、固定判定位置、兩拍預告、左右鼓墊、節奏進度 | 常駐資訊精簡；正式tab在遊玩時隱藏、退出恢復 |
| 即時回饋 | 鼓墊按下反應、真實Perfect/Early/Late/Extra、Miss、精準連擊 | 文字+形狀，不只靠顏色；不把Extra變成功、落地非第二判定 |
| 控制選單 | 重新開始、退出；CONTROL後才提供暫停／續玩 | CONTROL完成前只顯示「退出」，不能把cancel稱為pause |
| 結果 | 真實星星／命中／miss/extra、最佳紀錄、保存狀態、重試／下一關 | 保存失敗提供重試保存；不顯示未成功解鎖的下一關 |

不加入虛構總分、生命條、體力、貨幣、商城、排行榜、每日任務、Skin、新角色。
長按／滑動／雙音齊擊另議；半拍／四格示範音訊須另開SOUND-02契約，
不暗中加入其中一版破壞A/B公平。KidsCharacterKit仍延後。

## A/B不可變規則

使用原第二關65BPM四分交替、第三關60BPM八分，每關4小節＋4拍count-in；
兩段實際播放合計約38.82秒，準備／結果停留時間另計，不能為湊40秒改譜或tempo。
兩版只改呈現：相同targets IDs/times、校準處理、匹配窗口、音訊、鼓墊、
角色、四拍預備、視覺提前量、試玩順序對調，保存均隔離。
不新增鼓墊正確性扣分；L/R是練習指引，兩版準備頁均說明目前只判時機。
每次敲擊的press事件與真實TimingHit分開；press觸發鼓聲與按壓，match才推進角色。
動畫碰撞不產生targets或判分，miss在既有窗口關閉後才成立，休止沒有target。

## QA與交付界線

每片即驗一般/最大字級、窄手機/iPad、Light/Dark、Reduce Motion、VoiceOver。
控制區至少44pt；最大字級左／右標籤不得再靠縮到不可讀解決。
本機行為gate、真機timing/FPS gate、兒童體驗gate分開，不能互相替代。
真機使用新candidate及原始影音/幀資料；平均FPS不代替長幀尾端分布。
舊PhoneFrozen app缺失記錄維持FAIL；新包是新交付，不叫恢復原bytes。
所有build/test在本機Mac；保留失敗嘗試，不使用GitHub Mac。
此批規格不含TestFlight/public/PR/merge，發布要另行明確指示。

## 參考（官方機制核對，非實際逐款試玩）

- [太鼓Pop Tap Beat官方](https://poptapbeat.taiko-ch.net/)：紅藍為鼓面/鼓邊，
  不映射左右手不同音色；借用簡潔操作與清楚音符語言。
- [COLORFUL STAGE官方時機回饋](https://sega.helpshift.com/hc/en/12-hatsune-miku-colorful-stage/faq/753-is-there-a-way-to-get-feedback-on-the-timing-of-my-taps/)：
  早/晚與錯方向是可辨結果，支持把演奏音色與判定回饋分開的設計提案。
- [Muse Dash台灣商店開發者說明](https://apps.apple.com/tw/app/musedash/id1361473095)：
  音樂跑酷，現為16+；僅參考動作與節奏連結，不作兒童內容範本。
- [A Dance of Fire and Ice開發者](https://fizzd.itch.io/a-dance-of-fire-and-ice)：
  單鍵與道路節奏、offset；簡單操作也能支持節奏深度。

Status：source實作已接入A為預設，B比較入口隔離；完整本機與真機gate尚待當次證據。規格不代替已測結果，選A是owner決定，不證明兒童接受或發行準備完成。

## 2026-10-11 實作批次授權

Owner授權全部十片做完再Wi-Fi安裝，並明確選A雙軌為預設、保留B比較入口。App source可依各片界線順序實作並在本機測試；UI-JOURNEY先接入A作本機/手機候選，真機與兒童gate仍未接受，安裝只交測不等於public接受。QA在每片執行，批次完整回歸後才交手機。PLAY/UI/SOUND/CONTROL共用store所需整合在此批次內，不增加譜、星星規則或資料schema。所有發布界線維持。

## 本批目前狀態與試玩（2026-10-11）

2026-10-11：八個功能slice已實作並通過本機候選檢查；QA本機部分通過，真機/兒童/完整Accessibility仍未接受；已原地安裝並成功開啟。A雙軌為正式旅程預設，B跑酷在DEBUG練習設定的「操作比較」保留，使用原2/3關同譜、同聲音與判分且不保存試玩成績。版本0.1.0（14），驗證來源5580a14；簽署包來源96ad73a，所有product/native-test inputs SHA256相同，最後變動僅UITest。此批沒有Apple上傳/PR/merge，TestFlight仍為GAME23舊13。

驗證：Core59、原生App126；10個不同UI流程，以9個未改動case＋最終SE觸控重跑組合。通過執行15次＝完整SE10次＋iPad一般/最大字級2次＋Dark一般/最大字級2次＋最終SE觸控1次，包含重複；不稱15個不同case。Debug/Release與簽署iphoneos建置皆在本機Mac。 [完整索引](RHYTHM-PLAY-BATCH-verification.json)。初次原生2個failure、UI查詢/捲動/選單transition、iPad原tab與快速batch失敗皆保留；不稱每次嘗試都全綠。

| 範圍 | 狀態 |
|---|---|
| PLAY/UI/SOUND/CONTROL八個功能片 | source實作及本機候選PASS，產品接受pending |
| QA-PLAY-01 | 本機PASS；真機timing/FPS、兒童、完整VO/Reduce Motion未跑 |
| DELIVERY-PLAY-01 | 已原地安裝並成功開啟 |

手機試玩先從首頁「開始冒險」進入原有推薦關；音符到黃色判定線時敲固定鼓墊，左L、右R。敲擊都有鼓聲，但目前只判時機，L/R不辨識身體手別也不新增按錯側扣分。HUD可暫停，續玩先聽四拍；重開清掉當次嘗試，退出回旅程，已保存成績保留。

B比較入口：練習→右上設定→「操作比較 · 不影響進度」，同一關分別選雙軌節奏/節奏跑酷。先用第二關四分拍，再比較第三關八分拍；準備／結果停留另計，两段播放約38.82秒。比較不改正式鎖定或成績；不要將此DEBUG入口當成已發布TestFlight內容。

待取得手機原始影音/觸控/長幀資料及試玩觀察再接受；安裝不把QA標DONE。KidsCharacterKit仍延後，沒有新增角色、關卡或經濟系統。
