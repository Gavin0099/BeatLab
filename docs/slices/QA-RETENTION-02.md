# QA-RETENTION-02 — 2026-10-15 原始證據根目錄缺失

Heartbeat 要求核對真實來源、測試、推送與安裝證據。本次讀取發現 repo 的
TestResults 根目錄不存在，與10月14日當時的核對觀察不同；缺失原因未確立。
風險L0：read-only audit及狀態文件，不修改產品或重新編譯。

Allowed：本契約／verification JSON、PLAN當前風險註記、canonical memory，
artifacts/evidence/retention/20261015/（只存本次新audit／command／hash）。
Forbidden：App/Core/tests/assets/catalog/progress、治理pin／protected baseline、
覆寫或刪除舊receipt／manifest、重建原包冒充相同bytes、build/install/upload。
既有branch commit/push授權保留；不新建PR／merge或發行。

Verify plan：
1. 記錄根目錄及限定替代位置是否存在；不推定誰刪除或缺失時間。
2. 六個NIGHT slice的174個已記錄hash、鼓手版32個artifact與5個raw bundle
   inventory、14版13檔及ZIP逐項存在性／可驗性；保留missing而非PASS。
3. git HEAD／remote、工作區與cc6f5e7的產品／測試來源一致性、tracked
   canonical summaries／receipt是否保留；摘要不是原始測試重跑。
4. 新稽核本身有獨立輸出與exit status；更新PLAN及canonical memory後跑
   memory_workflow --check --repo . --run-guard；舊runtime環境缺失如實記錄。

Failure paths：把歷史PASS說成今天可重驗；把安裝紀錄說成手機現況；
新增目錄遮蔽初次不存在的觀察；把新build當原安裝包；未知原因杜撰。
不建立新的TestResults；本次紀錄另存tracked retention路徑。
Rollback：只回退本次狀態文字；保留缺失清單，不回填／修改歷史證據。

Status：AUDIT_COMPLETE_RETENTION_FAILED。核對完成；原始證據留存失敗，
不代表新的產品測試失敗，也不代表原始bytes已找回。

## 觀察結果

- NIGHT六片174個hash索引中168檔missing，剩6個tracked檔hash符合。
- 鼓手版32個artifact、5個raw xcresult／各自inventory均missing；原紀錄
  的1330個raw檔無法逐檔重新核對，118-input來源manifest也缺失。
- 14版13檔signed package、ZIP與4個install/launch原始receipt均missing。
  已提交摘要保留當時安裝／開啟成功，但目前手機狀態未檢查。
- git產品／測試來源對cc6f5e7無差異；audit開始local/remote同435e0ec。
  沒有產品改動、build/test/install/upload，也沒有建立新的TestResults。
- 稽核程式實際exit1，完整missing清單／expected hashes、當時command與
  stdout在[新tracked紀錄](../../artifacts/evidence/retention/20261015/audit.json)，
  [verification](QA-RETENTION-02-verification.json)保存其SHA-256。
- 對原位置、桌面同名位置與Trash同名位置的限定存在性檢查均未找到。
  這不是全磁碟搜尋，也不證明被誰刪除；已向owner詢問搬動／備份位置。
- 恢復原始證據需原備份或搬移資料，並用原hash核對；未拿新編譯回填舊包。
  鼓手候選本身已提交，後續仍須新的真機候選／試玩、timing/FPS/兒童/AX驗收。
