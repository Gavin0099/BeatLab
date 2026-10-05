# 拍拍冒險共用設計基礎

UI-BRAND-01；2026-10-05。首頁与 icon 已接受，這份規格建立後續畫面的預設，不改每頁資訊結構或玩法。

## 語意 token

| 用途 | SwiftUI token | Light | Dark |
|---|---|---|---|
| 畫布 | BeatLabStyle.canvas | #F9F8EE | #122921 |
| 卡片 | BeatLabStyle.surface | #FFFDF5 | #1D382D |
| 主要文字 | BeatLabStyle.ink | #203E31 | #EDF4E9 |
| 次要文字 | BeatLabStyle.muted | #52675B | #B9CABA |
| 主操作／選取 | BeatLabStyle.accent | #285D45 | #A5DEAC |
| 次操作／狀態底 | BeatLabStyle.accentSoft | #E6EFE4 | #294A39 |
| 主按鈕文字 | BeatLabStyle.onAccent | #F9F8EE | #122921 |
| 分隔 | BeatLabStyle.line | #CCD8CD | #536D5B |
| 正向回饋 | success／successSoft | #226746／#E2F2E8 | #8FE0B4／#233D32 |
| 星星／徽章 | reward／rewardSoft | #8A4C0E／#FFF0D8 | #FFD496／#473726 |
| 冒險 hero | HomeBrand.hero | #FFE181 | #F5CF65 |

HomeBrand 是首頁相容入口；canvas／surface／ink／muted／forest 指向同一 BeatLabStyle authority。Home* assets 原 bytes 保留，作已接受基準。現有共用元件與 Root tint 不再各自決定主色；舊 `Color.accentColor` 亦由相同 AccentColor asset 取得。

## 型態與元件

- TypeScale：title＝Dynamic Type rounded title2 bold；action＝headline bold；secondaryAction＝headline；body＝subheadline；label＝subheadline semibold。遵從系統字級，不固定 point size，也不靠縮小文字避開大字。
- Spacing：compact 8、regular 12、content 16、card 20、section 24 pt。
- Radius：card 24、primary 18、control 16 pt。舊特殊 hero／scene 圓角在其頁面改版片處理，不做全 repo rewrite。
- BLCard／BLSectionHeading／BLPill／BLStatusMessage 使用這些 tokens；primary／secondary button 使用同一套字級、padding、enabled／disabled／pressed 與 Reduce Motion 規則。首頁主按鈕走同一元件。
- 可互動目標至少 44×44 pt。共用按鈕高度保留：primary 最少 56 pt、secondary 最少 46 pt；icon controls 由容器確保寬度。不同尺寸仍需 native frame／hittable 檢查，不靠常數宣稱整 App 達標。
- 選取要有文字／形狀或 selected trait；成功／失敗／disabled 不只改顏色。語意狀態由已有實際 store 決定，設計元件不擁有 musical targets／成績／保存。

## 角色語言與停止擴功能

主參考為 icon／HomeDinosaur：綠色身體、暖黃環境、圓潤形體、清楚輪廓與一致陰影。首頁是冒險邀請；節拍器是樂器控制；遊玩讓角色和 upcoming cue 占主要視線。不要每頁塞同一張大 hero 卡片。

這片不生成／替換 art。練習舊恐龍與猫咪／機器人素材的造型統一留 GAME-08；保持現有選項，不增角色／Skin。場景、跳躍、落地／miss 表現與當次 combo 留 GAME-09；不加新章節／模式。整頁視覺接受不能由換 token 代替。

## 本片驗證

當片 native 三頁、settings／companion sheets、首頁入口與設定 relaunch；light、dark、短螢幕、最大字級。量測列出的實際 solid color pairs；native screenshots 逐張檢視。VoiceOver／實機 timing／兒童理解与完整 Accessibility 不從色票或 simulator 推斷。

下一輪 QA-01A／B／C 嵌入各片，Final 才做完整 regression。現況為「功能完整，產品級 timing validation 尚未完成」的產品化 alpha；TF-03 前四項接受 gate 以 QA-01 契約為準。
