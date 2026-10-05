# UI-BRAND-01 — 全 App 的品牌基礎

狀態：IN_PROGRESS；owner 要求從本片開始，QA 嵌入每片。L1，依賴 HOME-01 已接受的首頁／icon 與 TF-02 build 10。

Owner 修訂：只建立語意色彩、Dynamic Type 字級、間距、圓角、button／card 的共用設計基礎。完成後新畫面不用自行決定這些規格；不順便改三頁結構。角色指南以已接受首頁恐龍為基準，圖片替換留 GAME-08。

目的：暖白底、暖黃冒險區、深綠主要操作、清楚的文字與狀態色跨三分頁／sheet 一致。首頁恐龍是主角色參考；節拍器保持樂器控制的清楚層級。定義角色輪廓／陰影／比例指南，先比較首頁、節拍器、練習入口三張 composition；不以全頁換色宣稱完成全部改版。

Allowed files：`BeatLab/Design/BeatLabStyle.swift`、`BeatLab/Views/RootView.swift`；Assets.xcassets 中 AccentColor／AccentSoft／Canvas／Surface／Ink／MutedInk／OnAccent／Separator／Success／SuccessSoft／Reward／RewardSoft 各 colorset 的 Contents.json；`BeatLabUITests/FoundationUITests.swift`；`docs/design/branding/app-style-guide.md`；本 slice 的 evidence／PLAN；README、FEATURE-AUDIT 與 MET-02／GAME-08／GAME-09／QA-01／TF-03 的 gate 文件修訂；ignored TestResults/UI-BRAND-01 的 snapshots／checks／screenshots。現有 Home* colorsets 與 HomeDinosaur 保留為基準。
Forbidden：HomeView 主版型、icon、bundle/build、ConfigurationStore／PracticeStore／Audio／Sources、課程／score／保存；刪除夥伴功能；新 raster art／TestFlight。共用 tokens 影響多頁，必須驗證三分頁與 sheets。

行為：只調整品牌 tokens、共用元件和全域 tint；原本 disabled、selected、warning、success 必須以文字／形狀區分。深色使用深綠灰底、暖亮文字，暖黃限制在需要注意的區域。
Failure paths：暗色對比不足、selected/disabled 無法辨識、全域 tint 遺留紫色、首頁回歸。Checks：light/dark 三頁與 sheet 截圖；最大 Dynamic Type；文字／實際背景 pair 對比；至少 44pt hit area；首頁原導航／重啟保存流程不變。先 native build 再操作，不把色票對比當成整個 App accessibility 驗收。
Rollback：還原本 slice 的 tokens／tint snapshots，保留 build 10 首頁、資料與舊素材。完成代表品牌基礎與三頁原生比對通過，後續頁面結構仍由 MET-02／GAME-08／09 驗證。

Foundation gate 當片執行：light、dark、375×667、最大字級的三頁與 settings／companion sheets；共用元件與觸控可達性；首頁推薦／設定跨 relaunch。源碼 hash 只證明未改時計邏輯，不可代替真機 timing regression。

Observed gate defect：首次 wide largest 新增 case 量到 practiceSettings Button width 37.33pt。允許增加共用 BLToolbarIcon，並只改 `BeatLab/Views/PracticeView.swift` 的 idle toolbar settings Button label：將 44pt frame 放進可互動 label 與 contentShape。不改其他 PracticeView 結構／state／phase／clock。其 action／identifier 保留；以實際 frame 與 settings sheet 操作重驗，失敗 attempt 保存。

Content freeze：TF-03 前不新增關卡、Skin、角色或模式。Gate：三頁像同一 App、首次使用者 10 秒內知道開始、孩子第一關懂跟拍、真機 timing／判分無 regression。缺一保留 blocker，不以更多內容掩蓋。
