---
name: fix
model: inherit
effort: high
agents: [explorer, implementer]
description: >
  Use to fix a reported bug spec-first: reproduce it, trace the symptom to the owning feature's
  acceptance criteria, apply the minimal fix, check it in the running game plus the smoke check
  implement uses, then patch the spec so the bug class can't silently return.
  Triggers on "fix {bug}", "fix the bug in {slug}", "bug in {feature}", "/fix {slug}",
  "regression in {slug}", "полагодь баг", "виправ багу", "регресія в {slug}", "чому зламалось".
  Triage is three-way: AC exists and is violated (regression) / AC is ambiguous (spec-bug —
  patch the wording) / no AC covers it (gap — add one, marked added-by-fix). Works on a repo
  with no specs at all (soft mode — code-first, recommends survey after). Writes a fix record
  under docs/features/{slug}/_fixes/ and commits the fix (SDD-Fix trailer), the record and any
  spec patch as separate commits.
---

# Skill: fix

The **bugfix entry point** — the backbone in miniature, sized for «it's broken», not «build a feature». A bug is treated as **evidence about the spec**, not only about the code: either an acceptance criterion is violated (the code regressed), the AC was ambiguous enough to permit the behaviour (the spec is the root cause), or nothing covers it (a gap). So the fix always lands in two places — the **code** (a minimal fix, checked in the running game plus the smoke check `implement` runs) and the **spec** (a surgical AC patch) — tied together by a small fix record.

This skill keeps only its own machinery. Question phrasing → [`../_shared/ask-style.md`](../_shared/ask-style.md); dispatch policy → [`../_shared/agent-roster.md`](../_shared/agent-roster.md).


## Owner

The parent (solo maintainer). Triage that lands on «spec-bug» or «gap» changes an AC, which is a game-design decision, so it is always confirmed.

## Inputs

- `<slug>` — optional; pass it when you know which feature owns the bug, otherwise step 2 finds it from the symptom.
- The bug report, in any form: what the child or parent saw, a Godot error from the log, a screenshot, a `/playtest` finding.
- **Soft gate (never hard-refuse):** `docs/features/` with ≥1 `spec.md`. Absent (a brownfield repo that never ran the backbone) → still run, in **no-spec mode**: steps 1 → 3 → 4 → record, skip the spec patch, and recommend `/survey` in the handoff.
- (Optional) `.claude/sdd.local.md` — gate command overrides; otherwise the commands are detected per `implement`'s cascade.

No depth dial and no `.size` here — a fix is one size, and the interview is the bug report itself.

## Protocol

1. **Intake — reproduce before touching anything.** At most 1–2 `AskUserQuestion` (phrasing per [`../_shared/ask-style.md`](../_shared/ask-style.md)), only for what the report doesn't already say: expected vs actual, the steps, the scope (every time? only after a save reload? since which build?). Outcome: a one-line reproduction statement — «doing X, expected Y, got Z». A bug you can't state this way isn't ready to fix.
2. **Trace to spec (triage).** Grep `docs/features/*/spec.md` (+ the candidate slug's `_fixes/` for a recurrence) for the reproduction's domain terms; locate the owning slug and the closest §5 AC. In parallel, dispatch [`explorer`](../../agents/explorer.md) — `subagent_type: "explorer"` (fallback `Explore` / inline per [`../_shared/agent-roster.md`](../_shared/agent-roster.md)) — to localize the code path. Three outcomes (decision table → [`./references/triage.md`](./references/triage.md)):
   - **(a) Regression** — an AC describes the expected behaviour and the code violates it. The spec is right; only the code changes.
   - **(b) Spec-bug** — the AC exists but a reasonable implementer could read it and produce the observed behaviour. The wording is the root cause — the AC gets patched (with the user, step 5).
   - **(c) Gap** — no AC covers the behaviour. A new AC is added to §5, marked `<!-- added-by-fix: <date> -->`.
   - **No-spec mode** — no `docs/features/` (or no spec plausibly owns the symptom): skip the spec patch, say so in the record, recommend `survey`.
3. **Reproduce in the game.** Run the scene (or the build) and confirm the reproduction statement. No test is written; a GUT test is added only for a save or migration bug, where a fixture save is the cheapest proof.
4. **Minimal fix + smoke.** Make the smallest change inline (or dispatch [`implementer`](../../agents/implementer.md) for a larger one); **no drive-by refactors** (anything the fix exposes goes to the record's follow-ups). Then the smoke check (headless import, no script errors; commands → [`../implement/references/command-detection.md`](../implement/references/command-detection.md)) and re-run the reproduction in the game: the bug is gone.
5. **Spec patch + fix record.** Apply the step-2 branch — (a) nothing to patch, re-verify the AC; (b) patch the AC wording; (c) add the new AC with the marker. **Any spec change is confirmed with the user** in one `AskUserQuestion` (before/after wording shown). Then write `docs/features/<slug>/_fixes/<date>-<short-slug>.md` from [`./templates/fix-record.md`](./templates/fix-record.md): symptom → root cause → how it was checked → the spec patch (or why there is none).
6. **Commit + handoff.** With the GATE green (this skill's structural self-check), commit per [`../_shared/write-and-commit.md`](../_shared/write-and-commit.md) — separate commits: the code fix as `fix: <slug> <short summary>` with trailers `SDD-Fix: <date>-<short-slug>` and `SDD-AC: <id>` (when an AC was traced); the record as `fix: <slug> record <date>-<short-slug>`; the spec patch (if any) as `fix: <slug> spec.md <AC id>`. Script errors in the smoke check → no commits. Then **emit the stage-handoff block** per [`../_shared/handoff.md`](../_shared/handoff.md) (utility variant — `/clear` optional): *What I did* (incl. the commits with short SHAs) + *Review* (the diff, `_fixes/<date>-<short-slug>.md`, the spec patch if any) + *Run next*: resume what you were doing; **when the fix touched >5 files, crossed a system boundary, or touched save or word-DB code, recommend `/review <slug>`** — a recommendation, not a gate.

## Definition of Done

- The bug was reproduced in the game before the fix and is gone after it.
- The smoke check is clean (headless import, no script errors).
- The triage outcome is explicit — regression / spec-bug / gap / no-spec — and the matching spec patch is applied (or its absence explained in the record).
- `docs/features/<slug>/_fixes/<date>-<short-slug>.md` exists: symptom, root cause, how it was checked, the spec patch, follow-ups.
- The commit carries the `SDD-Fix:` trailer (+ `SDD-AC:` when traced); any spec change was user-confirmed.
- The in-game re-check + the smoke check are this skill's **structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)); its result is reported in the handoff.

## Anti-patterns

- **Fixing without reproducing.** «It works now» without having seen it fail first is a guess.
- **Patching code when the spec was the bug.** If the AC permitted the behaviour, the wording is the root cause; leave it unpatched and the next implementation reintroduces the bug legally.
- **Silent spec edits.** Every AC patch/addition is confirmed with the user — the spec is a contract, not a scratchpad.
- **Drive-by refactoring.** The fix commit is minimal; refactors the fix exposed go to the record's follow-ups, not into the same diff.
- **Skipping the smoke check because the change is «one line».** One-line fixes break scripts just fine.
- **Hard-refusing on a repo without specs.** A brownfield bug is this skill's front door — degrade to no-spec mode and recommend `survey`, never block.
- **Ignoring a recurrence.** When `_fixes/` shows the same symptom was fixed before, read the old record and fix the root cause this time.

## References & template

- [`./references/triage.md`](./references/triage.md) — the symptom→spec trace: grep strategy, the regression / spec-bug / gap decision table, the `added-by-fix` marker, no-spec mode, the recurrence check.
- [`./templates/fix-record.md`](./templates/fix-record.md) — the fix-record scaffold (symptom → root cause → how it was checked → spec patch → follow-ups).
- [`../implement/references/command-detection.md`](../implement/references/command-detection.md) — how the step-4 smoke commands are resolved (settings override → architecture-map keys → Godot defaults).
- [`../_shared/ask-style.md`](../_shared/ask-style.md) · [`../_shared/agent-roster.md`](../_shared/agent-roster.md) · [`../_shared/handoff.md`](../_shared/handoff.md).

## Example invocation

> **User:** «/fix — after the colours chapter the stars reset to zero when we reopen the game»
> **Skill:** intake confirms: expected 3 stars kept after restart, got 0, every time since the save-format v2 build. Trace: `docs/features/colours-chapter/spec.md` AC-06 says «stars earned in a chapter are still there the next day» → **regression**. `explorer` finds `migrate_v1_to_v2` drops `chapter_stars`. A save bug, so a small GUT test loads `tests/fixtures/saves/v1.json` and checks 3 stars after migration (fails before). Fix: copy the field in the migration; smoke clean, stars kept in the game. Record `_fixes/2026-12-03-stars-lost-on-migrate.md`; commit with `SDD-Fix:` / `SDD-AC: AC-06`. Save code touched → recommends `/review colours-chapter`.
