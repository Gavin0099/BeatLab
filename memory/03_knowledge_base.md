# Knowledge Base

## Foundation decisions

- PLAN／docs/verification 為需求與 gate 權威。G0 不要求治理 100% 自動化，runtime／hooks／validator debt 不阻塞 BL-001。
- BL-001 iOS16 SwiftUI shell → main-actor ConfigurationStore → framework-free BeatLabCore → UserDefaults versioned envelope；詳 docs/adr/0001-foundation-boundaries.md。
- 6/8 是兩個附點四分拍；compound eighth 與 simple meter subdivision 分開；拍號更改原子調整相容 subdivision。
- Codable 自動合成可绕過初始化邊界，因此 Tempo／Configuration 的 decode 明確驗證；未知 storage schema 保存原資料、阻止覆寫，需 explicit reset。
- UI 單一 source of truth；audio engine 只有 BL-002 才引入。未執行 Apple build/tests 不視為驗收成功。


## MVP timeline and progression

- Owner 2026-10-04 明確授權 S0～S17 全批先實作再到 Mac，覆蓋舊 implementation stop；各 device／child／release acceptance 仍未通過。
- C11 audio kernel 用整數 rational sample positions、原子 mailbox/history。UI 只讀 audio clock；下一未 render 的 beat／bar 套設定，不能回收硬體已接收 buffer。
- Gap 只靜音不重設 transport；Ladder 完整小節 +5／240 clamp，手動 BPM 退出。Lessons 固定音訊 tempo，暫停 Gap／Ladder 後再恢復。
- Speech PCM 在 Start 前由 Apple TTS 預渲染、trim/resample/copy，不在 realtime callback 用 TTS。準備失败可切回 Click；切回 Click 必須取消 loading，不可繼續禁用 Start。
- 同 rhythm pattern 給 lane／targets，休止不生成 target；touch-down uptime 以 event age 映射 host clock。最近 target、tie earlier，已命中最近 target 的 duplicate 是 extra；不移到鄰近拍。
- Calibrated ms 為 user alignment estimate（含人的偏差），route／sample rate 綁定；Bluetooth／未校正／VoiceOver 不顯示精準 claim。硬體延遲仍需獨立實測。
- 星星／解鎖基於 full-session hit/perfect/extra，best BPM 只在較高 tempo pass 才更新；future progress schema 保留、不覆寫。
- Capture analyzer regression 發現 last-minute inclusive boundary 讓交替 ±1 ms fixture 的末端 median 偏 +1 ms；改最後窗左端開區間，使兩端同為 60 秒，再由 known-offset／drift／不足解析度 fixtures 驗證。
- 全部 Swift tests／Apple rendering、聲音與畫面同步、Voice 清楚度及 child replay 未執行；source syntax 不是 compiler evidence。


## UI/UX state boundaries

- 清楚分開 lesson preparation／playing／finished；ordinary text 的 Tap Pad／transport fixed，Accessibility text 改 flow，避免覆蓋整個 viewport。
- 初版 result 在 save 失敗時仍會使用 stars 推出下一關；UIUX-01 新增 resultSaved／pending retry，保存前不顯示 persisted unlock。最近的 future-write guard 保留，新增 Mac regression 定義。
- Future schema 允許 explicit reset；missing catalog 是 resource failure，不應提供會刪 progress 的 reset。Calibration saved／estimate failed／pending save 分開顯示。
- HTML design reference 的 layouts／contrast 通過不等於 native UI 或 WCAG conformance；actual Apple screenshots／assistive technology 必須另外驗。
