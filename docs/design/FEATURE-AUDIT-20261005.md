# 拍拍冒險：目前功能與下一輪 slice

2026-10-05，基準為已分發的 TestFlight 0.1.0（10）。本次核對當前 61 個 production inputs，和 TF-02 封存的 hashes 一致；本輪只分析與保存進度，沒有改 App 畫面或節奏規則。

Owner 回饋：首頁風格已接受；節拍器與練習頁仍不符合。收到的三張手機截圖依序為首頁、已捲到聲音設定區的節拍器、練習旅程入口。截圖沒有版本號，因此 phone 安裝的精確 build 不從圖片推斷；也未提供本次 playing／result 畫面，不能據此判斷所有玩法狀態的排版。

## 功能盤點

| 面向 | 現有功能與來源 | 實作／證據邊界 |
|---|---|---|
| 首頁 | HomeView：今日／繼續推薦、直接進準備、10 關足跡、自由節拍器；icon 同造型衍生恐龍、暖白／暖黃／深綠 | owner 手機回饋認可畫風；HOME-01 最終 7 個 native cases，TF-02 Release 與 internal beta 已分發；不代表全部頁面或兒童體驗接受 |
| 基本節拍器 | MetronomeView／ConfigurationStore：30–240 BPM、slider、±1／±5、Tap Tempo、tempo undo/redo；2/4／3/4／4/4／6/8、合法細分 | MET-01 原生 focused controls 和保存檢查已有證據；BPM／細分下一拍、拍號／逐拍重音下一小節，engine 決定邊界 |
| 聲音與提示 | 每大拍重音→一般→靜音、電子／木魚／機械合成音色；節拍聲／預渲染數拍語音／兩種；音量、擺針、畫面 pulse、best-effort 震動 | timbre 與 count content 是兩個獨立設定。音量只調 gain，volume 0／靜音不重設 transport；提示不作物理精度證明 |
| 進階節拍器 | 入門／標準；標準 Gap：出聲 4 小節後靜音 1／2；Ladder 每 2／4／8 小節加 5 BPM，最多 240，手動改速退出 | core／C failure/boundary fixtures 已覆蓋；真機組合、回拍與長時間體驗仍待 gates |
| 課程旅程 | PracticeView、lessons.json：三篇章 2／4／4 關、共十關；四分、左右手、八分、休止、十六分、反拍與混合；全部 4 小節，基礎 60–75 BPM | 真實星星與順序解鎖；準備顯示目標／速度／節奏；標準可增加挑戰 BPM。手別文字沒有偵測左右手 |
| 夥伴與場景 | 恐龍預設，可換貓咪／機器人；起拍小島／回聲森林／星光舞台與篇章徽章 | 舊 imagesets 來自 owner 指定的字樹花園固定 commit；靜態 PNG，非完整跑步 sprite。選角是當次 View state，未持久化 |
| 原生跑酷 | GAME-07：音訊 elapsed 決定接近石頭；已判定的 matched hit 清除障礙並跳；extra 不清除、休止無石頭、終點和完整結果 | 這是既有跟拍課程的 runner 呈現。沒有新生命／道具經濟／碰撞判分，也沒有完整配樂或跑步動畫；不能把 GAME-04／05 browser 的救援／生命算入 App |
| 判分與結果 | PracticeStore／TimingSession：early／perfect／late、miss／extra、命中／perfect 比例、星星、最佳成績／BPM；retry、下一關、最後關、cancel 不計分 | 當前課程基本通過條件 hit ≥85%、perfect ≥55%、extra ≤10%；不調門檻來配合動畫。保存成功才更新解鎖；保存失敗可重試／明確放棄 |
| 標準詳情／對齊 | 標準模式跟拍對齊、route／sample-rate 有效性、JSON Share、uncalibrated／user alignment 標示；入門隱藏 ms | 對齊是人的估計，非獨立硬體延遲量測；Bluetooth 不作已校正 precision 宣稱。數據留本機，使用者 Share 才匯出 |
| 保存／安全停止 | 配置 v1 可讀、編輯才寫 v2；損壞／future schema 防護；本機課程進度；背景／中斷／route change 安全停、離開進行中練習 cancel | 無帳號／雲端；現有內部 beta bundle com.gavin0099.beatlab。早期 com.beatlab.app 資料不自動遷移；不能把不同 bundle 安裝稱為已遷移 |

目前不包含調音器、歌曲清單、麥克風真鼓辨識、MIDI、排行榜、雲端或 AI Coach。最初參考截圖有調音器／曲目分頁，並不代表這些已加入 BeatLab。

## 風格落差的實際原因

1. `BeatLabStyle.swift` 額外定義 HomeBrand，原本 BLCard／BLPrimaryButtonStyle／BLSecondaryButtonStyle／BLPill 等仍讀舊紫色 AccentColor／AccentSoft。`RootView.swift` 只有選首頁時改為 HomeBrand.forest，另外两個分頁仍紫色。
2. `PracticeView.swift` 的 welcome／chapter／lesson／results 大量使用舊 accentSoft；GameCompanion 引用 AdventureDinosaur／Celebration，首頁引用 HomeDinosaur，是兩套造型與材質。
3. 頁面資訊角色不同：首頁提供下一步；節拍器提供練鼓控制；練習提供旅程和遊玩。統一品牌不等於把三頁都做成同一張大恐龍卡片。節拍器需要讀拍，遊玩需要讀障礙與按鍵。
4. 截圖中的節拍器已捲到設定，不據此斷定沒有 BPM。聲音細節占比較大、重複摘要與音色／數拍的命名層級可整理；原操作需要保留可達性。
5. 練習入口 welcome 占很多高度，且 BEATLAB 舊標籤／舊恐龍和首頁不同；玩家的下一關在下方。這是結構與素材的一致性問題。遊玩及結果雖已有版面修復 evidence，這次還要一起檢查與 owner 新首頁偏好是否相符。

## 六個後續 slice

| 順序 | 契約 | 目的／完成範圍 | 依賴／風險 |
|---|---|---|---|
| 1 | [UI-BRAND-01](../slices/UI-BRAND-01.md) | 跨頁共用色彩、按鍵、狀態、tab／sheet tint 與角色造型指南；保護已接受首頁 | HOME-01；L1 |
| 2 | [MET-02](../slices/MET-02.md) | 速度／拍點／播放優先；聲音／提示整理、重音和目前拍獨立表達；保留全部控制 | UI-BRAND-01／MET-01；L1 |
| 3 | [GAME-08](../slices/GAME-08.md) | 同造型夥伴、旅程／關卡／準備／設定；下一關容易看到；保留三夥伴與真實解鎖 | UI-BRAND-01；L1 |
| 4 | [GAME-09](../slices/GAME-09.md) | 統一 runner／節奏／跳／停止／成功失敗與保存復原；維持單一高度感知版面 | GAME-08／GAME-07；L1，改時計／評分須另外升 L2 |
| 5 | [QA-01](../slices/QA-01.md) | 同一來源三頁與十關、light/dark、大字／短螢幕、VoiceOver／Reduce Motion；整理真機 gates 缺口 | 以上四項；UI L1、物理 timing L2 |
| 6 | [TF-03](../slices/TF-03.md) | 接受候選後封存、本人群組 TestFlight、實際更新確認 | 新版接受與交付授權；L1 |

以上皆 PLANNED，這輪不宣稱已實作。建議先共用品牌→節拍器→旅程準備→遊玩結果，因為先替每頁各做美術容易再次出現不同畫風。維持一小段能操作的課程循環來檢查樂趣；若 owner 不接受玩法，另開機制 slice，而非在美術 slice 偷加生命／評分／音樂時計。

## 目前可以信任的進度與缺口

- TF-02：0.1.0（10）上傳／Apple 處理／本人群組／notes 已確認；新素材／原 icon／privacy／distribution signing 已核對。
- HOME-01：7 項最終 native UI checks 通過；此輪 owner 接受首頁風格。GAME-07 有一般、短螢幕、最大文字深色與 Reduce Motion focused 證據；不是三頁／十關全矩陣接受。
- MET-01 有原生 App／UI focused evidence、offline 468 組 sample 長測。不能把 offline 精度換成喇叭／震動／input 的物理 precision。
- 此 checkpoint 新跑 core／C boundary／capture analyzer，精確結果見 [PROGRESS-01 evidence](../slices/PROGRESS-01-verification.json)。原生 compile／archive 的歷史 receipts 可核對，但本輪沒有重跑整個 App／UI suite。
- BL-002A／G1-G4、最低 OS／完整 VoiceOver、兒童理解與遊戲吸引力仍未接受。TestFlight 可下載與 owner 接受首頁，是兩個已觀察到的結果；不是正式上架 ready。

現有 release-checklist／docs/verification 保留為正式驗收入口；push 的意義是保存目前可試玩的來源與後續計畫。
