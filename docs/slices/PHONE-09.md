# PHONE-09 — Reinstall current GAME-24 candidate over Wi-Fi

Owner explicitly requests installation on the same Wi-Fi on 2026-10-09.
Reuse PHONE-08 signed Debug0.1.0(13), GAME-24 source2a77e49. The 2026-10-09
motion review changed documentation only; inter-jump motion is not fixed.

Allowed: current source/artifact/signature/profile/compiled-assets verification,
fresh paired-iPhone discovery, in-place installation and launch, ignored
TestResults/PHONE-09 receipts, this contract/verification, PLAN and canonical
evidence/memory. Dependency: matching107 inputs and frozen signed iphoneos app.
Forbidden: App/assets/version/audio/scoring/save changes, rebuild for docs-only
changes, uninstall/reset, certificate changes, GitHub Mac runs, TestFlight/public
upload, other-level work, protected governance changes. Preserve bundle/team/data.

Failure paths: reject source/artifact/profile mismatch; resume ongoing commands,
do not duplicate installs. Record install and launch separately. Locked requires
unlock and launch-only retry; connection/trust requires concrete diagnosis.
Checks: current source107/frozen manifest/signature/device profile/asset entries,
fresh localNetwork connection and successful devicectl receipts. Existing native
tests suffice for unchanged source. Installation does not accept motion/timing/FPS
or first-level/public readiness. Rollback docs only; restoring app needs owner
direction and must preserve learner data.
