# MAC-01 — First Apple build and owner iPhone installation

Owner authorization (2026-10-04): build BeatLab and install it on the owner's
paired iPhone; the same Wi-Fi may be used. 字樹花園's installation, UI/UX,
testing and release workflows may inform BeatLab's process.

## Contract

- Risk: L1 for build/signing/installation; no audio, scoring or persistence
  behavior changes are planned. Any discovered behavior fix needs its own
  scope, failure paths and applicable tests before editing.
- Allowed files: `.gitignore`, `PLAN.md`, `docs/mac-acceptance.md`,
  `docs/release-checklist.csv`, `docs/slices/MAC-01.md`,
  `docs/slices/MAC-01-verification.json`; ignored `TestResults/**`, `Build/**`
  and `DerivedData/**` hold generated builds and receipts.
- Forbidden: app/domain/DSP changes without a defined fix; protected baseline
  or framework changes; deleting phone data; reusing 字樹花園's bundle ID or
  profile; certificate revocation; PR, merge or TestFlight upload.
- Dependencies: existing MVP/UIUX source at `12587401aa989663098aba605ef800648f175633`,
  Xcode, valid personal development signing and the paired owner iPhone.
- Verification: SwiftPM tests, actual C renderer matrix, capture analyzer tests,
  simulator build/App tests, iphoneos build and signature/profile inspection,
  installation receipt and launch receipt. Interrupted/stalled App tests are
  not PASS. Installation/launch do not establish timing, usability or release
  acceptance.
- Failure paths: compiler/test errors, unavailable simulator, missing account
  or profile, inaccessible/locked phone, unsupported developer services,
  installation or launch rejection. Preserve each actual failure log; request
  only the owner action necessary to resolve the blocker.
- Rollback: stop a failed build/install attempt; preserve app data and existing
  credentials. Documentation and ignore changes are independently reversible.
  Do not uninstall another app or reset the phone.

## Evidence

The machine has Xcode 26.6 (17F113), Swift 6.3.3. Raw first-run evidence is
under `TestResults/20261004T094443Z/`. The iOS 18.0 simulator test attempt stalled
before executing tests and was interrupted; an iOS 26.5 attempt follows.
Final outcomes and claim boundaries will be recorded in
`docs/slices/MAC-01-verification.json`.
