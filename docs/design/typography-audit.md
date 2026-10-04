# Typography audit — design reference

Scope: docs/design/interface-preview.html; native type choices reviewed at source, Apple rendering pending. Font/size/punctuation/spacing/hierarchy/layout/numeral/brand-color signals reviewed; no bundled fonts or distinct pairings.

- docs/design/interface-preview.html: ✓ pass for system fallback / `font-synthesis:none`, regular body weight, unitless 1.5 body leading and 1.3 headline leading, constrained measure, no text-transform tricks, tabular tempo/statistics, measured light/dark text pairs.
- Native system Dynamic Type and monospacedDigit/rounded type match the same hierarchy; source review only. No font-loading or native typography-performance claim.

Remaining findings: 0 CRITICAL, 0 HIGH, 0 MEDIUM, 0 LOW within the reviewed reference scope. This is a focused manual review backed by rendered reference and contrast checks, not execution of all 78 rules or native font rendering approval.
