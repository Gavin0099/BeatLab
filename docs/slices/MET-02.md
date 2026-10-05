# MET-02 — 節拍器的冒險品牌與控制層級

狀態：IN_PROGRESS；L1，依賴 UI-BRAND-01、MET-01 現有行為。目的：使用首頁的暖白／深綠／暖黃語言，同時讓 BPM、目前拍點、開始／停止成為練鼓時主角。

Allowed files：`BeatLab/Views/MetronomeView.swift`、`BeatLab/Views/BeatVisualizer.swift`、`BeatLab/Views/ConfigurationSummary.swift`、`BeatLabUITests/MetronomeUITests.swift`；`docs/design/branding/metronome-layout.md`；本 evidence／PLAN。
Forbidden：ConfigurationStore／PracticeStore／Audio／Sources／DSP；拍點生效邊界、時鐘、haptic dispatch、語音準備／fallback、保存 schema、歷史 grouping、Gap/Ladder 語意；把 mascot 動畫當拍點；新增調音器／歌曲清單。

操作契約：大 BPM、slider／±1／±5／Tap Tempo／undo/redo 保留。拍號／細分靠近拍點；可編輯的重音／一般／靜音是固定標記，播放到哪一拍是獨立高亮，停止時移除播放標記。音量保持容易到達；音色（電子／木魚／機械）與播放内容（節拍聲／數拍／兩種）命名分清楚，折疊進聲音與提示區但不失去任何功能。入門／標準與標準 Gap／升速仍可用。待生效、語音準備、停止、讀取／保存錯誤均可看見。

Failure paths：折疊後失去 picker／VoiceOver 操作、transport 遮擋、6/8 被畫成六個大拍、重音與目前拍混淆、volume 0 被當停止。Checks：一般與 SE 短螢幕、最大字級、亮暗 native screenshots；所有四拍號與其合法細分；逐拍三態、聲音雙選單、volume 0、提示、undo/redo、重啟設定、播放中 pending、標準 Gap/Ladder、語音準備／取消；原 engine/app fixtures 以源碼 hash 沿用或在受影響時重跑。更動音訊／input／時計邊界先另立 L2 slice，不混入 UI 修正。
Rollback：只回復上述 View／test，資料與 engine 不動。完成：native 控制回歸與 owner 視覺回饋記錄齊全；物理 timing 不因畫面通過。

Embedded QA-01A：當片執行小螢幕／最大字級／dark、BPM／拍號／細分／播放狀態辨識與單手操作，不等 Final。TF-03 前不增關卡／Skin／角色／模式。真機未完整驗證時維持「功能完整，產品級 timing validation 尚未完成」。

Implementation decision：保留全部原 Binding／action，節奏 DisclosureGroup 移至拍點卡，sound DisclosureGroup 只包音色／數拍／提示，volume 常駐；warm hero 用現有 HomeHero／heroInk。測試先展開聲音區再選音色。
