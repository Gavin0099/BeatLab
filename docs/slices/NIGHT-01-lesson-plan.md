# 既有十關的續作規格（NIGHT-01）

Owner授權按現有catalog推進；本表是依賴規劃，不宣稱已實作或physical接受。不得改lesson JSON/門檻以迎合動畫。

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
