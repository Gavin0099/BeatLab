# GAME-16：節奏小島 · 送蛋回巢

第一關的隔離可操作概念。原生 App、TestFlight build 11、音訊與存檔未修改。

從 repo root 執行 `python3 -m http.server 7820 --bind 127.0.0.1`，開啟 http://127.0.0.1:7820/docs/design/rhythm-swing-concept/play.html 。既有圖集以相對路徑讀取，不能只拷貝單一 HTML。按「出發」，先聽四拍，再隨鼓声按「跳」；滑鼠、觸控、鍵盤 Enter／空白鍵皆可。開始後右邊方形鍵停止；離開可見頁面立即取消，沒有結果或保存。

## 第一關契約

60 BPM，4 拍數拍，16 個四分音符，目標時間 4…19 秒，20.2 秒結束。四格路線預告本小節，不增加模式或音符。黃色腳印是固定到拍位置；石頭每秒等距到達。提早命中仍保留石頭到 crossing，避免視覺間隔忽長忽短。成功跳躍有起跳／落地，Perfect 加亮光與連續數，early／late 如實提示；extra 不推進、不取代正在進行的接受跳躍；漏拍短暫接住但不換回舊靜態圖。Reduce Motion 保留靜態角色、跳躍位置與拍點結果，停止連續場景與動作。

「蛋到家」只在實際結果達既有第一關門檻時出現：16 目標中至少 14 命中、9 Perfect、多打最多 1 下。零輸入必敗。失敗可以重試，沒有生命、貨幣或重設學習進度。這些分數只在瀏覽器記憶體存在。

## 邊界

WebAudio.currentTime 是此試稿的唯一時間參考，聲音預先排程；動畫只讀時間／輸入結果。DOM input 採 browser-only matching，零 calibration offset；±180ms 命中、±50ms Perfect、最近目標同距先取較早目標、重複最近目標算 extra。規格來源是既有 TimingSession／first-beat 課程。此碼不得移植取代 native 音訊／UIKit clock／grade。此 UI 並未增加更高幀數素材，不能宣稱真機流暢度改善。音樂沿用過去概念的原創鼓點 pattern，沒有引入歌曲。

## 驗證與 owner gate

`CHROMIUM_PATH='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' node docs/design/rhythm-swing-concept/verify.cjs`

使用真實 DOM 輸入及運行中的 WebAudio 時間；不注入得分／結束狀態。測實際完整命中、零輸入、取消／重試、early／late、extra／duplicate、鍵盤、窄屏／深色／放大字／Reduce Motion。程式檢查與 screenshots 是概念行為／排版證據，不能證明手機音畫同步或兒童覺得好玩。放大字 class 是排版 stress fixture，不是完整 OS Dynamic Type 或 VoiceOver 驗收。

Owner 驗收仍 PENDING：第一次 10 秒能否說出任務及何時按；完成一次是否願意再玩；漏拍能否理解下一拍再接。接受這個可操作 loop 後才進 GAME-17 原生 adapter。GAME-17／18／19、QA-02 native/device/child、TF-05 尚未執行。
