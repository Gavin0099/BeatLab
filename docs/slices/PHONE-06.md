# PHONE-06 — Install existing native candidate for owner trial

Owner explicitly requests installation on 2026-10-04 after rejecting browser
concept colors/gameplay. Install the existing signed BeatLab 0.1.0 (6) draft;
this request does not accept its gameplay or authorize a browser concept port.

Allowed: in-place owner-iPhone installation and one launch, ignored PHONE-06
receipts, existing BUILD delivery fields, this contract/evidence, PLAN/README
and verification delivery status. Native source, tests, browser concepts,
assets, protected governance files and learner data remain unchanged.

Dependencies/checks: fresh paired-iPhone inventory; recorded executable/assets
hashes; all 52 source hashes; signed iphoneos app, existing bundle/team and
owner provisioning coverage. Reuse the candidate without rebuilding.

Failure paths: record install and launch separately. If locked, request unlock
once and retry launch only; trust/signing/connectivity errors require concrete
diagnosis. Do not uninstall/reset, regenerate certificates, or poll indefinitely.

Evidence: devicectl JSON/logs plus artifact/source verification. Installation
and launch do not establish timing, gameplay appeal, child usability, G1–G4 or
release acceptance. No commit/push/PR/merge/TestFlight is part of this slice.

Rollback: revert only this slice's documentation; retain raw receipts. Restore
a previous signed candidate in place only on owner request; never erase data.
