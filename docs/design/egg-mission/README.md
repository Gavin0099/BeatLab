# 把恐龍蛋帶回家

2026-10-06 owner 接受的第一關玩法試驗。沿用 first-beat：60 BPM、四拍數拍、十六次右手大拍、原有命中／Perfect／extra 與過關門檻。

## 試玩

App：首頁開始冒險 → 第一關「把恐龍蛋帶回家」→ 帶蛋出發。恐龍夥伴、60 BPM 才使用這個試玩；其餘速度、夥伴與九關保留原 runner。

獨立可玩概念：在 repo root 執行 `python3 -m http.server 7810 --bind 127.0.0.1`，開啟 `http://127.0.0.1:7810/docs/design/egg-mission/play.html`。先按「出發」才啟用瀏覽器音訊；離開分頁會停止，不保存學習進度。`verify.cjs` 使用實際 AudioContext 時間及按鈕事件，測零輸入失敗、16 次實際節拍輸入完成、重試、duplicate/extra、取消與三種寬度；可透過 PLAYWRIGHT_PATH/CHROMIUM_PATH 指定已安裝的瀏覽器測試工具。

## 呈現

出發前看見巢與抱蛋恐龍；石頭靠近預告下一拍。接受的輸入跳過石頭，Perfect 亮起蛋和連續拍提示；多打原地小跳，漏拍接蛋後恢復。到達巢後用真正星星決定成功／再試一次，保留保存失敗的復原。沒有生命／貨幣／新的課程。動畫和碰撞不參與判分。

原創 kick/snare/hat 四小節 PCM 混入既有 C render cursor，四拍數拍後才開始。聲音不是由畫面排程。自由節拍器與校正不使用此段音樂；參數切換會停用不相符的段落。實體 route 的 audibility、audio/input/display latency、frame pacing 與孩子是否想重玩仍需驗證。

Atlas 由內建 image_gen 產生，參考現有 HomeDinosaur 的身份與畫風。素材保存於 `BeatLab/Resources/Assets.xcassets/EggMissionAtlas.imageset/artwork.png`，alpha 原樣保留；[完整 prompt](art-prompt.txt)、[來源與實際裁切區域](art-source.json)。只在 SwiftUI Canvas/HTML Canvas 渲染時取 source rectangle，沒有另行編修原圖。

参考規則沿用 beatlab-rhythm-game-design skill 的官方來源；沒有複製參考遊戲圖、歌曲或關卡。工程檢查不代表兒童吸引力或 public readiness。
