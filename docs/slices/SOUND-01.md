# SOUND-01 — 一致的演奏鼓聲

Status: IMPLEMENTED / LOCAL_VALIDATION_PENDING。Risk: L2。Dependencies: PLAY-01。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本批source已實作，尚待當次本機回歸及適用真機gate；以下是實作界線。

## 行為與UI

同一鼓由L/R敲擊使用同一sample；有效遊戲press包括extra都發出相同鼓聲與按壓，TimingHit只控制判定／命中角色回應。非合法輸入區、calibration、取消／中斷／靜音不发聲；count-in末尾仍保留原有合法early窗口。原有背景quarter click與第一關groove不變；A/B必須用同一組音訊。Perfect獎勵主要視覺；不按grade改掉基礎鼓音色。聲音透過audio graph輸入回饋路徑，不從繪製callback播音。

## Allowed files

BeatLab/Audio/MetronomeAudio.swift（PracticeFeedbackVoice only）；BeatLab/App/PracticeStore.swift（validated press feedback dispatch only）；BeatLabTests/MetronomeAudioTests.swift；BeatLabTests/PracticeStoreTests.swift。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/SOUND-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

BLDSP transport/render／CountVoice／PracticeGroove、匹配窗口／calibration／stars/save/catalog；不加新背景曲或細分示範，不複製商業音源，不在UI timer排音。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

rapid taps漏聲／無界queue、voice搶掉reference click、sample-rate/route change、gain0有殘音、無效press產生聲音、同一次press雙重播音、音訊準備失敗只改假playing狀態。

## Checks / gate

共用sample fingerprint与envelope oracle、L/R／Perfect/Early/Late/Extra一致，DSP／matcher原結果不變；valid/invalid press傳遞、rapid bounded voice、stop/mute/interruption/route change。實際input到audible onset量測另屬真機gate，不以scheduleBuffer成功或preferredIOBuffer值當latency。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

回到原grade提示音voice、移除new dispatch，clock／score/save不動。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。
