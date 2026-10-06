# GAME-14：石頭間隔與到拍標記

Owner 指出的是石頭看起來間隔不均，不是角色 FPS。第一關既有規格為 60 BPM、四拍預備、16 次操作；石頭中心依原本音訊 host epoch 在第 4–19 秒通過固定位置，每秒一顆。

可重現的顯示缺陷：提早命中會立即移除尚未到拍的石頭。這能產生視覺空缺，但尚不能據此證明真機音訊或實際到達間隔有誤。

本版保留石頭到原定位置後才淡出，地面加固定標記。命中回饋仍立即顯示；星星在到拍後才出現。沒有更動音訊、輸入判分或既有節拍位置公式。

`play.html` 是獨立可操作比較稿；`build-concept.py` 重用原動作稿，`verify.cjs` 用真正的提早輸入和 rendered snapshot 比較舊／新畫面，再走無輸入失敗、重試、16 次 clock-cued 操作、Extra 與取消。瀏覽器時鐘和判分不導入 App。

Native 截圖來自實際 UI 測試；完整來源、失敗候選與驗證界線見 `../../slices/GAME-14-verification.json`。Simulator 和模型測試不代表真機音畫同步或 FPS 已驗收。KidsCharacterKit 仍依 owner 決定延後導入。
