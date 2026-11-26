---
name: implement
model: inherit
effort: medium
agents: [implementer, reviewer]
description: >
  Use to build a feature from its tasks.json, fast: one task at a time, in dependency order, the
  code written directly (inline, or by the implementer agent for a larger task), then the smoke
  check (headless import, no script errors) and a task-scoped commit with SDD-Task / SDD-AC
  trailers. No TDD loop and no mandatory tests: the real test is playing the build and the
  playtest with the child. Triggers on "implement {slug}", "build {slug}", "start coding {slug}",
  "/implement {slug}", "реалізуй {slug}", "почни кодити {slug}". Hard-refuses without tasks.json.
---

# Skill: implement

The build engine. This is a home-use game with no production, so speed wins: one task at a time,
in dependency order, each through `SELECT → BUILD → SMOKE → COMMIT`. Tests are **optional** —
write a GUT test only when it is cheaper than checking by hand (a save migration, a tricky rule
you'd otherwise re-check every session). The child's playtest is the real test.

## Inputs

- `<slug>`; **gate (hard refuse):** `docs/features/<slug>/tasks.json` → «run `/tasks <slug>` first».
  A `_scaffold` task set → redirect to `/scaffold`.
- Read the task file first → [`./references/inputs.md`](./references/inputs.md).
- Settings: `.claude/sdd.local.md` (created with defaults if absent, per
  [`../_shared/settings-file.md`](../_shared/settings-file.md)); keys → [`./references/settings.md`](./references/settings.md).

## Protocol

1. **Preconditions.** `tasks.json` parses, `deps` acyclic, every `file` resolves
   ([`./references/inputs.md`](./references/inputs.md)).
2. **Ensure settings** (create if absent, never overwrite; one line to the human).
3. **Detect commands** (headless check, optional lint, optional GUT, export) →
   [`./references/command-detection.md`](./references/command-detection.md).
4. **Build the order + resume.** Topological sort; `save` tasks in version order. Read each
   task's `status`: `done` skip, `in_progress`/`review` reset to `todo`, `blocked` ask.
5. **Branch + roadmap.** Ensure a feature branch (`branch_strategy`). If `docs/roadmap.md` has
   this feature's step, set it `building`.
6. **Build each task.** Small task → write it inline. Larger or independent task → dispatch
   [`implementer`](../../agents/implementer.md) with the worker preamble from
   [`../_shared/agent-roster.md`](../_shared/agent-roster.md) and the task file path. Follow the
   map's conventions and few-shots, design-system components and Theme tokens.
7. **Smoke + commit per task.** The smoke check is the headless import with no script errors
   (plus lint when `gate_lint: true`, plus any GUT tests that exist when `gate_tests: true`).
   Then commit only the task's files plus its status, with trailers `SDD-Task: T<n>` and one
   `SDD-AC: AC-NN` per satisfied AC. A new design-system component flips its row to `built` in
   the same commit.
8. **Stuck?** Two honest attempts, then mark the task `blocked` with the reason and move on to
   what doesn't depend on it.
9. **Summary + handoff.** Commits (short SHA + trailers), the smoke result, blocked tasks, and
   what to look at when playing the build. Handoff per [`../_shared/handoff.md`](../_shared/handoff.md):
   `/review <slug>` on the standard or full route, else `/ship <slug>`.

## Definition of Done

- Every task is committed with a clean smoke check and trailers, or reported blocked with the reason.
- Status files reflect the final state of every task.
- The smoke check is this skill's **structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)).

## Anti-patterns

- **Test theatre.** Writing tests nobody needed, for code that is easier to check by playing.
- **Touching the real `user://`** in any test that does exist. Use a temp directory.
- **Editing a `.tscn` by hand when the scene can be built in code** or with a tiny scene; never
  break `uid://` references.
- **Hard-coded colours, sizes or strings in UI** instead of Theme tokens and voice line ids.
- **Committing with script errors** in the headless import.
