# BeatLab MVP source handoff

S0～S17 source batch 已建立；不是已驗收 release。App 無第三方 runtime，最低 iOS 16。

在 Mac 解壓後，Terminal 切到含 Package.swift 的目錄：

```sh
bash scripts/run_macos_checks.sh
```

腳本一次跑 SwiftPM tests、C renderer 15 分鐘矩陣、capture analyzer tests、iOS simulator build／App／UI tests；結果保留在 TestResults。
也可先用 Xcode 開 BeatLab.xcodeproj，選 shared BeatLab scheme；真機需自己的 signing team／bundle ID。

自動 checks 完成後，照 [Mac／真機驗收](docs/mac-acceptance.md) 執行 BL-002A、G1～G4；逐列記 [release checklist](docs/release-checklist.csv)。不要直接全部勾 PASS。

Windows 已實跑 156 組實際 C kernel，每組模擬 15 分鐘（總計 39 小時）、最大理想 sample onset error 0.5 sample；不是外部喇叭 capture 或畫面同步結果。Swift tests／Xcode build／iPhone／child playtest 仍 NOT RUN。

本包不含 Git history、governance submodule 或開發 compiler；不影響 App build。治理 pin 保留在原 repo，G0 凍結提交 d872bad；App 變更尚未 commit／push，TestFlight 未上傳。


UIUX-01 原始碼已套用，最新版為 BeatLab-iOS-MVP-UIUX-Mac.zip。設計參考：docs/design/interface-preview.html／interface-overview.png；不是 native screenshot。37 Swift files source check、61 Swift test definitions，實跑仍待上面的 Mac 腳本。參考預覽與配色結果在 docs/design/uiux-verification.json。
