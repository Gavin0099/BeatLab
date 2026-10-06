# 跑酷流暢度比較 — 2026-10-06

Owner: GAME-10 有比較好但仍不夠，要求參考市面 App 流暢度。保留送蛋回巢與暖黃/深綠風格；此輪改善動作與呈現更新，不增加內容。

## 官方參考與可借用的做法

| 參考 | 本次核對的官方內容 | BeatLab 的應用 |
|---|---|---|
| [Beat Sneak Bandit — Simogo](https://simogo.com/work/beat-sneak-bandit/) Videos / Gameplay & Development | 開發者明確說明操作立即發生、動畫在動作後表達 follow-through，使用 squash/stretch；聲音時鐘驅動遊戲與節拍動畫。 | 直接沿用真實輸入時間呈現跳躍，落地後短暫壓縮；動作不延後判分。 |
| [A Dance of Fire and Ice — 開發者](https://fizzd.itch.io/a-dance-of-fire-and-ice) | 單鍵控制軌道中的兩顆星球走過路徑，幾何形狀承載節奏。 | 視覺位置必須連續、下一個障礙可預判；不借用其嚴格難度或美術。 |
| [Jetpack Joyride Classic — Halfbrick](https://www.halfbrick.com/games/jetpack-joyride-classic) / [官方 trailer](https://www.youtube.com/watch?v=Jzxi8nid9BQ) | 官方頁介紹持續跑酷、單觸控與障礙；影片來源為 Halfbrick。 | 地面持續流動、操控入口保持穩定、角色與障礙比文字重要。此列為 BeatLab 設計推論。 |
| [TimelineView — Apple](https://developer.apple.com/documentation/SwiftUI/TimelineView) / [SwiftUI performance](https://developer.apple.com/documentation/Xcode/understanding-and-improving-swiftui-performance) | Timeline 提供排程更新；性能需要 runtime profiling，排程頻率不是 FPS 證據。 | 場景使用 display animation schedule，HUD/聲音/判分不由它更新；只有測量才能聲稱幀率。 |

本輪實際閱讀官方描述與開發紀錄，找到官方影片連結；沒有實際玩商業 App，也沒有取得影片播放/商業 App FPS、input latency 或掉幀資料。不要把 trailer 的觀感/產品名稱當成性能 benchmark。

## 原生來源中確認的問題

- 場景只讀每30ms才publish一次的 `practice.elapsed`：名義33.3次/秒上限，不是測得真機33FPS。
- 背景 `%8` 每八秒從24px偏移回到0：來源可直接證明不連續。
- `latestHit` 被extra取代時，74px的matched跳躍立即換成12px小跳；實際視覺是否引發不適尚待試玩。
- 各atlas cell的透明邊距不同；採共同source scale、實際圖形crop與腳底baseline避免站姿浮動。原圖未編輯。
- cue文字長度改變可能改layout高度；保留最長提示的版面，不移動触控區。
- 瀏覽器每幀重設canvas尺寸、native多個Canvas各畫完整atlas；改runtime region cache和單一scene Canvas。這是減少重複工作，尚不等於性能測量改善。

## 試玩與工程界線

Repo root 執行 `python3 -m http.server 7811 --bind 127.0.0.1`，開啟 [可玩比較](http://127.0.0.1:7811/docs/design/runner-fluidity/play.html)。勾選「改善動作銜接」可切舊/新版呈現，保留同一段browser音訊與真實手動判分；沒有App進度保存。此開關只在概念存在。

Native只讀原有audio-host epoch，場景TimelineView請求60Hz。用原始hit.inputTime決定動作年龄；accepted動作保留0.64秒（0.48跳躍+0.16落地），extra不能截斷/延長，亦不會在落地後重播舊extra。跑姿與落地姿勢短暫交叉淡化，避免換圖的一幀跳動。背景有限連續平移、近景地面在視野外wrap，角色腳底對齊，動態陰影、短暫塵土和壓縮。Reduce Motion關閉位移/旋轉/壓縮；停止/重試不保留前次動作。未改Audio、DSP、Core、TapPad、星星或保存。

瀏覽器檢查包含零輸入真實失敗、重試、16次clock-cued觸控通關、duplicate extra、取消、尺寸、loaded sprite pixels、8秒邊界與動作連續性。初次cache過早保存未載入圖片的空白結果已發現修正，舊記錄保留。後續一次跨程序觸控自動化未達真實通關門檻，失敗保留；改為browser內輪詢實際AudioContext clock並派發PointerEvent，沒有改grade/hits/window或強制成功。另避免每幀重寫同字文字、ResizeObserver取得尺寸、進度以transform縮放。原生驗證詳見 `../../slices/GAME-11-verification.json`；真機性能、音画/input timing与兒童重玩意願須分開接受。

## 本輪驗證與交付

可玩比較22 checks、core53、原生wide47通過；SE实际touch/restart、一般viewport、最大字級四輪與dark檢查通過。前三次最大字級fixture失敗保留，不能稱完整UI suite單次全綠。原生預览見 native-wide.png / native-narrow-dark.png / native-narrow-largest-stop.png。舊SE Reduce Motion已還原OFF、appearance light。

Signed Debug候選已完成source/artifact/signature核對，但devicectl安裝失敗（配對手機不可用），新版尚未裝入手機。Instruments無法attach offline手機；simulator Hitches不支援。請求60Hz只是呈現排程，物理FPS、input latency、掉幀和兒童吸引力仍待驗；沒有新TestFlight或public分發。
