# GAME-24 — 第一關掉落表情

Owner 2026-10-08 已接受 build13 掉落動作，但要求表情跟著改；目前只有第一關做好，預設10關。第一關尚未接受完整完成，後續九關等第一關完成才開始排slice。

Risk L1: presentation only，沿用GAME23 recovery.phase/pose，不改clock/matching/score。Dependencies TF06 build13 owner掉落motion acceptance、GAME22 dense atlas與GAME21 renderer。

Allowed: BeatLab/Views/EggMissionView.swift facial texture/mask/cache與read-only表情狀態；新增3個 Recovery*Expressions.imageset（保留original dense atlas字節）及expression provenance於docs；BeatLabTests/PracticeStoreTests.swift；此契約/verification、PLAN、docs/verification.md、canonical evidence/memory、ignored TestResults/GAME-24。
Forbidden: 已接受跳躍/下墜/承接/回平台位置曲線、duration、anchors/原PNG、audio/Core/input/PracticeStore/matching/score/save、關卡數目/關卡內容/unlock、UI重設、metadata/signing版本、GitHub Mac/PR/merge/public、擴展第2–10關。

Behavior: 正常保持原表情；漏拍下墜驚訝張口/眼睛睜大、接住閉眼緊張、托盤回平台先鬆氣再恢復。三角色用相同stage語意、維持原角色造型。僅替換face region，original body/pose/motion不变；preparing/completed/cancel/route missing不保留表情。Reduce Motion不加晃動/表情切換動畫，可讀的neutral miss。缺expression素材回original face。預載cache，frame不生成textures/nodes。

Checks: phase expression fixtures含邊界/invalid/repeated/reset/reduced/missing texture；GAME23既有curve/anchor/body texture與jump regression；本機App/Core、native三角色fall/catch/return/wait/light-dark/compact specimens、live callbacks/node count。工程通過不證明physicalFPS/timing/兒童體感。僅source/candidate可備，不在本片自動宣稱TF14。

Failure: 新表情face registration/色差不符，保留失敗素材並針對修正，不能用整張新body替換已接受motion。Rollback只revert facial code/new assets/test，保留build13與learner資料。Status DEFINED。
