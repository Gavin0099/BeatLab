# 第一關完整動作銜接 review — 2026-10-09

Owner 回報：跳躍與掉落比前版順，但兩次跳躍之間沒有動作。這次檢查
PHONE-08 所安裝 GAME-24 source；不是再改跳躍或掉落的物理曲線。

結論：主要可重現問題是動作循環缺段。跨島模式將等待固定成一張站姿，
沒有跟拍待機或起跳預備；有效第一拍早按又會被 count-in 畫格條件擋住。
增加飛行素材數量、提高 SKView 請求刷新率，都不會消除這兩段邏輯。
三角色共用這些邏輯；表情修正版只處理漏拍，沒有處理正常跳躍間的等待。

## Review 範圍與證據邊界

本次為唯讀程式／素材／既有 native evidence review 與本機 Swift 取樣。
檢查 EggMissionView、PracticeView、PracticeStore、TapPad、TimingPractice、
第一關規格與 PracticeStoreTests；三套 32-cell dense 原素材已實際檢圖。
允許此報告、PLAN、canonical review evidence/memory 與 ignored 本機診斷。
不改 App、素材、判分、音訊、存檔、版本或第2–10關；不安裝或上傳。
風險：review 揭露 L1 呈現缺陷，後續修正若觸及 clock/result 邊界依 policy
列 L2。後續實作契約須另定，這份建議不是已實作或已接受的新 slice。

本機診斷直接擷取現行 Swift production struct/enum，使用真正 TimingSession
產生 matched hits，再抽樣 PlatformJourneyFrame／DenseAnimationFrame。
這不是 iPhone 畫面錄影、native presented FPS 或 input-to-display latency 量測。
原本 App76/Core53 是舊規格工程 evidence；這次没有重跑相同完整 suite。

## Findings（P1：先於第一關完整接受修正；P2：同一動作循環應納入修正）

| 優先 | 問題與可重現觸發 | 原因／影響 | 位置 |
| --- | --- | --- | --- |
| P1 / F1 | 第一拍 t=4 命中、下一拍 t=5 命中，t=4.64…5 固定站姿28；取樣87次只有同一 pose，step=1/camera=0 | `.48s` 飛行＋`.16s` 落地後 `stationary=true` 強制 ready。角色位置／縮放／旋轉同時回到常數；約`.36s`沒有角色動作。early→late 合法輸入3.82→5.18時空白可到`.72s`。不是只有第一跳，中間第2–4拍亦相同 | EggMissionView.swift:505–508、833–907 |
| P2 / F2 | 第一拍合法提早 t=3.82 命中；t=3.90/3.99 step 已移動但仍 pose28，到 t=4 突然切 pose16 | `elapsed >= 4` guard 在 active hit 分支前。count-in 顯示保護錯誤地壓過已判定成功的起跳姿勢，跳過前4個 flight poses | EggMissionView.swift:505–506；PracticeStore.swift:169–176 |
| P2 / F3 | t=4.70/4.80/4.90/4.98 全 pose28，下一個真實命中立即切 flight12 | 沒有「等待跟拍→蓄力→離地」的身體連接，landing27→ready28→flight12 是直接換圖。三套素材29–31目前不播放，且只是ready候選，不能把32張當作完整動作循環 | EggMissionView.swift:502–509、907；GAME-22 contract |
| P1 / F4 | 舊 native test 明確要求跨島 t=4.8 使用同一張28；live callback test只要求`.8s`內看過>8 textures | 測試保護了「不跑步」卻把「不能有任何待機動作」也固定住。單次flight/landing與miss samples沒有證明連續多跳的接點好看，既有76/0不能反駁owner觀察 | PracticeStoreTests.swift:988–989、998–1029 |
| P2 / F5 | 實際第一關14/16 Perfect仍可得2星；live step14/camera12.7，結果 renderer 改成step16/camera14.7 | 結果頁重建場景、改尺寸、切旧慶祝素材與終點位置，沒有保留最後位置再做抵達銜接。是另一個斷接來源；不是畫面中途掉幀的證據 | EggMissionView.swift:838–839、903；PracticeView.swift:707–709 |

F3 的視覺不自然程度與 F5 的結果頁體感仍需手機整段播放確認；分支／
未實作預備動作／世界位置替換是已確認程式事實。沒有把 art 接縫或 CPU
負載猜測寫成已量測的 iPhone 掉幀。

## 從進入到結束的檢查

| 接點／路徑 | 目前行為 | 判定 |
| --- | --- | --- |
| 準備、四拍 count-in | ready28；首次合法 early hit 的 flight 被 count-in guard壓住 | 準備可靜態；有效 hit 是 F2 |
| 起跳→飛行→落地 | 12 flight/.48s、4 landing/.16s；原進度與arc保持已接受版本 | 保留；位置曲線連續不等於pose接點完整 |
| 落地→等待→下次起跳 | ready28、縮放1、旋轉0，無跟拍身體／預備動作 | F1/F3，優先修正 |
| 漏拍→下墜→接住→回平台 | 已接受`.24+.08+.28s`回復，回程age≥.40用28但仍有carrier位移 | 保留已接受動作；回到平台後又進靜態等待，納入F1 |
| 多按／連續命中 | 既有extra不推進；有效命中主導step，不用動畫碰撞判分 | 邊界正確；新idle不能蓋過flight/recovery |
| 暫停、背景、Reduce Motion、取消重開 | configure/detach有pause，Reduce Motion靜態；既有native regression evidence | 保持；沒有新真機中斷驗證 |
| 完成→結果 | 全／部分通過皆直接設定終點與舊慶祝pose | F5，後於核心多跳接點 |

已保留的合理設計：live drawing由單一 SKScene.update 擁有；SwiftUI約33Hz
發布不另開繪圖循環；角色單一opaque sprite、textures/shaders cache，缺素材
有fallback；audio host elapsed只讀，不以動畫建立targets／判分／保存。
所以不建議先改 clock、移動整個音訊架構或提高數字到120fps。

## 建議下一個第一關修正範圍

優先建立「落地回彈→跟拍待機→預備起跳→已判定命中飛行」的完整循環，
以及「接回平台→同一待機循環」。腳的落點與已接受飛行／掉落曲線保留。
等待可用小幅重心、呼吸、尾巴／耳朵／機械關節；起跳預備跟真正 upcoming
note 做只讀顯示。預備不能自行離地、提前獎勵或替玩家命中；有效 early hit
必須能直接接進flight。恐龍、貓咪、機器人共用轉場語意但有各自動作個性。
不能直接把running loop放在站立平台上，也不能用29–31近似站姿輪播假裝完成。

驗收改為整段循環：三角色至少連續4跳、early→late與late→early、第一次early、
miss接回後early hit、extra、cancel/restart、pause/Reduce Motion；整段正常速度與
慢速檢查landing→idle→anticipation→flight，實際native pixels／單角色／腳點／
camera接點；再以同一候選iPhone錄影或profiling檢查frame pacing與touch response。
畫格數、callback次數及平均FPS都不能單独當作接點自然的驗收。

第2–10關仍待第一關完成後才排slice。TestFlight／手機安裝狀態不因本次review
改變；最後一次自動launch仍為PHONE08 device locked，owner的新體感回報可記錄
為已試玩，不補造自動launch成功receipt。

## 驗證

- 現行107來源仍與GAME24 tested/candidate manifest一致，App source未改。
- 本機 `swift TestResults/MOTION-REVIEW-20261009/motion-audit.swift`成功，使用
  production read-only抽樣＋real matcher及實際第一關threshold；未執行Xcode rebuild。
- F1取樣`.36s/87`、`.72s/173`次都pose28，較短合法相鄰命中可没有等待；這些
  是診斷抽樣密度，不是rendered FPS。
- F2早按取樣step已前進且pose28，t=4切到pose16；F5實際14命中得2星。
- 三份dense PNG檢圖；既有GAME22 native assets/poses、GAME23 recovery、GAME24
  expression evidence及App76/Core53範圍review。這次不宣稱新 native/frame profiler測試。
- Canonical review receipt與source/sample hashes見同名verification JSON。實作、
  真機FPS／touch latency／兒童吸引力與第一關完整接受均尚未完成。
