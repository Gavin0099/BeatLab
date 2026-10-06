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

- GAME-09A native input feedback implemented; physical/public gates pending. <!-- memory_record_projection:active-task-summary:eaa0fe5e67d9791cfb75566fea5631b530854369f4fdc0665f62b4361d1c9579 -->

- GAME-10 egg mission locally implemented and installed; owner gameplay/public gates pending, owned SE Reduce Motion restoration awaits Mac unlock. <!-- memory_record_projection:active-task-summary:3665cdabf7dc6edb9979bcb3cff40db274662a829b60b67b5d965ee92cbe59d5 -->

- GAME-11 implemented local checks pass at9f98c2a, install blocked because phone unavailable; phone remains previous GAME-10, TestFlight unchanged. Source-bound signed candidate ready. Owner GAME-10 better-but-insufficient is partial acceptance only; GAME-11 physical FPS/input timing and fun/public G1-G4 remain unaccepted. Official references and playable old/new comparison in docs/design/runner-fluidity. SE Reduce Motion restoredOFF/light. Implementation and canonical companion separate, push existing product-alpha/ui-checkpoint only. <!-- memory_record_projection:active-task-summary:8b47e7cb1056409c91421a73c43e0f04dca320c5235b18350a107f73fe56c817 -->

- GAME-12 source363a8e8 motion/frame/root-transform and persistent graph checks pass across separately reported actions; signed original-bundle phone installPASS/locked auto-launchFAIL, no data reset. Owner/physical timing/appeal/public gates remain pending; intermediate crash/ghost/query-budget failures retained; no full UI or physical FPS claim. <!-- memory_record_projection:active-task-summary:7418046c61cb2bfda3d2b907234a684670eb9c76fe5c00ebf0c2cc7ac81a010b -->

- GAME-13 IMPLEMENTED_BUILD_PASS_FINAL_UI_PARTIAL_OWNER_PENDING: distinct cloud cat/circuit robot first60BPM; App49/Core53/browser20/wide2 pass; narrow50/2 failed (CoreAudio abort, robot0hit), XXXL/physical/owner gates pending; phone offline, no install/TF/public; source checkpoint8707255. <!-- memory_record_projection:active-task-summary:c47c1c278dcc1b9c84fada9818e548c4637c464a4545794fb2187b7b16a0223d -->
