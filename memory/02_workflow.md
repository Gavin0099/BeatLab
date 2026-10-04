# Tech Stack / Workflow

- Swift 5 language mode／SwiftPM tools 5.9、iOS 16+、SwiftUI／UIKit touch input、AVAudioEngine／AVAudioSourceNode、C11 sample kernel。
- BeatLabCore 本機 package，JSON lesson resources；BeatLabDSP 無第三方 runtime。UserDefaults versioned settings／progress，future schema 不覆寫。
- Windows／PowerShell：Zig 0.13.0 cc 執行真實 C renderer，Swift syntax 與 project source checks；沒有 Swift／Xcode compiler。開發工具在 ignored artifacts/development，非 App dependency。
- Mac 驗收入口：scripts/run_macos_checks.sh、docs/mac-acceptance.md；device/child gates 需另外實測接受。
- AI Governance 為 pinned ai-governance-framework submodule consumer，未改 pin／protected baseline；memory lifecycle hooks／runtime automation 未確認。
- 目前更新為 curated milestone/decision state；沒有 inferred session-end daily memory writer。
