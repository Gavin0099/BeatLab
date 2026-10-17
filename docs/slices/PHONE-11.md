# PHONE-11 — 鼓手版本機簽署手機候選準備

2026-10-17 heartbeat要求接續可獨立完成的已授權工作。依既有本機建置／手機
測試授權，先把QA-REVALIDATE-01已驗證的鼓手來源建成iphoneos Debug候選。
本片只準備候選，不自動安裝尚待owner試玩的新玩法，不發行Apple。

風險L1交付：不修改產品或domain。依賴新Core59／原生13／UI3／Dark1重跑
及407檔雙份留存仍符合原SHA-256；來源產品等同cc6f5e7。
Allowed：本契約／verification、PLAN、canonical memory、tracked
artifacts/evidence/phone/20261017/的指令／核對／hash（不得含profile或憑證），
ignored artifacts/development/PHONE-11/的source／build／簽署包／原始device
inventory；另存 ~/Library/Application Support/BeatLabEvidence/PHONE-11-20261017。
Forbidden：產品／測試／素材／舊receipt／治理pin／手機資料；安裝／launch／
reset／trust改動／上傳／PR／merge；撤銷或重建cert、改bundle ID／team以繞過錯誤。

Verify plan：
1. 核對407檔兩份副本、git local／remote及root來源；凍結相同116輸入。
2. 原com.gavin0099.beatlab／P358EB3X9H，本機generic iOS Debug build。
   僅command override CURRENT_PROJECT_VERSION=15以分辨新候選；不改root project。
3. 實際signed iphoneos／0.1.0(15)／DEBUG入口與Swift define、codesign verify，
   profile／entitlements team、application-id／到期／development授權核對。
   依fresh device inventory，在可連線時核對owner UDID coverage；無法讀取時
   明列NOT VERIFIED，不猜UDID或把配對清單當安裝成功。
4. compiled catalog／privacy／icon與來源或新simulator元件比較，輸入hash一致，
   原地更新bundle與資料schema不變。手機上執行、timing/FPS不在本片宣稱範圍。
5. frozen簽署包與ZIP逐檔hash、副本第二位置核對；profile只留local，metadata
   只含必要判斷及hash。失敗不覆寫，實際缺account／keychain才請owner處理。

Rollback：無產品改動，只回退狀態文件；保留失敗／candidate，不能替代舊14包。
Status：SIGNED_CANDIDATE_PREPARED_NOT_INSTALLED；本片候選準備完成，
安裝／玩法／真機效能仍未接受。

## 本機實際證據

- source116輸入與root／git f1f9a65／新QA來源相同；本機Debug iphoneos build
  exit0，0.1.0(15)，只command override build號，沒有產品／測試修改。
- codesign --verify --deep --strict exit0；原bundle／team，development
  profile／entitlements／有效期符合。fresh配對inventory的owner UDID在profile。
- DEBUG編譯旗標與第三關試玩入口確認；未注入UI-test suite／seed。catalog／
  privacy等於來源，兩個AppIcon bytes等於先前已選定icon。
- 13檔Frozen簽署App、ZIP內容及副本核對；148個新批次檔在第二位置SHA相同。
  profiles／原始device inventory只留local，Git保留必要判斷及hash。
- fresh inventory顯示paired、tunnel disconnected；沒有安裝或啟動嘗試，
  不把這個狀態稱為已確認的安裝阻擋，也不推斷手機鎖定或目前正在使用的版本。
- 新QA的Core59／原生13／UI3／Dark1使用相同產品來源，兩份407檔今日hash
  仍一致；本輪沒有重跑這些測試，也沒有完整十關／手機timing驗收。
- [候選receipt](PHONE-11-verification.json)。下一步是實際Wi-Fi交付及owner
  鼓手／runner比較；此包不是原14版的恢復，也沒有TestFlight/public發行。
