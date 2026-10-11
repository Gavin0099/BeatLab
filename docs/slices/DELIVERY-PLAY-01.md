# DELIVERY-PLAY-01 — 新原型簽署包與Wi-Fi交付

Status: DEFINED / NOT IMPLEMENTED。Risk: L1。Dependencies: 每個當次candidate本機gates；真正pause另需CONTROL gate。
總契約：[RHYTHM-PLAY-01](RHYTHM-PLAY-01.md)；本機與真機/兒童gate分開。
本次只寫規格；以下allowed是未來本片實作界線，並非source已改。

## 行為與UI

A/B分階段可交付，每個candidate有獨立ID、source commit、完整inputs SHA256、版本/build/configuration、原始測試與簽署包manifest。App metadata改號只限此片，不能與TestFlight舊13混淆。建置／測試全在本機，簽署包留durable原路徑，先驗SOURCE/包/profile/device/resource，再Wi-Fi原地安裝及單獨啟動。

## Allowed files

BeatLab.xcodeproj/project.pbxproj（version/build only）；docs/verification.md；PLAN.md；本片verification JSON、canonical memory/evidence；TestResults/DELIVERY-PLAY-01/<candidate-id>完整新build/app/manifest/install/launch原始檔。
此md、當片verification JSON、PLAN/verification、canonical memory/evidence與
TestResults/DELIVERY-PLAY-01亦可用於記錄本片。加入新檔只增當片必要引用，不改發布設定。

## Forbidden

App功能改動、改歷史PhoneFrozenmanifest或receipt、重建稱為原包恢復、手機reset/fixture/uninstall、TestFlight/public/PR/merge、Github Mac、未核對source直接裝最新輸出。
所有片均不含Apple上傳/PR/merge。保持既有來源、失敗與原型/正式進度隔離。

## Failure paths

簽署失效／device不在profile、未paired/lock/noWiFi、source/asset/catalog差異、install成功launch失敗混寫、清理誤刪frozen app、DEBUG結果被稱Release。缺包記錄FAIL不可只留hash後稱bytes已驗證。

## Checks / gate

當次實際code/build/sourcehash、signature/provision/profileexpiry、compiled icon/privacy/catalog/既有角色素材；fresh device transport localNetwork與identity、install与launch各自exit/outcome。交付後再次查包bytes仍存在并match；只清本task可再生intermediates，不刪frozen/manifest/raw。手機timing/FPS與兒童試玩另引用QA，不以安裝成功代替。
所需實際checks未跑標NOT RUN；模擬器不證明physical timing/FPS或兒童接受。
UI片皆檢視原尺寸PNG，大小字/Light/Dark/Reduce Motion/VoiceOver按改動驗。

## Rollback

保留candidate與失敗證據；手機如需回裝僅用另已核對的已授權候選，原包不存在不可偽稱回裝。
未接受之前不取代正式旅程；不要回退或清空owner已保存進度。
