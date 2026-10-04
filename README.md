# BeatLab

iOS MVP：節拍準、孩子看得懂、練習有成就感。
G0 baseline 已凍結；S0～S17 原始碼已建立。Swift／Xcode／真機／兒童與 release 驗收尚未執行，不宣稱可發行。

已實作：30–240 BPM、音訊 sample clock、拍點、Tap Tempo、2/4／3/4／4/4／6/8、細分／重音、Click／Voice／Both、rhythm lane／跟拍回饋、10 JSON 課程、星星／解鎖／best BPM、Gap Click、Tempo Ladder、daily／continue、Beginner／Standard 與安全中斷停止。

- [Roadmap 與狀態](PLAN.md)
- [Mac 一次驗收](docs/mac-acceptance.md)
- [Timing／互動／Release gates](docs/verification.md)
- [完整 slice 契約](docs/slices/MVP-implementation.md)
- [音訊／跟拍架構](docs/adr/0002-audio-and-practice-timeline.md)
- [Repo AI 規則](AGENTS.md)／[治理導入狀態](docs/governance-adoption.md)

在 Mac 開 BeatLab.xcodeproj，shared BeatLab scheme；最低 iOS 16，Swift 5 language mode。App 無第三方依賴；Apple speech 在播放前預渲染，聲音只由音訊 callback 排程。真機需自己的 signing team／bundle ID。

```sh
bash scripts/run_macos_checks.sh
# 或只跑 core
swift test
```

自動測試結果存 TestResults；真機與 child gates 按 docs/mac-acceptance.md 執行。未到 Mac 前，37 Swift files 僅 syntax parse，61 Swift test definitions 均 NOT RUN。
Windows 實際 C kernel 已通過 156 組各 15 分鐘離線長測（總計模擬 39 小時）、最大 onset 誤差 0.5 sample；boundary／restart／Gap／Ladder／voice fixture 與 UBSan 通過。這不證明喇叭 onset、UI 同步或 touch 硬體延遲。
證據：[source](docs/slices/MVP-source-check.json)／[C kernel](docs/slices/MVP-dsp-tests.json)／[local verification](docs/slices/MVP-local-verification.json)。

開發用 source checks：依 scripts/requirements-sourcechecks.txt 安裝檢查工具後跑 `python scripts/check_source.py`；不屬於 App 依賴。Capture analysis 用 Python 標準函式庫；`python -m unittest discover -s Tests/TimingCaptureTests`。
Clone repo 後可 `git submodule update --init --recursive` 載入治理框架。原始碼 ZIP 不含 Git/framework，但包含 App、package、resources、tests、docs、驗收腳本。
Owner 已授權提交與推送 GitHub 開發分支；PR／merge／TestFlight 不在本次授權範圍。Apple／真機驗收仍待執行。


UI/UX 已套用：暖白／紫色 light/dark、固定 transport／tap pad、課程 sheet、清楚的準備／進行／結果與 recovery。[設計預覽](docs/design/interface-preview.html)／[設計與驗證](docs/design/UIUX.md)；reference 不是 SwiftUI render，Apple 驗收未跑。
