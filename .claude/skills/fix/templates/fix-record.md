---
slug: <slug>
date: <YYYY-MM-DD>
triage: <regression | spec-bug | gap | no-spec>
acs: [<AC-NN>]            # the AC(s) traced; empty list for no-spec
commit: <sha>             # filled after the fix commit lands
recurrence_of: <none | _fixes/<date>-<short>.md>
---

# Fix: <one-line symptom>

## Symptom

<!-- The reproduction statement from intake, verbatim: «doing X, expected Y, got Z».
     Plus scope: how often (every time / sometimes), since when (build, commit, date). -->

## Root cause

<!-- 2–4 sentences: the mechanism, the file:line, and why it slipped past the existing
     checks (which case nobody played?). -->

## How it was checked

<!-- How the bug was reproduced in the game before the fix, and re-checked after it (input used,
     scene, build). A GUT test only for a save/migration bug: name it. -->

## Spec patch

<!-- One of, per the triage branch:
     (a) regression: «none — spec was right; AC-NN re-verified»
     (b) spec-bug:   the AC wording, before → after
     (c) gap:        the new AC text added to §5 (with its added-by-fix marker)
     no-spec:        «no spec to patch — brownfield; survey recommended» -->

## Follow-ups

<!-- Refactors / adjacent risks the fix exposed but deliberately did NOT touch (the fix
     commit stays minimal) — each as one actionable line. Or «none». -->
