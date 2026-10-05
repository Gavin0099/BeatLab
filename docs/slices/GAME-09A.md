# GAME-09A — 已判定輸入的短音效

狀態：IN_PROGRESS；來源／本機工程檢查通過，真機與 owner 接受待驗。L2，依賴 UI 工程 checkpoint 8bd9453 與 GAME-09 既有 loop。Owner 已要求聽拍→預判→操作→立即視覺／聲音回饋，並要求繼續到 public；本片只補該聲音，不新增玩法／模式／課程／角色。

Allowed files：`BeatLab/Audio/MetronomeAudio.swift` 的可選 practice feedback player／預先合成 buffers／start-stop-gain cleanup；`BeatLab/App/PracticeStore.swift` 的開始時啟用與已判定 tap 後發聲、取消／結束清理 weak audio reference；`BeatLabTests/MetronomeAudioTests.swift`、`PracticeStoreTests.swift` 的 PCM／實際 graph／lifecycle／integration fixtures；必要時 `BeatLabUITests/PracticeUITests.swift` 的既有真實 touch regression；本契約／verification、PLAN、README、runner-layout／public-release-plan／store draft；ignored TestResults/GAME-09A。不增加 project membership。

Milestone companion boundary：canonical memory writer 的 daily／active-task-summary 追加、`artifacts/evidence/test-results/GAME-09A-regression.json` 與同名 `.txt`。Receipt writer 實際讀取 native regression xcresult、檢查失敗數與 source manifest 後生成收據，绑定新的 App commit；不把歷史證據移位或改寫為本輪測試。
Forbidden：Sources／DSP／matching／targets／判分／星星／保存 schema／catalog／TapPad／輸入 timestamp／audibleEpoch／latency estimate／transport clock formulas；從動畫或 UI Timer 排聲音；新配樂／count-in 規則／選項／權限／服務；改 icon／bundle／build；強推／PR／merge／公開 beta／App Store submission。

機制：練習（非校正）建立另一個 AVAudioPlayerNode，使用 route sample rate 的 mono PCM buffers，在 graph.start 前完成所有合成與配置。自由節拍器／校正維持原 graph 路徑。PracticeStore 先使用原 TimingSession 判定，再立即提交短 feedback；音效不是 target cue／第二次 timing 要求，也不參與 grade。Perfect 為短亮音，Early/Late 為較輕提示，Extra 為短低音；Miss 使用既有視覺恢復，不从 View deadline 排聲音。

Budget／獨立驗證 invariant：buffers duration <= 50ms、finite mono samples、peak <=0.14、起末為零；支援 8k–192k rate，非法輸入不產生 buffer。播放重覆使用 immutable buffer、interrupts 替換上一個 effect，避免高密度／快速連點堆長 queue；不分配於自訂 C render callback。gain 跟隨既有 App volume，volume0 聲音靜音但 transport 不重設；不增 loudness／精度宣稱。

Failure paths：buffer/route 不適用、graph 尚未開始／已停止、rapid taps／多打、gain0、取消／結束／背景／中斷／route reset、十關／校正混用。Optional effect prepare 失敗保持 cue 路徑可用；既有 graph route failure 安全停止。所有 stop path 清除 effect buffer queue，下一輪不播上一輪聲音。

Checks：同一音效 component 的 AVAudioEngine offline render 驗有效輸出、silence／drain／interrupt、rate／長度／taper／peak；實際完整 metronome+feedback graph audible clock、快速輸入、不停 transport、背景／中斷／route reset、重開及 volume0。PracticeStore 真實 target 判定後才 feedback、校正禁用；core／DSP authority hash 保持不變。重跑 App/store 與实际 UIKit matched/extra/restart／zero-input UI。不得只用「方法被呼叫」當聲音證據。

真機 gate：固定 route／OS／build，外部 capture 核對新增音效不遮蔽節拍、音畫/input/frame pacing 無 regression；sound onset 的實際 touch-to-feedback latency 量測另列，未測即 NOT RUN。Simulator/offline 不證明硬體 precision／兒童吸引力。iPhone目前 unavailable；這不阻擋來源與本機測試，但阻擋 public gate 接受。

Rollback：還原本片兩個 production file 與對應 tests／文件，回到已驗證 UI checkpoint；不重設進度、settings、已分發 build10或 framework pin。
