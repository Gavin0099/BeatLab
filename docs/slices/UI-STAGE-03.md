# UI-STAGE-03 — 第三關恐龍鼓手可玩垂直切片

## Analyze / Define

Owner 2026-10-11再次指出靜態提案仍像拼接畫面，要求先以第三關20–30秒
片段驗證演奏手感，並比較恐龍擊鼓與原跑酷。依此先做DEBUG可玩候選，
不立即替換正式十關。風險保守L2：新呈現模式接入既有音訊/輸入/結果流程，
不修改其時鐘或判分權威。

來源基準cd7872b，已安裝14的視覺接受仍REJECTED。沿用第三關eighth：
60BPM、四拍預備4秒、四小節16秒、32個原target，加匹配收尾約20.18秒。
原第三關32個target全為R，0.5秒間隔、相對epoch的4.0–19.5秒；不能為填左軌
假造L/R交替。舞台提示「右手 · 1 & 2 &」，兩軌/兩墊保留操作一致性。
不新編譜、不縮放時間、不擴其他關卡或導入KidsCharacterKit。

Allowed：BeatLab/App/PracticeComparison.swift、PracticeStore.swift
（僅DEBUG候選合法關卡guard）；BeatLab/Views/PracticeComparisonView.swift、
PracticeView.swift（DEBUG入口/原結果重試）、DrummerRhythmScene.swift、
DrummerStageView.swift；BeatLab.xcodeproj/project.pbxproj；
BeatLabTests/PracticeStoreTests.swift、BeatLabUITests/PracticeUITests.swift；
PLAN.md、本片/verification、canonical memory、ignored TestResults/UI-STAGE-03。
Forbidden：Core/DSP/audio/TouchPad、其他正式畫面、catalog/schema/star/unlock、
匹配窗口/校準/target、原素材、已留存證據、owner手機資料、Apple upload/PR/merge。

## Playable contract

- 新模式drummer只允許DEBUG第三關比較，真音訊、UIKit觸控與TimingSession
  原樣；用相同譜可比較既有falling/runner。試玩結果不保存或解鎖。
- 音符是兩條清楚的主軌，兩拍預告；視覺到固定鼓面時敲擊，原late窗口
  仍可敲，過期才隱藏。L/R是手別指引，不能假裝偵測實際手別。
- 恐龍縮小坐於上方舞台及鼓組後；鼓棒連續下擊/回彈只由真實matched
  引發。Extra只按墊/鼓聲與不同回饋，不增加舞台進度。Miss不中斷音樂。
- 鼓墊為實際樂器表面而非兩張大文字卡，保留至少44pt原生觸控區與可達暫停/退出。
- 同一SpriteKit場景讀既有presentationElapsed，畫面刷新不產生判分/聲音。
  角色、鼓棒、命中波紋使用同一讀取時間，pause凍結；Reduce Motion靜態高亮。
- 目標是奏完這段既有節奏、讓舞台隨有效敲擊亮起；不造新貨幣/生命/成績。
  結束使用原真實summary/stars與重試，零輸入不能變成功。

## Verify plan / failure paths

1. 獨立原生fixture：兩拍進場、fixed strike center、early/late/miss/extra、
   休止、校準、無效elapsed、sceneresize、matched與extra鼓棒差異、pause凍結。
2. Store實際音訊候選：只第三關/來源譜與20.18秒/32targets、成功與零輸入
   結果/取消不寫進度，拒絕其他關、paused/resume/restart沿原流程。
3. 本機App測試＋focused UI：實際觸控與可觀察命中、零輸入結果、重試/退出
   /暫停、左右位置、SE窄/最大字/Light/Dark、Reduce Motion的實際呈現檢圖。
4. 來源/hash綁定、git diff --check；所有build/test本機Mac，不用GitHub Mac。
   原始失敗保留，不能把測試注入target time當真機手感證據。

Rollback：移除DEBUG第三關drummer入口/模式與兩個新View/Scene並回退登錄；
保留原falling/runner和已保存資料。候選不自動安裝或上傳。
Status：SOURCE_LOCAL_CANDIDATE；本機工程完成，本片仍等待owner玩法/視覺、
真機timing/FPS及兒童接受，不能標成產品DONE或release ready。

## 本機驗證與交付邊界（2026-10-11）

- source5 Debug simulator build PASS；118來源輸入綁定。Core/DSP/audio15檔及
  UIKit TapPad與cd7872b byte-identical。只新增DEBUG第三關候選及呈現元件。
- 原生focused RhythmPrototypeTests13/13 PASS（source4），包括新場景geometry、
  有效命中/extra回彈、pause凍結、零輸入/成功/取消不保存、既有校準/休止/
  spam/route/media-reset failure cases。source4→5僅HUD/View兩檔變更；
  scene/store/test輸入相同，組件證據明確綁定，沒有聲稱full新host App suite。
- source5 focused UI3/3 PASS：真實獨立觸控可觀察命中、pause/restart、
  zero-input0stars/retry/exit不解鎖、大字左右位置/可觸及、原falling回歸。
  Dark最大字1/1為同一流程重跑，不增加unique case數。
- 逐張看過Light/Dark原生場景、真正UI命中/零分結果/最大字截圖；大字
  截斷BPM/提示已修正。Reduce Motion為原生fixture檢查，未跑OS設定或VoiceOver。
- 保留初次wrong-filter執行0項及UI初跑2pass/1fail；UI初跑暫停請求已超過
  真實20.18秒結束，修正測試順序後通過；未放寬判分/拉長譜以遷就測試。
  初次export在bundle finalize前失敗，之後原bundle正常匯出，非損毀。
- 最新實際UI截圖與raw xcresult/command/log/hash見
  [canonical evidence](UI-STAGE-03-verification.json)。它們是工程證據，
  不等同於高FPS、真機音畫同步、儿童理解、好玩或正式上架驗收。
- 入口：練習→設定→「恐龍鼓手·20秒試玩」；同頁保留第三關falling/runner
  比較。第三關仍為原R八分譜，非雙手交替；比較結果不保存/解鎖。
- 未安裝本輪候選、未上傳TestFlight/public、未重設手機；已安裝14仍為被
  owner拒絕的舊畫面。下一步是這段原生試玩與同譜runner的真機比較，
  先檢查敲擊感/音畫同步與重玩意願，再決定是否擴至正式十關。
