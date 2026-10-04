# M1 — BL-002 through BL-006 source implementation

2026-10-04 owner direction: continue implementation, defer Mac tests until the batch is complete. This supersedes the requirement to stop implementation at BL-002A; BL-002A and G1 remain unexecuted acceptance gates, never implicit PASS.

Allowed: Sources/BeatLabDSP/**, Sources/BeatLabCore/**, Tests/**, BeatLab/Audio/**, BeatLab/App/**, BeatLab/Views/**, BeatLabTests/**, BeatLabUITests/**, Package.swift, Xcode project/scheme, docs/**, PLAN.md, repo policy and curated memory state. No submodule/protected baseline changes. Owner subsequently explicitly authorized all S0-S17 source work; see MVP-implementation.md.
Risk: L2 for audio kernel, boundaries and lifecycle; L1 for presentation/controls. No account, microphone, MIDI or scoring.

## Mechanism

Audio uses an AVAudioSourceNode feeding AVAudioEngine. A C11 kernel renders clicks in the audio callback, with precomputed click samples and allocation-free sample arithmetic. BPM changes anchor a new rational tempo segment at the next rendered beat, preserving phase. Subdivision changes at the next beat; meter/accent at the next bar. Meter-induced incompatible subdivision normalization waits for that meter's bar boundary. Latest desired state wins before a boundary.

Control mailbox and event history use lock-free atomics; initialization rejects unsupported platforms. UI does not generate clicks. Buffers already handed to hardware cannot be recalled: next boundary means the next unrendered engine boundary, with pending state shown until audible applied state is observed. UI frame refresh projects the audio host timestamp into the same sample timeline, with route latency as an estimate (not score calibration).

Start rebuilds the kernel with the persisted configuration and current route sample rate; Stop closes output and frees only after the engine/node is stopped/detached. Background, interruption, route/config changes and media reset stop safely; restart is explicit.

## Verification and rollback

Core tests: rational sample positions, live transitions, 6/8/subdivision compatibility, gain/silence, rapid requests, stop/restart state; Tap Tempo boundary/reset/outlier cases. Test actual C render code where a local compiler is available, not a Python reimplementation.
Mac: SwiftPM tests, build, App/store/UI tests, AVAudioEngine start/stop/interruption and BL-002A/G1 matrix. Visual sync remains unmeasured until device evidence. Offline samples do not prove audible hardware onset.
Source implementation never advances slices to DONE without their tests and device acceptance. Rollback returns to the BL-001 source shell; do not modify the frozen G0 framework pin.
