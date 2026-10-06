# GAME-15 漏拍後保持動作連續

現版要求 60 FPS，但跑步只有 8 張姿勢圖、跳躍 6 張。更新頻率不等於動畫姿勢幀數；本次不新增素材，不將這項限制宣稱為已解決。

確認並重現的另一個問題：漏拍會讓角色切成静態 recovery 圖、身體尺寸／anchor 改變、bob 突停，0.48 秒後才切回原來跑步。Native 舊版回歸測試一項失敗、13 個斷言失敗，涵蓋恐龍、貓咪、機器人。

本次契約保留跑步與跳躍的既有圖集／相位、幾何和 bob；漏拍使用既有提示文字和短暫 white tint，新的操作立即清除 tint，Reduce Motion 使用靜態 highlight。音訊、判分、石頭到拍時程和存檔不變。

`play.html` 可在真實無輸入漏拍的同一個窗口切換舊靜態圖／新連續跑步。`verify.cjs` 觀察實際 canvas renderer 的角色狀態後，走零輸入失敗、重試、真正 16 次 clock-cued 操作、Extra 和取消。它是獨立 browser concept，沒有 App 成績注入。

真機 Animation Hitches 擷取因無線裝置連線逾時失敗，沒有取得 gameplay，不能因此診斷或排除掉幀。完整 final build／native／phone 狀態見 GAME-15-verification.json；KidsCharacterKit 仍延後導入。
