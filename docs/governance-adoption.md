# BeatLab AI Governance 初次導入

2026-10-04，consumer 類型：submodule_consumer。這是本機初次導入，不是 F-7 full update。
Canonical source：https://github.com/Gavin0099/ai-governance-framework.git
Pinned commit：15722daadca7f7f28eb00250170b34844caf600b，導入時以 git ls-remote 比對 main。
尚未建立 parent commit／push／PR。submodule add 自動 staged .gitmodules／gitlink；其他檔案未 staged。

## 已落地

- 官方 adopt_governance.py：dry-run 後 apply，生成 protected baseline、AGENTS、contract、PLAN、governance/rules、memory scaffold。
- PLAN.md 保留 M1～M4、S0～S17，具體化 BL-001～006；docs/verification.md 記錄 G1～G4。
- AGENTS.md 增加 timing、scope、risk、must-test 與真機證據規則。
- governance/framework.lock.json 記錄 pin；未 commit 時 maturity checker 會報 working-tree lock inconsistency，不能改寫成 committed consistency。
- CI workflow 改成實際 ai-governance-framework 路徑；尚未在 GitHub 執行。

## 邊界

沒有安裝本機 commit/push hooks 或 Codex lifecycle hooks；沒有 repo-specific domain validator；memory 僅 scaffold／初始策劃狀態。
framework smoke 驗證治理工具入口，不證明 iOS App／音訊時序／觸控校正／兒童體驗。
Windows 不支援本次 iOS build／真機驗收；所有產品 gates 尚未執行。

## 重跑檢查

在 repo 根目錄執行（Python 3.9+）：

```powershell
python -X utf8 ai-governance-framework/governance_tools/governance_drift_checker.py --repo . --framework-root ./ai-governance-framework --format human
python -X utf8 ai-governance-framework/governance_tools/quickstart_smoke.py --project-root . --plan PLAN.md --contract contract.yaml --format human
python -X utf8 ai-governance-framework/governance_tools/external_repo_readiness.py --repo . --framework-root ./ai-governance-framework --format human
```

結果存 .governance/evidence/。readiness 不會因靜態檔案存在就完整 PASS；未導入 hooks／project facts 等照實保留。
日後更新 framework 使用官方 F-7 路徑；不可手動 bump 後宣稱 full_update_completed。

## Executable trust 檢查

套用 external-executable-trust-audit 技能，範圍為 adoption chain：

| Executable | 分類 | Binding／environment | 證據與邊界 |
|---|---|---|---|
| Git | 本機導入與讀取 source | 外層已解析絕對路徑 C:/Program Files/Git/cmd/git.exe；環境未隔離 | command resolution／submodule remote／HEAD 可觀測；無完整 executable trust 保證 |
| Python | 執行官方導入／檢查 | 外層使用絕對路徑 C:/Users/daish/AppData/Local/Programs/Python/Python312/python.exe；環境未隔離 | interpreter 版本與 SHA256 記錄於 evidence；digest inventory 不等於已驗證 trusted bytes |
| tool 內部 Git | 官方工具 subprocess | 仍使用 ambient git resolution | adopt_governance.py 的 subprocess 使用 git 名稱，未 harden upstream |

結論：ambient executable trust root remains。這次不宣稱 security boundary，未進行 adversarial trust tests，也未修改 framework。

## 本次檢查結果

- drift：ok=True、severity=warning；唯一 warning 為 baseline source_commit=unknown，原因是 parent repo 沒有 commit。framework pin 另有 lock 與 submodule HEAD 可追溯。
- external_repo_readiness：ready=True，但 governance_drift_clean=False、hooks_ready=False。ready 是該工具的有限判定，不能當完整治理 PASS。
- quickstart smoke：ok=False；pre_task_ok=True；session_start 被 version_compatibility_unsupported 阻擋，缺 .governance/version_manifest.yaml。保留失敗，不複製未實際安裝的 hook/version 宣告來製造 PASS。
- memory_workflow --check --run-guard：無 blocking item；canonical writer／authority guard 路徑發現為 NOT FOUND。guard 已由 dispatcher 內部 import 執行，但沒有本機 hook routing，不能宣稱完整記憶接線／canonical closeout。
- Git staged／tracked diff whitespace checks 無錯；framework working tree 保持乾淨。產品／iOS／G1～G4 尚未執行。
- 最新機器狀態見 .governance/evidence/adoption-summary.json；人類可讀表見 adoption-summary.log。

此任務結束不代表 session end；未執行 session closeout，也未產生 daily session record。


## G0 Owner Decision — 2026-10-04

Planning / Governance baseline READY；App implementation NOT STARTED（freeze 時）。使用者授權 G0 純治理提交後直接進 BL-001。Runtime smoke／hooks／domain validator／memory workflow 為 KNOWN DEBT、非 BL-001 blocker；不要求先補治理自動化。
移除 runtime debt 的條件為後續明確接線／驗證需求，不為解除 App 開發的人造 blocker 而擴張治理。
G0 的靜態完整性／framework pin／乾淨工作樹需驗證；App build／launch／UI tests 則依 BL-001 done gate 獨立驗收。
