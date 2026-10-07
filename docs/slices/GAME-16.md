# GAME-16 — 第一關短試玩概念

Status IMPLEMENTED_CONCEPT_BROWSER60_PASS_OWNER_PENDING，2026-10-07。Owner「好，往下走」授權開始本片；先交可操作概念，接受後才進GAME-17。依賴：Rhythm Swing六片總覽、現有first-beat規格、GAME-15／TF-04交付基準。Risk L1：瀏覽器隔離互動概念；不是原生timing或新score authority。

目的／契約：用既有恐龍／島嶼風格驗證「送蛋回巢」，4拍數拍＋16拍約20秒，單一敲擊區與可見下一段路線。完整ready→count-in→playing→success/failure→retry/cancel。結果以實際輸入產生，零輸入必定失敗；不做自動成功展示。使用清楚標記的browser-only clock／判定，不接原生保存。

Allowed exact files：新建 `docs/design/rhythm-swing-concept/README.md`、`play.html`、`verify.cjs`、`reference-notes.md`；只讀引用現有資源，不改素材；本slice、`docs/slices/GAME-16-verification.json`、PLAN、canonical milestone evidence／memory、ignored `TestResults/GAME-16/**`。截圖新增位置限該concept目录下 `ready.png`、`matched.png`、`missed.png`、`failure.png`、`success.png`。
Forbidden：App/Core/DSP/音訊/測試/project/resource變更；修改過去concept或證據；新生命／貨幣／skin／音樂；KidsCharacterKit導入；官方素材複製；手機／TestFlight交付。

Checks／gate：真實DOM輸入走完整16目標，另驗零輸入、extra／duplicate、early／late、取消／重試；預期值依first-beat及既有grade規格，不能從concept函式反推。小螢幕、深色、大字、Reduce Motion檢查。owner首次10秒內能指出目標和輸入時機，完成一次後試再玩；接受／拒絕如實記錄，script PASS不代替趣味接受。
Failure：看不懂下一拍、只看到背景移動、success與miss反應無法分辨、cue／controls遮擋、概念被owner拒絕，均留在本片修正。缺資料標NOT RUN，不提高命中率造假。
Rollback：原生候選完全保留；只移除新concept入口或回復本片新增檔到本片前，保存原失敗證據。不得清 learner data。接受後才進GAME-17。

## 實作／驗證 2026-10-07

四格樂句、固定到拍腳印、原圖集連續動作、真實 matched/early/late/extra/miss、數拍／取消／實際成敗／重試完成。READY 載入圖集後才能開始，素材失敗明確阻擋空白遊戲；準備文案在場景外，不蓋角色。Final browser60 checks PASS；實際16次clock-cued DOM輸入16Perfect/0Extra，零輸入0/16失敗；12組ready及12組live窄屏／深色／放大字flow，Reduce Motion及鍵盤通過。實際截圖已檢視，重複巢穴原圖保留後修正。95原生inputs hash未變，沒有native build/device/TestFlight/public工作。詳GAME-16-verification.json。

Owner／兒童趣味與第一次10秒理解尚待實測，不把60PASS當接受；GAME-17仍PLANNED。
