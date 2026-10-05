# PHONE-07 — Install runner candidate for owner trial

Owner explicitly requests installation of the reviewed GAME-07 build 7 on
2026-10-05. Reuse the existing signed iphoneos candidate; no source rebuild.

Allowed: fresh paired-iPhone discovery, artifact/source/signature/profile
verification, in-place installation and launch, ignored receipts and candidate
delivery fields, PHONE-07 evidence and current PLAN/README/verification status.
Preserve bundle/team/data. Native source/tests/assets/prototypes and protected
governance remain unchanged. No uninstall/reset/commit/push/release upload.

Failure paths: resume an ongoing command rather than duplicate installation;
record install/launch separately. Locked requires unlock and launch-only retry;
unavailable/trust/signing requires the actual connection or signing diagnosis.
Do not repeat an unchanged candidate's sufficient tests or regenerate signing.

Evidence: fresh devicectl JSON, source/artifact preflight and install/launch
receipts. Installation is delivery for trial, not design/child/timing/G1–G4 or
release acceptance. Roll back only this slice's docs; restoring an earlier
signed app in place needs an owner request and must preserve learner data.
