# MET-01 — Reference metronome controls

Owner request (2026-10-04): implement the functionality shown in the supplied
metronome image. Working scope: its metronome controls, rather than the
separate tuner/song-list destinations. The owner may narrow or expand this
scope in the pending clarification.

## Contract before implementation

- Risk L2: per-beat output state, click timbre, audio mailbox and settings v1→v2
  migration; L1: tempo history and UI/cue presentation.
- Allowed: Sources/BeatLabCore/{MetronomeConfiguration,ConfigurationRepository,TapTempo}.swift;
  Sources/BeatLabDSP/BeatLabDSP.c and include/BeatLabDSP.h;
  BeatLab/{App/ConfigurationStore,Audio/MetronomeAudio,Views/MetronomeView,Views/BeatVisualizer,Views/ConfigurationSummary}.swift;
  existing files under Tests/BeatLabCoreTests, Tests/DSPKernelTests,
  BeatLabTests and BeatLabUITests; PLAN.md, README.md,
  docs/{slices/MET-01*,verification.md,mac-acceptance.md}; ignored TestResults/**.
- Forbidden: score/target/lesson/progress authority, microphone/MIDI, tuner,
  song library, new services, framework/baseline changes or release upload.
- Dependencies: current MVP and preserved MAC-01 work. App bundle remains
  com.beatlab.app; installation may reuse the owner's existing authorization.
- Behavior: tap each big-beat control cycles accent → normal → mute → accent.
  Muting suppresses that big beat's click/voice/subdivisions, with transport,
  beat history, Gap and Ladder advancing. Pattern changes apply atomically
  with meter at the next bar. Electronic/woodblock/mechanical synthesized PCM
  is prepared before rendering; timbre changes at a beat. 6/8 remains two big
  beats with three eighths each. Practice keeps its specified default pattern.
- Visual cues: pendulum derives phase from the audio snapshot. Optional screen
  pulse and haptic cues derive big-beat changes from that same snapshot, remain
  best-effort presentation (no precision claim), and never schedule audio.
  No camera flash or microphone permission. Reduce Motion suppresses moving
  pendulum/pulse; stable beat highlighting remains. Volume zero allows visual/
  haptic-only use. UI cue preferences default off.
- Tempo history: session-local undo/redo for successful tempo edits only;
  one slider gesture is one edit, new edits discard redo, invalid/failed writes
  do not change stacks. Undo/redo obey the existing boundary/ladder rule.
- Persistence: read v1 without rewriting; infer existing first-beat accent,
  default electronic timbre/cues off. Save v2 only on successful user edits;
  unknown versions block writes, invalid patterns recover as corrupt data.
- Failures/tests: invalid patterns/timbres, every meter, legacy decode,
  restart/roundtrip/future-version protection, undo/redo branches,
  partial/muted/all-muted render, bar-boundary changes, simultaneous meter/BPM,
  every timbre/subdivision and Gap/Ladder/Voice combinations. Independent
  sample onsets and nonzero/silent windows are the oracle. Swift tests,
  focused C harness+UBSan and long matrix; simulator build/tests and real-device
  build/install. Native visual, physical cues and changed output timing still
  need applicable device evidence; unavailable test services are not PASS.
- Rollback: revert only MET-01 edits; retain MAC-01 changes and prior receipts.
  Do not downgrade v2 by overwriting data with v1 code. Preserve phone data;
  previous app reinstall would require compatible settings handling.

UI reference: install-garden-on-iphone and garden-ios-ux skills; BeatLab's
own product, timing and accessibility contracts remain authoritative.

## Native verification follow-up (2026-10-04)

The owned simulator now boots after a shutdown/boot retry. Native App tests
execute. The first UI run observes `rhythmSettings` on the disclosure and its
child picker buttons, replacing `signaturePicker`/`subdivisionPicker`.
The correction is L1, limited to MetronomeView accessibility identifier scope
and existing UI tests/screenshot attachments. Preserve picker behavior and
audio/storage authority. Verify independent picker identifiers, shared settings
and relaunch persistence in native UI tests; rollback only this identifier
placement if native lookup fails. Retain the failed result bundle.
