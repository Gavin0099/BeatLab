# 跑酷畫面與回饋

本輪沿用首頁已接受的 HomeDinosaur，場景為原創 RunnerIsland。暖白背景、暖黃跳躍操作、深綠 HUD 與節奏格共用 App 的角色／配色；没有新增關卡、Skin、角色或模式。

## 操作循環

先聽四拍，觀察向腳下接近的 R/L 石頭，在節奏點按「跳」。手別是教學提示，不偵測左右手。休止不畫石頭，也不需要按。旗幟在既有課程結尾，結果、星星與下一關以實際已保存成績為準。

既有匹配成功才清除障礙、跳躍；Perfect 的較高跳躍與 sparkles、當次連續 Perfect 提示讀取已判定的結果。Extra 只做小跳，不能清除障礙；Early／Late 使用原有文字，不冒充 Perfect。漏拍的石頭保留且變色，「站穩，聽下一拍再跳」讓玩家恢復。漏拍呈現等待 matching window 加最大允許 calibration offset，避免仍可配對時過早提示。

當次 combo 不影響計分、星星、解鎖或保存；停止、重試、回準備頁清除。GAME-09A 在既有輸入判定後發出短音：Perfect 為亮音，Early／Late 為較輕提示，Extra 為低音且不清除障礙。音效預先合成，快速輸入替換上一個音，沿用音量；靜音不停止節拍。自由節拍器與校正不啟用。漏拍維持視覺恢復提示；動畫、落地與 UI deadline 不觸發音訊。實際 PCM／graph／中斷回歸已通過，真機遮蔽與 touch-to-sound latency 待驗，不能宣稱物理四段 loop 已接受。

## 尺寸與 Accessibility

HUD、場景、節奏格、跳與停止由單一 composition 決定高度。一般尺寸可同時呈現；短高度或最大字級使用同一捲動內容，不把跳鍵疊在節奏格上。提示放在場景上方，角色依場景高度縮放，跳躍弧線限制在畫面內，修正 SE 截圖中提示遮頭的缺陷。

Reduce Motion 保留固定角色、逐格障礙與拍點狀態，停用連續跳躍。語意提示与可操作 TapPad 保留；自動化 AX frame／label 檢查不能取代真人 VoiceOver 或鼓架距離辨識。

## 判定邊界與驗證

View 只讀既有 elapsed、pattern、hit 與 accepted targets。TapPad 的 UIKit 時戳、cue clock、matching、score、progress schema 與 catalog 不變；動畫、碰撞與 frame rate 不創造目標或判分。GAME-09A 修改 practice graph 與判定後副作用，另見 L2 契約／驗證，不能沿用 UI checkpoint 的「所有 Audio files 不變」作當前 claim。

自動化證據見 QA-01-verification.json：實際 touch 清除／重啟、zero-input 失敗、純呈現 fixtures、一般／小螢幕／大字／亮暗檢查分開列出。十關準備及 active HUD 必須顯示實際選定關卡號碼，不能只用截圖檔名當正確關卡證據。

目前仍是產品化 alpha。新畫風／玩法的 owner 接受、三位兒童試玩、真機音畫／touch／frame pacing、成功結果完整矩陣尚待驗證；不能由 simulator PASS 推論公開版本已就緒。
