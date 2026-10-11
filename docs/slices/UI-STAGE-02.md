# UI-STAGE-02 — 雙軌舞台視覺檢討與提案

## 本輪界線

2026-10-11 owner提供已安裝0.1.0(14)第三關截圖，回報「感覺很粗糙」。
狀態：OWNER_VISUAL_REJECTED；這是視覺設計結果，並非安裝或本機測試失敗。
雙軌預設、保留跑酷比較的操作方向仍沿用。尚未接受任何替代畫面。

本輪L0：只分析截圖、呈現兩版可點擊視覺提案及保存結果。
Allowed：本文件、PLAN.md、此片verification.json；task-owned視覺fragment與
browser檢查、ignored TestResults/UI-STAGE-02的提案/檢圖留存。Forbidden：App/Core/tests/assets、判分/音訊/觸控權威、
既有測試與安裝receipt、手機資料、Apple上傳、PR/merge。
Dependencies：RHYTHM-PLAY候選及owner實際截圖。
Failure paths：角色/軌道重疊、音符遮擋判定線、320px溢出、深色對比失去、
回饋示意誤被描述為真實Perfect、將可點擊提案稱為節奏遊戲驗收。
Checks：320/390px Light/Dark、兩版圖片載入/敲擊回饋/暫停示意返回、
無JS錯誤/橫向溢出、人工檢圖、fragment SHA256、git diff --check。
Rollback：只回退本片提案與PLAN新增項；保留已安裝14與歷史證據。

## 截圖診斷

- 小幅恐龍場景與大幅淡色音符區分開，角色更像附加插圖。
- R/L矩形音符、網格與文字標籤像設定控制項，缺少一致的音樂視覺語言。
- 判定線、鼓墊及回饋文字分散；敲擊的空間因果關係不夠清楚。
- 標題、原始統計、場景、音符、長句回饋與大按鈕都各占一區，
  既有暖黃/森林綠一致不等於整體遊戲完成度。

以上為此截圖的設計判斷，不是新的市售遊戲實测或幀率/節拍診斷。
精準連擊0保留其真實含義；不為鼓勵感改成假combo或降低匹配窗口。

## 可比較方向

森林舞台：同一背景串接恐龍、兩軌預告、判定線與具鼓面質感的觸控區。
鼓手舞台：縮減環境插畫、較長的清楚軌道，集中於演奏與固定敲擊位置。
沿用既有RunnerIsland與HomeDinosaur；只為瀏覽提案縮圖/嵌入，不改原素材。
兩版使用相同示意資料；L圓形/R菱形加字母，顏色不是唯一辨識方式。

這是靜態譜面＋有限無聲敲擊回饋，不判時機、不遞增成績、不保存進度。
不能證明完整核心loop、音畫同步、好玩或兒童理解。
下一輪原生版需先確定採用配置及完整ready/count-in/live/early/late/miss/
rest/paused/result状态，再定義L1實作檔案與QA，保持原音訊/判分權威。
若碰時間邊界或匹配/保存則升L2；本輪尚未實作或安裝替代App。

## 驗證

本輪browser evidence見UI-STAGE-02-verification.json；不重跑未變動App測試。
RHYTHM-PLAY本機工程通過與0.1.0(14)Wi-Fi安裝/開啟證據維持原狀，
視覺接受明確未通過。G1–G4/真機timing/FPS/兒童/完整Accessibility保持pending。
