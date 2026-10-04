# BeatLab UI/UX

已套用 native SwiftUI 原始碼。設計預览在 interface-preview.html；interface-overview.png 是 HTML 參考畫面，不是已編譯的 iPhone screenshot。

## 視覺與流程

- 暖白／深紫：大拍與 BPM 使用 system rounded / tabular numerals，按鈕至少 44pt（主要按鈕 52pt 以上）；綠色只給 Perfect，金色給星星。所有狀態同時有文字／圖示，不能只靠顏色。
- Home：今天的推薦課程是主動作；真實完成關數與繼續練習是次動作；自由節拍器容易找到。沒有虛構 streak 或時長。
- Metronome：BPM／slider／±1±5／Tap Tempo 在主區，大拍單獨顯示；開始／停止固定底部。拍號／細分採 disclosure，聲音／音量與模式可直接找到。Standard 才展開 Gap／Ladder。
- Practice：準備、進行、結果分開；準備頁有 R/L/休止說明與 4 拍 count-in 提示；課程列表移到 sheet，鎖定原因明示。
- 進行中：普通字級的 Tap Pad／停止固定底部，節奏格可捲動。Accessibility 大字改為自然捲動，避免整屏被固定控制佔滿；節奏格按 beat 分组，active 同時有 dot／selected trait。
- 結果：一句鼓勵、實際 stars/hit/perfect 與下一步。Beginner 不顯示 ms；Standard 的技術資訊收進 disclosure，且只有 route-bound alignment 才顯示 ms。完成第十關不再承諾不存在的下一關。

## Recovery

- Speech preparation：顯示準備中，可以切回 Click，Stop 隨時可操作。
- Playback / interruption / cancellation：保留設定，說明重新開始；停止不是 pause，不暗示可續接。
- Future schema：說明更新或 explicit reset；reset 與課程/節拍器各自分開、confirm 才執行。
- Missing catalog：顯示重開 App／自由節拍器路徑，不提供會刪進度的 reset。
- Unsaved results：保留 summary、顯示未保存、重試保存；不解鎖／不顯示已保存成功。未保存期間不替換結果；explicit discard 需 confirmation。
- Calibration 保存失敗／估計失敗／完成分開，只有保存成功才顯示完成。

## 證據與限制

HTML reference 在 Chromium 33 layouts 檢查：320/390/768、light/dark、large text 及四頁總覽；無水平 overflow，visible buttons/selects 高度 ≥44px。Dialog 開／Escape 關、locked lessons、primary navigation、示範 tempo/start/stop、keyboard focus、reduced motion media checks PASS。Preview 沒有音訊、實際計分或永久進度，demo result 明確標示。

26 token pairs contrast PASS，最小 5.1074:1；並非 native rendered pixel sampling 或 WCAG conformance。Typography 用 system fallback、400/600/700 weight、unitless leading、bounded measure、tabular figures。無外部 fonts／影像／frontend runtime。

Native source syntax、colorset/resource／project membership checks 與新增 Mac test definitions 有記錄，Swift compile、SwiftUI render、VoiceOver、Dynamic Type extreme sizes、physical tap、child playtest 全部 NOT RUN。frontend-design hard gates 未取得 native evidence，不能以參考圖宣稱 App UX 已驗收。

依據：[Apple accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)、[ViewThatFits](https://developer.apple.com/documentation/swiftui/viewthatfits)、[AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate)。
