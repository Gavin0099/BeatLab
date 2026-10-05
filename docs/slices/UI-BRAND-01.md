# UI-BRAND-01 — 全 App 的品牌基礎

狀態：PLANNED；本輪只建立契約。L1，依賴 HOME-01 已接受的首頁／icon 與 TF-02 build 10。Owner 2026-10-05 認可首頁，節拍器與練習頁待改。

目的：暖白底、暖黃冒險區、深綠主要操作、清楚的文字與狀態色跨三分頁／sheet 一致。首頁恐龍是主角色參考；節拍器保持樂器控制的清楚層級。定義角色輪廓／陰影／比例指南，先比較首頁、節拍器、練習入口三張 composition；不以全頁換色宣稱完成全部改版。

Allowed files：`BeatLab/Design/BeatLabStyle.swift`、`BeatLab/Views/RootView.swift`；Assets.xcassets 中 AccentColor／AccentSoft／Canvas／Surface／Ink／MutedInk／OnAccent／Separator／Success／SuccessSoft／Reward／RewardSoft 各 colorset 的 Contents.json；`BeatLabUITests/FoundationUITests.swift`；`docs/design/branding/app-style-guide.md`；本 slice 的 evidence／PLAN。現有 Home* colorsets 與 HomeDinosaur 保留為基準。
Forbidden：HomeView 主版型、icon、bundle/build、ConfigurationStore／PracticeStore／Audio／Sources、課程／score／保存；刪除夥伴功能；新 raster art／TestFlight。共用 tokens 影響多頁，必須驗證三分頁與 sheets。

行為：只調整品牌 tokens、共用元件和全域 tint；原本 disabled、selected、warning、success 必須以文字／形狀區分。深色使用深綠灰底、暖亮文字，暖黃限制在需要注意的區域。
Failure paths：暗色對比不足、selected/disabled 無法辨識、全域 tint 遺留紫色、首頁回歸。Checks：light/dark 三頁與 sheet 截圖；最大 Dynamic Type；文字／實際背景 pair 對比；至少 44pt hit area；首頁原導航／重啟保存流程不變。先 native build 再操作，不把色票對比當成整個 App accessibility 驗收。
Rollback：還原本 slice 的 tokens／tint snapshots，保留 build 10 首頁、資料與舊素材。完成代表品牌基礎與三頁原生比對通過，後續頁面結構仍由 MET-02／GAME-08／09 驗證。
