# 既有十關的續作規格（NIGHT-01）

Owner授權按現有catalog推進；下表保留原始依賴規劃，後方另列實際來源進度。不得改lesson JSON/門檻以迎合動畫；工程通過不代表手機或兒童接受。

| 關卡 | 既有BPM／節奏 | 遊戲練習重點 | 工程依賴與Gate |
|---|---|---|---|
| 1 · first-beat | 60 BPM · R,R,R,R（每拍1格，4小節） | 右手每拍跳一次 | GAME25已本機通過、第一關physical接受pending |
| 2 · quarter-hands | 65 BPM · R,L,R,L（每拍1格，4小節） | 右左接力每拍跳 | GAME26 dual-pad +65BPM；保存失敗不能解鎖 |
| 3 · eighth | 60 BPM · R,R,R,R,R,R,R,R（每拍2格，4小節） | 一拍兩次交接 | 密拍動作銜接／超過16目標場景pool／actual step clock |
| 4 · eighth-hands | 65 BPM · R,L,R,L,R,L,R,L（每拍2格，4小節） | 右左半拍交接 | 密拍動作銜接／超過16目標場景pool／actual step clock |
| 5 · quarter-rest | 70 BPM · R,-,R,-（每拍1格，4小節） | 空拍站穩等待 | 休止cue不生成target；extra/miss與gap銜接 |
| 6 · eighth-rest | 70 BPM · R,L,-,R,-,L,R,-（每拍2格，4小節） | 右左與休止混合 | 休止cue不生成target；extra/miss與gap銜接 |
| 7 · sixteenth | 60 BPM · R,R,R,R,R,R,R,R,R,R,R,R,R,R,R,R（每拍4格，4小節） | 四分格連續踏跳 | 快速連續輸入／高密cue／adaptive呈現，authority不變 |
| 8 · sixteenth-hands | 65 BPM · R,L,R,L,R,L,R,L,R,L,R,L,R,L,R,L（每拍4格，4小節） | 右左快速接力 | 快速連續輸入／高密cue／adaptive呈現，authority不變 |
| 9 · offbeat | 75 BPM · -,R,-,L,-,R,-,L（每拍2格，4小節） | 聽大拍、等反拍再跳 | 休止cue不生成target；extra/miss與gap銜接 |
| 10 · mixed | 70 BPM · R,L,-,R,-,L,R,L,-,R,-,L,R,-,L,-（每拍4格，4小節） | 整合右左與留白 | 快速連續輸入／高密cue／adaptive呈現，authority不變 |

優先拆出密拍呈現與休止呈現兩種新行為，再加入依賴已驗證行為的關卡。
未完成關卡仍保留既有generic runner；不靠直接放寬profile把unsupported遊戲當完成。
需要手別偵測、更多素材/故事/獎勵或新模式皆留owner決策，不加入本批。

本機來源進度（原有十關，未新增catalog內容）：

| Slice | 已落地的範圍 | 工程證據 | 仍待驗收 |
|---|---|---|---|
| GAME-26 | 第二關65BPM右左接力與雙觸控區 | [來源驗證](GAME-26-verification.json) | 手機體感、手別只是指引 |
| GAME-27 | 第三、四關半拍密度、連續動作與32目標路徑 | [來源驗證](GAME-27-verification.json) | 真機密拍觸控／掉幀 |
| GAME-28 | 遊戲固定可視範圍、結果與底部分頁距離 | [來源驗證](GAME-28-verification.json) | 手機尺寸與完整Accessibility |
| GAME-29 | 第五、六、九關休止與反拍；休止不生成目標 | [來源驗證](GAME-29-verification.json) | 孩子是否理解留白與反拍 |
| GAME-30 | 第七、八、十關64／64／40目標與四格提示 | [來源驗證](GAME-30-verification.json) | 真機高密度流暢度 |
| GAME-31 | 結束保留真實抵達數與位置，有限動作收尾 | [來源驗證](GAME-31-verification.json) | 第一關完整試玩接受 |

QA-NIGHT-01整合回歸與PHONE-10手機候選仍各有自己的Gate；不能把上表
工程證據相加當作一輪完整測試或公開上架驗收。其他關卡目前使用原有大拍
click與實際輸入回饋，完整半拍／四格示範聲音尚未新增；需另開音訊slice。
