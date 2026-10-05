# GAME-08 — 練習入口、關卡與準備畫面

狀態：PLANNED；L1，依賴 UI-BRAND-01 與現有十關／保存規則。目的：入口恐龍、旅程、關卡準備與首頁看起來是同一個冒險；讓孩子立即理解「下一關在哪、要怎麼玩」。

Allowed files：PracticeView.swift 中 journeyPanel／adventureWelcome／companionPicker／chapterButtons／journeyNode／adventureStickers／lessonPreview／practiceSettings／lessonBrowser 與 GameCompanion 的呈現；相同路徑為 `BeatLab/Views/PracticeView.swift`；`BeatLabUITests/PracticeUITests.swift` 的入口／準備／sheet cases；AdventureDinosaur／AdventureDinosaurCelebration／AdventureCat／AdventureCatCelebration／AdventureRobot imageset 的 artwork.png 與 Contents.json（需要時以同一已接受的造型指南製作原創替代）；`docs/design/branding/practice-entry.md`、`companion-art-sources.json`；本 evidence／PLAN。
Forbidden：playing／runner／result／calibration 操作邏輯、PracticeStore／Audio／Sources、課程 JSON／門檻／星星／解鎖／持久化；更改 icon 或已接受首頁；刪除既有貓咪／機器人選項；把選角改成保存 schema。

準備契約：以今日／繼續挑戰為主要入口，三篇章（2／4／4 關）與十關真實進度保留。精簡高大的重複 welcome 文案，使用同造型恐龍；顯示目前章節、下一關與完成星星。準備頁提供清楚關卡目標、BPM、4 小節、R/L／休止預覽與「先聽 4 拍→跟拍跳」說明。鎖定關卡不可啟動；手別只是提示，不偵測。替換圖片需記錄 prompt、來源、hash、原圖，並核對所有場景引用。

Failure paths：無課程／未知版本進度、鎖關被誤開、從首頁推薦跳到錯關、夥伴選單被 sheet 遮擋、最大字級卡片過高。Checks：首頁→正確準備頁、三章與 locked 說明、換三夥伴、返回旅程、入門／標準 settings、挑戰 BPM、cancel preparation；light/dark／375×667／最大文字；源碼／catalog／progress hash 保持不變。Owner 對角色與入口的接受獨立記錄。
Rollback：恢复本 slice View／art 引用與 assets snapshots，不重設課程資料。完成：入口／準備導航驗證與畫風比對通過；遊玩及結果的完整改版留 GAME-09。
