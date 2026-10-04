# S0–S17 implementation batch

Owner explicitly selected the complete iOS MVP on 2026-10-04, with Mac acceptance after implementation. This authorizes M2–M4 source work ahead of G1; it does not accept G1/G2/G3/G4 or authorize publishing. All slices remain IN_PROGRESS until applicable tests and device gates pass.

Each slice below shares the allowed paths Sources/**, Tests/**, BeatLab/**, BeatLabTests/**, BeatLabUITests/**, Package.swift, BeatLab.xcodeproj/**, docs/**, PLAN.md, AGENTS.md and curated memory. Protected framework/baseline, external services, excluded features and deployment are forbidden.

| Slice | Boundary / dependency | Failure path / checks | Rollback |
|---|---|---|---|
| S6 voice (L2) | Pre-render Apple speech PCM before Start; C renderer owns onsets; click/voice/both. Voice eighths use 1 & 2 &; other subdivisions explicitly beat-only counting. | Missing/failed speech, timeout, stale task, route change; reject voice Start until assets ready. No realtime TTS; device intelligibility/onset pending. | Click mode |
| S7 lane (L1) | Versioned rhythm steps (R/L/rest); one pattern supplies lane and targets. | Empty/invalid/mismatched pattern rejected; rests generate no target. | Fixed quarter pattern |
| S8 tap (L2) | UIKit finger-down timestamp mapped to host epoch; nearest target with earlier tie; repeated closest target is extra, fixed 180 ms match window. | Nonfinite/outside/duplicate/extra/missed inputs; engine interruption cancels session. | No practice transport |
| S9 score (L2) | Signed error = input minus target minus calibration offset; ±50 ms Perfect; MAE/stddev/miss/extra distinct. Calibration route/rate bound. | Uncalibrated hides ms; calibration must meet spread/sample rules; no claim user offset is hardware-only. Tests use specified injected offsets. | Uncalibrated qualitative practice |
| S10 lessons (L1) | Versioned JSON resource decoded and validated outside UI; completion BPM/pattern/accuracy fixed. | Unknown schema, duplicate IDs, invalid durations/goals fail load visibly. | Disable lessons on load error |
| S11 10 lessons (L1) | Quarter → eighth → rests → sixteenth → R/L; full bar count-in. | Every lesson needs legal targets, walkthrough and child playtest pending. | Free practice |
| S12 progress (L2) | Versioned local envelope; stars/unlock/best BPM conditional on passing full-session hit/miss/extra criteria. | Corrupt recovery notice, future version blocks writes, restart tests; no migrations in v1. | Explicit reset only |
| S13 Gap (L2) | 4 audible bars then 1/2 silent; C transport/history continue. | Sample tests at mute/return, UI shows silent bar, device return test pending. | Disable gap |
| S14 Ladder (L2) | +5 every N complete bars, clamp 240; manual tempo exits. | Bar-boundary samples, gap combination, no gain clock effect; rapid control updates. | Disable ladder |
| S15 home (L1) | Today/continue derived from local next unlocked lesson; no identity/account. | Fresh/complete/corrupt/future states; navigation to lesson. | Metronome shortcut |
| S16 age UI (L1) | Manual Beginner/Standard; Beginner hides timing statistics and advanced controls. | Core target/score unchanged; Dynamic Type/VoiceOver pending. | Standard UI |
| S17 polish (L2) | Safe background stop, interruptions/routes, accessibility, release checklist. | Apple build/tests and fixed-device acceptance NOT RUN until Mac; no TestFlight upload. | Retain source; no release claim |

Calibration is a user alignment estimate based on paced taps, containing human bias; it does not establish independently measured touch/output hardware latency. Bluetooth routes are excluded from calibrated timing claims. Raw error data stays local. No microphone permission, MIDI, account, cloud, leaderboard or AI coach.
