# 恐龍連續動作比較 — GAME-12

Owner指出「跑步、跳躍像在換圖片」。這輪針對角色連續動作，保留送蛋回巢、原音訊/判分/input/store；不新增關卡或玩法。

[可玩比較](http://127.0.0.1:7811/docs/design/runner-motion/play.html)：勾選新動作幀，取消可比較GAME-11的兩姿勢/短淡化/sin跳躍。按出發，先聽四拍，按鼓聲跳過石頭。零輸入仍真實失敗，多打仍Extra，不寫入App進度。程式比較/自動clock-cued輸入不能證明兒童喜歡或真機精度。

原生版使用持續存在的SpriteKit節點；八幀跑步循環、六幀跳躍加準備/壓縮落地，共16幀，單一不透明角色層（移除相鄰幀混合，避免雙眼/雙腳重影）。以眼睛/腳底註冊位置，控制角色的整體晃動；實際跳躍位置沿既有輸入時間算出，零速度落地，小場景等比例縮整條軌跡。Reduce Motion靜態呈現，背景/暫停/結果不持續更新。渲染沒有接收觸控、沒有SKActions、沒有產生判分目標。

美術來源：[透明原始圖集](../../../BeatLab/Resources/Assets.xcassets/EggMotionAtlas.imageset/artwork.png)、[實際生成提示](art-prompt-used.txt)、[規格](art-prompt.txt)、[像素/alpha/幀註冊](art-source.json)。使用內建imagegen，新生成同角色動畫；既有圖集、icon與背景保留。PNG1254×1254，RGBA透明；沒有重新編碼或加工PNG，裁切與錨點在執行期完成。AI幀不是骨骼動畫；仍需owner確認八幀循環的觀感。

官方技術參考：[Apple節點繪製效能](https://developer.apple.com/documentation/spritekit/maximizing-node-drawing-performance)、[SKScene逐幀更新](https://developer.apple.com/documentation/spritekit/skscene/update(_:))、[顯示更新率設定](https://developer.apple.com/documentation/spritekit/skview/preferredframespersecond)。使用明確zPosition與ignoresSiblingOrder；preferredFramesPerSecond=60只是請求，不能宣稱手機達成60FPS。這輪没有量測商業遊戲或手機GPU/frame pacing。

實际驗證原始輸出位於忽略的TestResults/GAME-12，摘要與87份輸入hash保存於docs/slices/GAME-12-verification.json。實際SKView的callback與render方法work數據保存於驗證JSON。只表示模擬器callback cadence/方法CPU執行時間，不能當成實際顯示幀率、完整frame成本或input latency。

保留失敗：首建置floor節點名稱遮住全域floor函式（改rounded(.down)）；首原生執行SKScene在super.init提前didChangeSize，graph未建成時越界崩潰（新增初始化guard，兩個實際scene建置/lifecycle測試重跑）；中途並行兩個build共享build.db被鎖（最終建置順序完成）；首次手機build漏命令列原團隊值（原project未改）。首test action中斷導致xcresult無Info.plist，保留原crash log/目錄，不能報為可讀正式測試summary。最終source的並行wide49pass/1fail與narrow2pass/1fail保留；大字查詢跨過原20秒關卡，串行無build/錄影再測同一份程式與fixture，wide/narrow各1pass。結果按action分開報告，不能稱一個全綠UI suite。所有結果由實際xcresult reader讀取，失敗未刪除。

[可玩版準備](concept-ready.png) · [真實輸入通關](concept-success.png) · [原生實際場景](native-solid.png)。原生runtime.mp4是中間版畫面檢查錄影，發現crossfade重影後未安裝那份候選；最後版只保留單一角色層。錄影不作幀率量測。手機安裝/啟動結果以驗證JSON為準；硬體timing和owner體驗未接受，TestFlight/public readiness不能因此通過。
