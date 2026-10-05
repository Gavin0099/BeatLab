# BRAND-01 — 拍拍冒險名稱與恐龍圖示

Owner selected concept A, 拍拍冒險 and its yellow-background jumping dinosaur.
Risk L0: branding and presentation text only; focused existing navigation checks retained.

Allowed files: project.pbxproj display name in Debug/Release; HomeView navigation title; PracticeStore future-version notice text; existing FoundationUITests brand expectations; AppIcon.appiconset/AppIcon.png; docs/design/branding original image and provenance; this slice/evidence; PLAN.md and README.md branding notes.
Forbidden: bundle identifier, product/scheme/module names, persistence keys/schema, audio/clock/matching/scoring, gameplay character artwork, protected governance files, App Store writes, upload/submission, phone installation.

Dependencies: owner-approved generated concept A. Preserve the original generated PNG; mechanically resample to the catalog's 1024-square opaque PNG without creative edits. Use a workspace copy for provenance.
Failure paths: missing source, incorrect dimensions/alpha, compiler/asset warnings, stale Home title/test expectation, changing app identity. Stop claims on failed checks.
Checks: catalog filename and dimensions/opacity; Debug/Release display-name and unchanged bundle ID; simulator build and existing FoundationUITests; launch/Home screenshot and built icon preview. This does not validate App Store name availability, trademark rights, physical timing or release gates.
Rollback: restore only this slice's paths from ignored TestResults/BRAND-01/before, remove only new branding/slice files, preserve all prior dirty work and learner data.

Result: simulator build and 2 existing FoundationUITests PASS; built display name, packaged icon and ready Home screenshot inspected. Owned simulator restored to Shutdown. Source manifest comparison against build 7 shows only HomeView, PracticeStore text and AppIcon changed among 52 entries; project display-name change separately validated in both configurations. Phone installation and store writes NOT RUN. Evidence: BRAND-01-verification.json.
