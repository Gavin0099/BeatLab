# Active Task

## Current Status

- G0 frozen: d872bad；framework pin／protected baseline 未修改。
- Owner 明確授權整個 S0～S17 source batch 完成後才到 Mac 驗收；此為里程碑策劃更新，不是 session closeout。
- 全 MVP 原始碼已建立：M1 metronome、M2 voice／lane／tap／score、M3 10 lessons／progress、M4 Gap／Ladder／daily／mode／lifecycle／accessibility。
- 156 組 C renderer 各 15 分鐘離線長測 PASS，0.5 sample 最大 onset error；Gap／Ladder／voice fixture／restart／silence＋UBSan PASS；capture analyzer 3 regression tests PASS。
- Swift syntax/project references PASS；58 Swift test definitions 尚未跑。Swift compile／Xcode build／App launch／UI／真機／兒童／release gates NOT RUN，所有 slices 維持 IN_PROGRESS。
- Owner 已授權 App commit／GitHub branch push；PR／merge／TestFlight 未執行。Runtime governance automation 為已接受非阻塞 debt。

## Next Steps

- 在 Mac 開 source package / BeatLab.xcodeproj，執行 `bash scripts/run_macos_checks.sh`，保留 TestResults。
- 再依 docs/mac-acceptance.md 按 BL-002A／G1／G2／G3／G4 驗收；不以離線 sample 或 syntax PASS 取代 Apple/device evidence。
- 校正為含人為偏差的 user alignment estimate；聲音 onset／input latency、Voice intelligibility／高速截字及 child playtest 尚未證明。


## UI/UX milestone

- UIUX-01 原始碼已套用：shared styles／semantic colors、Home 主動作、fixed transport／tap pad、課程 sheet、明確的 lesson/session/result/recovery。
- Reference prototype 33 layouts 與 26 token pairs PASS；37 native Swift files syntax／93 project objects membership checks，61 Swift test definitions NOT RUN。不是 native-rendering／VoiceOver acceptance。
- Progress save failure 保留 summary／pending data，可重試；未成功不宣稱 saved／unlocked，catalog missing 不顯示 destructive reset。
- 最新交接包改用 BeatLab-iOS-MVP-UIUX-Mac.zip；Apple gates 仍待 docs/mac-acceptance.md。

- Productized alpha UI checkpoint; sound feedback and physical/child/public gates remain pending. <!-- memory_record_projection:active-task-summary:be36766a35bf7f53ad1bb50825279270f822b7c4313f14d46ff2a2a0683b1ff1 -->
