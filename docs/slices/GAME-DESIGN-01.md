# GAME-DESIGN-01 — Rhythm quest design

Owner request: design game-like practice after choosing the recommended
rhythm-quest direction. This is a design-only slice, risk L0; native navigation
and scoring implementation are not changed by the prototype.

Allowed: docs/design/beatlab-rhythm-quest.html, docs/design/GAME-DESIGN.md,
docs/design/game-design-verification.json, docs/slices/GAME-DESIGN-01.md,
PLAN.md, ignored TestResults/GAME-DESIGN/**. Preserve all prior uncommitted work.
Forbidden: native App/Core/DSP/test source, settings/progress payloads, microphone,
MIDI, accounts, release upload, framework/baseline edits, installing the design
as if it were a native App update.

Design contract: warm white/purple instrument feel; local course selection,
4-beat count-in, four-bar challenge, large drum pad, explicit R/L/rest, real
lesson names and patterns, pass/retry/unsaved/final-course result views. Compare
journey and studio selection layouts. No combo scoring, health penalty,
currency, daily streak or unrelated economy. Accent settings and current beat
remain different concepts. Native integration must reuse audio-clock targets,
existing matching/grade/star rules and save-before-unlock behavior.

Prototype boundary: silent visual animation and reviewed illustrative progress
and results, clearly labeled as a design preview. Tap demonstrates feedback;
it does not measure input precision or derive a true grade. No audio, network,
UserDefaults writes or claims of native rendering. Reduced Motion suppresses
decorative transitions while stable beat highlighting remains. Keyboard, narrow
width, large text, light/dark and screen-reader names are explicit requirements.

Verification: browser execute primary navigation/count-in/cancel/tap/result,
course locks and unsaved recovery, local visual controls; inspect screenshots
and overflow/target sizes at 320/390/736px and light/dark/large/reduced-motion.
Expected courses/patterns come from existing lessons.json; example stars are
reviewed fixtures of the existing rules, never a fake production result.

Rollback: remove only these new design files and their PLAN entry. Existing
candidate 0.1.0 (3), its phone-install blocker and G1-G4 gates stay pending.
