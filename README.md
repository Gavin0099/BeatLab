# 拍拍冒險（BeatLab）

iOS 本機節奏練習 App：自由節拍器＋恐龍跟拍課程。目前 owner-only TestFlight 為 **0.1.0（10）**，bundle `com.gavin0099.beatlab`。首頁黃綠恐龍風格已獲 owner 手機回饋認可；節拍器與練習風格仍待下一輪改版。內部 beta 可測不等於正式上架 ready，G1～G4／物理 timing／兒童與完整 accessibility 尚未接受。

## 目前功能

- 30–240 BPM、slider／±1／±5／Tap Tempo、tempo undo/redo；2/4／3/4／4/4／6/8 與合法細分。
- 每大拍重音／一般／靜音；電子／木魚／機械合成音色；節拍聲／預渲染數拍／兩種；音量、擺針、畫面與 best-effort 震動。播放中變更由 audio engine 決定生效邊界；volume 0／靜音不重設 transport。
- 入門／標準；標準 Gap Click、Tempo Ladder、跟拍對齊與本機成績 JSON Share。
- 三篇章／十個 JSON 關卡，四分→左右→八分→休止→十六分→反拍／混合；四拍 count-in、R/L/rest、真實判定與 runner 障礙呈現。
- 星星、逐關解鎖、最佳成績／BPM、daily／continue；保存失敗重試／放棄。三個夥伴的選擇是當次 View state。
- 背景／中斷／route change 安全停止；本機設定與進度損壞／未知版本防護。無帳號／雲端／麥克風／MIDI。

原生 runner 沿用課程判定，沒有瀏覽器概念的生命／救援經濟、完整配樂或跑步 sprite。6/8 的 BPM 是附點四分音符的大拍、每小節兩大拍。早期開發 bundle `com.beatlab.app` 與現在 beta 不同，舊資料不自動遷移。

## 下一輪切分

[功能盤點與六個 slice](docs/design/FEATURE-AUDIT-20261005.md)：共用品牌 → 節拍器 → 旅程／準備 → 遊玩／結果 → 整體驗證 → 接受候選後 TestFlight。這轮完成分析與來源 checkpoint，後續契約皆 PLANNED，未新增畫面或變更時計／評分。

- [Roadmap 與當前狀態](PLAN.md)
- [首頁證據與 owner 回饋](docs/slices/HOME-01-verification.json)
- [當前 TestFlight delivery](docs/slices/TF-02-verification.json)
- [目前進度 push evidence](docs/slices/PROGRESS-01-verification.json)
- [Mac／iPhone 驗收入口](docs/mac-acceptance.md)
- [Timing／互動／Release gates](docs/verification.md)
- [歷史設計與未接受概念](docs/design/GAME-DESIGN.md)

## 開發與驗證

Swift／SwiftUI、iOS 16+，App 使用本地 Swift package，沒有第三方 App 套件。用 Xcode 開 BeatLab.xcodeproj，選擇自己的 team 與唯一 bundle。App 的 release／distribution signing credentials 不在 repo。

```sh
swift test
python3 -m unittest discover -s Tests/TimingCaptureTests -v
bash scripts/run_macos_checks.sh <BEATLAB_SIMULATOR_UUID>
```

原始 C renderer 測試、App/store/UI checks 與 logs 由 macOS 腳本收集於 ignored TestResults/，不自動勾選 device／兒童／release gates。Source check `python3 scripts/check_source.py` 只做 syntax／結構，需 scripts/requirements-sourcechecks.txt 中開發工具，不能替代 Swift typecheck 或 App runtime；該腳本會更新其對應 source-check evidence。

Clone 可 `git submodule update --init --recursive` 取得 pinned 治理框架；本輪沒有更新框架或保護的 AGENTS.base.md。個人遊戲 skill 不在 repo，設計決策與素材 provenance 已存 docs/design。原圖與必要 app assets 入庫，IPA／archive／DerivedData／credentials／raw logs 留在本機。

Owner 授權提交與 push 目前進度到既有開發分支；本輪不建立 PR／merge／新 TestFlight 或 App Store submission。歷史試玩及檢查以各 slice evidence 的當時 source hashes／status 為準。
