# Audio and practice timeline

Status: implemented in source, Apple verification pending. Risk L2.

AVAudioSourceNode calls a C11 renderer; the render callback never allocates, takes a lock, schedules a UI timer or invokes speech synthesis. Click PCM is prepared at creation. Apple speech PCM is prepared before Start via [AVSpeechSynthesizer.write](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/write(_:tobuffercallback:)), resampled and copied into the stopped C kernel. Voice onset trimming is an estimate; device intelligibility/onset still needs measurement. High tempo can truncate a word. Eight counts use 'and'; triplet/16th/compound voice counts only big beats.

Positions derive independently from an integer rational musical epoch, so rounding never accumulates. The audio callback reads one atomic desired-state packet at each beat. BPM/subdivision apply at the next unrendered beat; meter/accent at the next bar. A normalized subdivision that is incompatible with the current meter waits for the meter transition. Already rendered hardware buffers cannot be recalled; pending UI is based on audible history. Gain changes at a render buffer, independent of phase.

Gap suppresses the mixed output while transport/history continue. Ladder uses complete bars, adjusts BPM by five and anchors a new segment at the same sample. Manual BPM exits Ladder. Both modes are disabled during lessons and restored after completion/cancellation, so targets have one fixed tempo.

The node callback retains the kernel owner. Stop/detach release the graph before dropping the owner; an in-flight callback still retains valid C state. Notification handling switches to the main actor before graph destruction, following [Apple's configuration-change guidance](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/avaudioengineconfigurationchange). Route, interruption, background and media reset stop safely; restart is explicit. No background playback entitlement/mode.

UI projects [AVAudioTime host timestamps](https://developer.apple.com/documentation/avfaudio/avaudiotime) into rendered samples. UIKit finger-down time is mapped by the observed event age into that host domain. Targets derive from the validated pattern and audio sample-zero epoch; never from animation. Output latency for display is an estimate from the session, not independently measured onset.

Calibration is a paced-tap median with sample-count and spread checks, bound to route UID and sample rate. It includes human bias; exported data explicitly labels this estimate. Bluetooth cannot establish calibrated scoring. Beginner hides milliseconds. Standard displays milliseconds only after a valid user alignment, with its limitation stated. Independent hardware measurement remains G2 debt.

The nearest target wins, earlier on a tie. If already hit, the new tap is extra rather than moving to the next note. Rest produces no target. Passing uses perfect/total, hit/total and extra/total, preserving misses and preventing spam from passing. Best BPM updates only after a passing full session at that tempo.

No remote service, microphone, MIDI or identity is introduced. Versioned settings/progress retain future data and block writes until explicit reset.
