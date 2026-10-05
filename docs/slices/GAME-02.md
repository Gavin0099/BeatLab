# GAME-02 — A more inviting drum adventure

Outcome: IMPLEMENTED_AND_INSTALLED_WAITING_FOR_UNLOCK. Signed BeatLab 0.1.0 (5).
Installed in place; launch blocked by observed owner-phone lock. Final focused picker light (1) and maximum-text dark (2)
checks PASS, with prior three light PASS and unaffected maximum-text daily PASS
as composite evidence. See GAME-02-verification.json for source boundaries.
Child appeal and G1-G4 remain unaccepted.

Owner (2026-10-04): the installed game interface is insufficiently attractive
for children. Improve the native practice presentation and update the already
authorized owner-phone candidate. Risk L1, visual presentation only.

Allowed source: BeatLab/Views/PracticeView.swift (private SwiftUI illustration
types in the same file, no project changes); BeatLabUITests/PracticeUITests.swift
for observable scene/reward regression assertions; PLAN.md, README.md,
docs/verification.md, docs/mac-acceptance.md, docs/design/GAME-DESIGN.md,
docs/slices/GAME-02*, ignored TestResults/GAME-02/**.

Add a native illustrated drum companion, three chapter destinations, a winding
route, achievement stickers derived only from saved lesson stars, and an
expressive real-result presentation. Keep the existing ten lessons, chapter
selection, lock explanation, Home preparation, cancel, retry/save/discard,
large-text reflow and controls accessible. Decorative art is hidden from
accessibility and hit testing. No repeating animation, audio scheduling,
fake scores, new currencies, services, permissions or data fields. Respect
Reduce Motion on any appearance transitions.

Read-only authorities: PracticeStore, TapPad, RhythmLane, RootView, audio/DSP,
core matching/scoring/catalog/progress. Any authority change escalates to L2
and requires another contract. Never uninstall/reset data or change framework
pin/baseline/certificates. Preserve earlier changes and receipts.

Failure paths: no-input attempt earns no stars/stickers or unlock; locked
chapters remain viewable with disabled lesson buttons; save failure remains
explicit, no reward persistence claim; reduced motion uses a static result;
large text scrolls to reachable start/pad/stop without clipped labels.

Verification: build and run three existing practice UI flows with scene and
unearned-sticker assertions; repeat at maximum accessibility size/dark,
review native screenshots. Signed iphoneos build/source hash/signature/profile
checks, fresh paired-device inventory, install and launch receipts required.
Core/audio authority unchanged, so no repeated offline timing suite. Child
appeal is a design hypothesis requiring real playtest, not a test PASS claim.

Rollback: restore only PracticeView edits from TestResults/GAME-02/before/
and this slice's test changes; preserve GAME-01/MET-01. Phone downgrade is not
automatic. No PR/merge/TestFlight or G1-G4 acceptance claim.

Owner steering: inspect cat/robot/dinosaur art in english-vocab-trainer and
reuse it as game companions. Extend allowed files to five named imagesets
under BeatLab/Resources/Assets.xcassets/Adventure{Cat,CatCelebration,Robot,
Dinosaur,DinosaurCelebration}.imageset/** and
docs/design/game-character-sources.json. Import PNG bytes unchanged from
pinned private repository main via authenticated GitHub read APIs; record
commit/blob/hash provenance. Garden sources remain read-only.

Add a cosmetic companion picker with local view state (no persistence/schema
change). Cat/robot/dinosaur appear in welcome/scene/preparation/pad/result;
actual perfect/result states select their reaction, never change targeting,
star grading or locks. Existing drum illustration is a decorative fallback.
Verify picker changes selected label/character while progress and locks stay
unchanged; switching is idle-only and active practice uses the chosen partner.
All art is static PNG, not an imported skeletal/frame animation. Keep viewport
alignment and bounded but adequate scrolling in tests; retain failed attempts.

Picker repair: retained the interrupted maximum-text run (daily PASS, companion
selection FAIL, no-input canceled). Hierarchy showed the picker dinosaur card
ended at y=820 while the hidden underlying tab bar began at y=791; the harness
used the wrong viewport. Use the sheet's bounds and throw on exhausted reveal
to stop an async test promptly. Also shorten AX-only optional invitation copy
and give the whole card a content shape. Recheck the changed picker journey in
normal light and maximum-text dark, plus no-input result at maximum text. The
unchanged daily path's preceding maximum-text PASS is retained as composite
evidence; do not describe this as one final three-test dark suite.
