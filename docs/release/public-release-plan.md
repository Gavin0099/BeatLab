# 拍拍冒險公開版本交付

Owner 2026-10-05 指示繼續做到 public。目的地問題已提出，仍待 App Store／TestFlight 公開測試／GitHub Release 的選擇；目前繼續完成共同的 UI、遊玩回饋與 QA。

GitHub 倉庫已確認 PUBLIC，default branch 為 `codex/bl-001-app-foundation`。這只代表程式碼可見。已分發的 TestFlight 0.1.0（10）為本人群組試玩；這輪新 UI 未上傳。

## 共同交付條件

三頁同品牌；首次使用者 10 秒內找到開始；目標年齡第一關理解跟拍；真機節拍／判分無 regression。依 QA-01 的 gate，native UI／fixture 可通過，但不可填成真人／child／物理 timing PASS。現階段為產品化 alpha，功能完整，產品級 timing validation 尚未完成。

G1 外部聲音 onset／音畫同步、G2 輸入對齊及三位目標年齡使用者、G4 最低與目前支援 OS 真機矩陣，需按 docs/verification.md 記錄。iPhone 於本輪 devicectl 檢查為 unavailable；沒有安裝或測出硬體精度。保持 learner data，不重設本人 TestFlight 進度。

## 各目的地的最後步驟

| 目的地 | 可準備的內容 | 必須核對的實際交付結果 |
|---|---|---|
| GitHub Release | 通過來源回歸的提交、版本說明、未完成 gates | remote SHA、release URL；不可把 simulator artifact 稱作可安裝 iOS 正式包 |
| TestFlight 公開測試 | 非 Internal Only 新 build、beta 說明與 review metadata | external group、Beta App Review 狀態、可用 public invitation link |
| App Store 正式版 | 合格 Release archive、商店文案／截圖、支援／隱私頁、age rating、review notes | metadata 完整、App Review 提交／審核狀態、可公開下載 URL；送審不等於已上架 |

Apple 官方指出外部測試需要 external group、build 及審核，再以 public invitation link 邀請：[Invite external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers)。本人群組可測不能代替這個結果。

正式送審需支援及隱私頁、完整審查資訊：[App Review](https://developer.apple.com/app-store/review/)。年齡分級需依實際內容回答問卷：[Submitting](https://developer.apple.com/app-store/submitting/)。目前沒有對 pricing／商店年齡分級／Kids category 代填或新公開送審的完成宣稱。

TF-03 只交付最後合格 candidate，不在封存時加關卡／Skin／角色／模式。UI-BRAND-01、MET-02、GAME-08、GAME-09 的 owner 視覺／玩法接受仍需明確記錄。GAME-09A 已補入判定後的短音效，9 項 focused audio／integration 與 36 App＋2 UIKit 回歸通過；需真機檢查它不遮蔽 cue、touch response／音畫／frame pacing 無 regression，不能把 offline PCM 或 Simulator graph 當作物理 timing gate。

已推送的 UI 工程 checkpoint 位於 `product-alpha/ui-checkpoint`，沒有 PR／merge。新版 App 尚未安裝或分發；手機仍 unavailable，公開目的地仍待 owner 回答。不要以 GitHub source public 代替對 App 發行的決定。
