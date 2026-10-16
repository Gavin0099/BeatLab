# QA-REVALIDATE-01 — 鼓手候選的新本機驗證批次

2026-10-16 heartbeat允許接續可獨立完成的已授權工作。原TestResults仍缺失，
來源可用；從已提交的02dc2df凍結產品／測試輸入，重新建置與驗證，不等待
原備份。這是新批次，不能修復QA-RETENTION-02的原始證據留存失敗。

風險保守L2：驗證既有音訊／輸入／判分／保存整合；不修改它們。
Allowed：本契約／verification、PLAN、canonical memory、tracked
artifacts/evidence/revalidation/20261016/的指令／摘要／hash與本次實際測試截圖（非新美術）；ignored
artifacts/development/QA-REVALIDATE-01/的凍結來源／build／raw結果；另存本批
副本於 ~/Library/Application Support/BeatLabEvidence/QA-REVALIDATE-01-20261016。
Forbidden：產品／測試／素材／schema／治理pin、舊receipt、手機資料、
原TestResults、安裝／簽署發行／Apple upload／PR／merge、其他專案的simulator。

Checks／完成界線：
1. 凍結的每個來源檔與git02dc2df相同；只在本機Mac build/test，不用GitHub Mac。
2. Core全套、focused RhythmPrototypeTests13項、實際UI3流程（鼓手真實
   個別touch／pause／zero-result／retry／隔離進度、大字、原雙軌回歸）。
   Dark最大字重跑與原生減少動態fixture分開；不稱full App或fullAX通過。
3. 保留每次失敗／command／exit／raw xcresult，確認非0項與正確class filter。
   截圖實際檢視；preferred60FPS只是要求，不是實測。
4. 使用既有BeatLab專用SE，記錄原Shutdown與appearance，完成後復原；
   不碰原Booted的其他iPhone或其他專案資料。不需要打開owner手機。
5. 新source manifest、raw／simulator候選／log SHA-256及第二位置副本核對；
   不回填舊檔，不聲稱這是14版原始簽署安裝包。

Failure paths：build工具／testmanager／觸控測試失敗、0項假PASS、備份未完整、
資料與候選hash不一致、sim未復原；明列為未完成，不放寬產品判分以通過測試。
如需產品修正，另定slice，不在本片偷偷修改。
Rollback：無產品變更；只復原本批使用的sim狀態。保留失敗與新結果，不刪舊資料。
Status：NEW_LOCAL_CANDIDATE_PASSED；本片新本機驗證完成，產品接受仍pending。

## 實際驗證

- git02dc2df的116個tracked產品／測試／project輸入凍結，build後root／frozen
  全部SHA-256相同。未修改產品、測試、素材或評分。
- 本機Debug build PASS；新Core59/0、同一compiled host原生13＋實際UI3
  共16/0、Dark最大字同case重跑1/0。全部raw xcresult與commands保留；
  不稱full App或ten-level regression重新驗完。沒有0項test當PASS。
- 實際看過5張截圖：正命中、零輸入0星、大字Light/Dark、原生compact Dark。
  Reduce Motion是原生fixture；未跑OS設定或VoiceOver完整操作。
- 407個新批次檔在本機另一位置逐檔SHA-256相同，副本包括raw results、
  frozen source、simulator candidate與logs；排除可重建cache。清單與receipt
  另存tracked metadata。本次沒有建立原TestResults，也沒有回填舊bytes。
- 專用SE已回復原Shutdown／light；其他原Booted裝置未操作。沒有phone
  install／launch／reset或Apple upload；候選是simulator-only。
- [完整receipt](QA-REVALIDATE-01-verification.json)；[實際正命中截圖](../../artifacts/evidence/revalidation/20261016/screenshots/actual-touch.png)。
  下一步仍是新真機候選與owner比較，不把本機PASS當timing/FPS/好玩接受。
