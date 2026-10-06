# 貓咪雲端／機器人科技平台

Owner direction: 貓咪和機器人也做連續跑跳，而且風格要不同。

第一關 60 BPM 三個角色共用原有節拍、目標、判分、重試與保存。貓咪是橘色虎斑、暖桃色雲端小屋，尾巴跟隨步伐、柔軟起跳與落地；機器人保留銀色身體、紅天線、藍手腳與蠟筆材質，藍色科技平台、關節步伐與較穩的落地。其他關卡與速度保留既有 runner。

## 素材與來源

使用內建 imagegen，原角色圖作為 identity/style reference；沒有改寫原角色素材或把恐龍改色。完整提示與參考路徑見 [prompts.json](prompts.json)，原始 PNG 的尺寸、alpha、hash、逐格範圍見 [art-source.json](art-source.json)。

- [貓咪動作圖集](../../../BeatLab/Resources/Assets.xcassets/CatMotionAtlas.imageset/artwork.png)
- [機器人動作圖集](../../../BeatLab/Resources/Assets.xcassets/RobotMotionAtlas.imageset/artwork.png)
- [雲端場景](../../../BeatLab/Resources/Assets.xcassets/RunnerCloud.imageset/artwork.png)
- [科技平台場景](../../../BeatLab/Resources/Assets.xcassets/RunnerCircuit.imageset/artwork.png)

24 格：0–7 跑步、8–13 跳躍、14 準備、15 落地、16 安全接住、17 完成、18 運送物、19 目的地、20 障礙、21–23 裝飾。貓咪生成圖的行間距不均，依透明空隙劃分行，再使用各格實際 alpha 範圍；機器人是等距 4×6。讀取／裁切只在載入時快取，原始 PNG 不重編碼。SpriteKit 以單一不透明角色節點、固定素材比例與腳底基準播放，保留既有軌跡與時間權威；不同角色只有美術、文字與動作性格不同。

## 可玩草稿

在 repository 根目錄提供 HTTP，再開啟 [play.html](play.html)。選貓咪或機器人，聽四拍預備，按跳躍配合 16 個拍點。無操作會失敗，多按不會前進；重試與停止使用真實流程。草稿的 AudioContext 僅供概念驗證，沒有移植到原生聲音或判分。

`verify.cjs` 以實際 pointer input 檢查兩個角色的成功、零輸入失敗、Extra、重試、取消、窄／寬尺寸與錯誤；測試不直接寫分數或完成狀態。原生檢查與限制見 [GAME-13](../../slices/GAME-13.md) 及其 verification JSON。模擬器不能證明真機 FPS、輸入延遲或兒童是否喜歡。

## 原生畫面

[貓咪實際跟拍](native/cat-actual-live-runner.png) · [機器人實際跟拍](native/robot-actual-live-runner.png) · [貓咪零輸入失敗](native/cat-actual-failure.png) · [機器人零輸入失敗](native/robot-actual-failure.png)。這些畫面來自實際原生測試，沒有在畫面上手動補分數。

## 驗收範圍

原生 App 49 項、Core 53 項、草稿 20 項檢查通過。素材／動作已實作，但小螢幕的大字操作測試尚未完成驗收：實際執行曾在未修改的音訊停止路徑遇到 Simulator CoreAudio RPC timeout 崩潰，同輪機器人點擊也未命中，原因未確定。失敗、修正與後續重測均保存在 [驗證紀錄](../../slices/GAME-13-verification.json)，不能用建置成功取代這些檢查。沒有更新 TestFlight、安裝手機或取得真機流暢度／兒童喜好驗收。
