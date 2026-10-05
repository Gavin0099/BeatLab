# PROGRESS-01 — 功能盤點、品牌改版拆分與目前進度 push

2026-10-05 owner 確認首頁風格，指出節拍器／練習不一致，要求先分析、切 slice，再 push 目前進度。

本輪 L0 文件／checkpoint，不實作下一輪畫面。待提交的累積來源含 MET-01 的 L2 audio/config 改動；此 checkpoint 不把它降級，也不補稱真機 gates 已通過。

Allowed edits: 本契約與 `docs/slices/PROGRESS-01-verification.json`；`docs/design/FEATURE-AUDIT-20261005.md`；`docs/slices/UI-BRAND-01.md`、`MET-02.md`、`GAME-08.md`、`GAME-09.md`、`QA-01.md`、`TF-03.md`；PLAN／README／verification／mac-acceptance 的當前狀態摘要；HOME-01、TF-02 evidence 的後續 owner 回饋欄位；`.gitignore` 增加 `.derived-data-log-*`（保留本地檔案）。Ignored `TestResults/PROGRESS-01/` 存 manifests、checks 與 delivery receipts。

Authorized delivery: 將現有 BeatLab／Xcode project／Sources／Tests／App tests／UI tests、原創與來源已記錄 assets、design docs／slice contracts／evidence 與本輪分析 commit 到既有 `codex/bl-001-app-foundation`，push 同名 origin branch。歷史檔案視為 checkpoint，不重寫其當時未提交／未交付的紀錄。不得 stage 全目錄以夾帶 transient logs。

Forbidden: 本輪新增 UI／玩法／audio／score／schema 行為、改 build／bundle／icon；framework pointer／protected base／治理規則更新；memory 記錄手寫；credentials／profiles／IPA／archive／DerivedData／logs 上傳；PR／merge／新 TestFlight 或 App Store 送審。

Checks: fetch 並確認 branch 無 divergence；61-file TF-02 production manifest 對照當前 bytes；`swift test`、focused C boundaries/restart/silence/Gap/Ladder/voice/beat-controls、capture analyzer failure fixtures；JSON／plist／staged diff lint；只輸出路徑的 staged secret/large-artifact inventory；freeze staged file hashes；commit 後逐檔比对與 remote branch SHA 一致。沿用歷史 native evidence，但本輪不把 simulator／真機未重跑宣稱為新通過。此提交保存可試玩候選；G1-G4／兒童體驗未接受。

Failure paths: remote ahead/divergence → preserve local state, inspect before integrating; checks fail → preserve logs and repair only checkpoint-related issue or report concrete blocker; secret/artifact → exclude before commit without printing contents; push outcome unknown → compare remote SHA before retry。Rollback: 只恢復本輪文件 before snapshots或 unstage 本輪路徑；不 reset 現有來源，不 force push／刪 remote branch。
