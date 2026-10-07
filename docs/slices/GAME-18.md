# GAME-18 — 跑跳、落地與失誤的遊戲回饋

Status PLANNED，2026-10-07。依賴GAME-17及QA-02A。Risk L1：只讀事件呈現；若改presentation host epoch、輸入或音訊边界即升L2重立契約。

目的／契約：敲擊matched即開始動作、到拍點看到跨越、落地接回跑步；Perfect有短物品亮光／落地效果，early／late保留真實grade。extra有即時輕反應但不覆蓋正在發生的有效跳躍、不清障礙；miss有可辨識的輕絆／接回動作且仍是miss，下一拍可接上。持續場景不重建、不突然切回靜止圖；配樂／hit聲沿用，這片不新增音訊。

Allowed exact files：`BeatLab/Views/EggMissionView.swift`、GAME-17建立後的 `BeatLab/Views/RunnerPresentation.swift`、`BeatLabTests/PracticeStoreTests.swift`（呈現fixture測試）、`BeatLabUITests/PracticeUITests.swift`；本slice／`docs/slices/GAME-18-verification.json`、PLAN、canonical evidence／memory、ignored `TestResults/GAME-18/**`。
Forbidden：PracticeStore transport／input、`BeatLab/Audio/**`、`Sources/**`、課程／score／save／進度／生命制、project/buildmetadata、資源換版、KidsCharacterKit、新皮膚／角色。不能以增加跑速或跳過幀隱藏不順。

Checks／QA-02B：run→matched jump→landing→run、extra during jump、miss後下一拍matched、連續miss、取消／finished／background復原。用獨立位置／狀態fixture與實際連續輸入／零輸入回放核對尺寸／腳底／眼位／pose連續性；至少擷取跑／跳頂點／落地／失誤片段。Reduce Motion改靜態提示、不按每幀VoiceOver播報。真機record frame interval、render work與hitch；數值目標依裝置refresh及QA-02預先定義，不把錄影片率當實際渲染或承諾固定60FPS。
Failure：現有8跑／6跳動作圖若仍可見抽換，記為素材限制，不能稱已解決；需要新rig／動作素材另列前置設計，KidsCharacterKit仍deferred，未取得新素材範圍不先生成或導入。真機工具失敗標NOT RUN，不能只用simulator宣布流暢。
Rollback：回復本片動作曲線／event呈現至GAME-17，保留判定資料與失敗證據；不得改音樂、match窗口或降難度取得通過。
