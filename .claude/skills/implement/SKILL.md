---
name: implement
model: inherit
effort: high
agents: [test-author, implementer, refactorer, reviewer]
description: >
  Use to build a feature from its tasks.json with strict TDD and three separate agents per task:
  test-author writes the GUT test from the ACs and proves it fails (RED), implementer writes the
  minimal code to pass (GREEN), refactorer cleans up to the project conventions while staying
  green (REFACTOR); then the gate (GUT + gdlint + headless check) and a task-scoped commit with
  SDD-Task / SDD-AC trailers. Triggers on "implement {slug}", "build {slug}", "start coding
  {slug}", "/implement {slug}", "реалізуй {slug}", "почни кодити {slug}". Hard-refuses without
  tasks.json.
---

# Skill: implement

The TDD engine. One task at a time, in dependency order, each task through
`SELECT → RED → GREEN → REFACTOR → GATE → COMMIT`, each of the three code steps done by **a
different agent with a clean context**:

| Step | Agent | Must not |
|---|---|---|
| RED | `test-author` | write production code |
| GREEN | `implementer` | edit or weaken the test |
| REFACTOR | `refactorer` | change behaviour (tests stay green, test files untouched) |

Why three: if one agent writes both, the test tends to cover the existing bug, or the agent
deletes the failing test (the oracle problem). Detail of each step and the on-disk status →
[`./references/tdd-loop.md`](./references/tdd-loop.md).

## Inputs

- `<slug>`; **gate (hard refuse):** `docs/features/<slug>/tasks.json` → «run `/tasks <slug>` first».
  A `_scaffold` task set → redirect to `/scaffold`.
- Read by the agents directly, task file first → [`./references/inputs.md`](./references/inputs.md).
- Settings: `.claude/sdd.local.md` (created with defaults if absent, per
  [`../_shared/settings-file.md`](../_shared/settings-file.md)); keys → [`./references/settings.md`](./references/settings.md).

## Protocol

1. **Preconditions.** `tasks.json` parses, `deps` acyclic, every `file` resolves
   ([`./references/inputs.md`](./references/inputs.md)).
2. **Ensure settings** (create if absent, never overwrite; one line to the human).
3. **Detect commands** (GUT unit/integration, lint, headless check, export) and print them →
   [`./references/command-detection.md`](./references/command-detection.md). No GUT runner →
   stop: TDD needs it (point at `/scaffold`).
4. **Build the order + resume.** Topological sort; among ready tasks prefer the one sharing
   `files_hint` with the last one; `save` tasks in version order. Read each task's `status`:
   `done` skip, `in_progress`/`review` reset to `todo`, `blocked` ask.
5. **Banner + branch + roadmap.** Print `tdd=<…> stop_on_red=<…> route=<…>` and the commands.
   Ensure a feature branch (`branch_strategy`). If `docs/roadmap.md` has this feature's step, set
   it `building` and commit that alone.
6. **Run each task** through the loop in [`./references/tdd-loop.md`](./references/tdd-loop.md),
   writing status + step to the task file, `tasks/tracker.md` and `tasks.json` at every
   transition. Dispatch each agent with the worker preamble from
   [`../_shared/agent-roster.md`](../_shared/agent-roster.md), the task file path, the test
   command, and (for test-author) the test-plan rows for the task's ACs.
7. **Gate + commit per task.** GUT (unit + integration + contract tiers) green, lint and headless
   check clean, then commit only the task's files plus its status files, with trailers
   `SDD-Task: T<n>` and one `SDD-AC: AC-NN` per satisfied AC. A new design-system component the
   task built flips its row in `docs/design-system.md` to `built` in the same commit.
8. **Stuck?** Escalation ladder → [`./references/escalation.md`](./references/escalation.md).
   Never weaken a test.
9. **Summary + handoff.** Covered ACs, commits (short SHA + trailers), gate results, blocked tasks
   with reasons. Handoff per [`../_shared/handoff.md`](../_shared/handoff.md): `/clear`, then
   `/review <slug>`. `implement` does not certify its own work.

## Definition of Done

- Every task is committed test-first and gate-clean with trailers, or reported blocked/dropped
  with the reason.
- Status files reflect the final state of every task.
- The per-task gate is this skill's **structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)).

## Anti-patterns

- **One agent doing RED and GREEN.** The separation is the point.
- **Tests that touch the real `user://`.** Use a temp profile directory.
- **Editing a `.tscn` by hand when the scene can be built in code** or with a tiny scene; never
  break `uid://` references.
- **Hard-coded colours, sizes or strings in UI** instead of Theme tokens and voice line ids.
- **Committing with a red or skipped gate** as done.
