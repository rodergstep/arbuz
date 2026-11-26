# TDD loop: the per-task cycle

Every task runs `SELECT → RED → GREEN → REFACTOR → GATE → COMMIT`, sequentially, in place. Three different agents own the three middle steps, so no agent grades its own work:

| Step | Agent | May edit |
|---|---|---|
| RED | `test-author` | `tests/**` only |
| GREEN | `implementer` | production code in the task's `files_hint`; never tests |
| REFACTOR | `refactorer` | production code touched by this task; never tests, never behaviour |

The RED step is the load-bearing one. Skip its discipline and the method collapses into "write code, then a test that happens to pass".

Every transition is written to disk as it happens; see **Status protocol** below.

## SELECT

Pick the next task whose `deps` are all `done` as recorded on disk (`tasks.json` `status`), never as remembered from the conversation. **Read the task file first** (`docs/features/<slug>/tasks/<task-slug>.md`): it carries the §5 acceptance criteria verbatim, the contract delta, the pattern to follow and the edge cases. `spec.md §5` and `test-plan.md` are the fallback ([`./inputs.md`](./inputs.md)). Know, before anything is written, which observable outcome the test will assert.

## RED: `test-author` writes the failing test

1. Dispatch `test-author` with the task file, the matching test-plan rows, and the pattern few-shot for tests from `docs/architecture-map.md`. It writes GUT tests under `tests/` (unit → `tests/unit/`, integration → `tests/integration/`, contract → `tests/contract/`).
2. It runs the unit command and **classifies the first run aloud**:

   | Class | What it looks like | Action |
   |---|---|---|
   | **GOOD red** | the test script parses, runs, and fails on an assertion or a missing method | hand over to GREEN |
   | **BAD red** | parse error in the test, wrong preload path, typo in the test itself | the test is broken, not the code: fix the test, re-run, re-classify |
   | **false-pass** | green before any production code exists | the test asserts nothing real: strengthen it until it is GOOD red |
   | **NON-run** | needs a windowed run (rendering, real audio device, export) that headless cannot do | record NON-run; cover the logic with a headless unit test too, and list the windowed check for `/playtest` |

3. It **quotes the failing line** (assertion with expected vs actual, or `Invalid call. Nonexistent function ...`). This quote is the proof the test exercises the right thing, and the handover to GREEN carries it.

Save-format tasks: the RED must include a fixture-save test (`tests/fixtures/saves/v<N>.json` loads and migrates to the current version). Word-DB tasks: a test that validates every entry against `docs/contracts/word-db.md`.

## GREEN: `implementer` makes it pass

Dispatch `implementer` with the task file, the quoted failure and the pattern few-shot. It writes the **least** code that turns the quoted assertion green: no speculative generality, nothing outside `files_hint`, and it **never edits a test**. If it believes a test is wrong, it stops and reports; the engine sends the test back to `test-author` with the reason. It re-runs the unit command and confirms the quoted failure is green and nothing else broke.

## REFACTOR: `refactorer` cleans while staying green

Dispatch `refactorer` with the task's diff, the conventions section of `docs/architecture-map.md`, and the design-system tokens if UI was touched. It tidies names, typed GDScript (`: int`, `-> void`), signal naming, duplication, magic numbers that should be tokens or constants. It re-runs the unit command after each change; a refactor that goes red and is not trivially fixable is reverted. It may answer `NO_CHANGES`, which is a fine outcome. It never changes behaviour or tests.

On `route: quick` the engine may skip REFACTOR for XS tasks; say so in the run log.

## GATE: the task is not done until this is clean

Run, per the detected commands and settings ([`./command-detection.md`](./command-detection.md)):

- **unit**: GUT on `tests/unit` must be green.
- **integration / contract**: GUT on those dirs, green when present.
- **import check**: `<godot> --headless --path . --import --quit` exits 0 with no script errors.
- **lint** (if `gate_lint`): `gdlint` clean, `gdformat --check` clean.
- **vet** (if `gate_vet` and resolved): treat warnings-as-errors in the import log as failures.

Any hard-gate failure means the task is not done. Fix it, or escalate ([`./escalation.md`](./escalation.md)).

## COMMIT: one task, one commit, traceable

When `auto_commit: per_task`, commit only this task's files:

```
<type>(<slug>): <task title>

<one line: what and why>

SDD-Task: T3
SDD-AC: AC-02
SDD-AC: AC-04
```

One `SDD-AC` trailer per AC satisfied. The task's status files are set to `done` **before** the commit and ride in it. With `auto_commit: off` the engine still updates every status file and leaves committing to the human.

If a contract change and its first consumer cannot be green separately (for example a renamed autoload method and its only caller), `/tasks` should have merged them into one task. If they arrive split anyway, run one GATE and one commit with both `SDD-Task` trailers and say why in the body.

## Status protocol: live task status on disk

Every task's progress is on disk, updated **at each transition, not at the end**, so an interrupted run resumes exactly where it stopped. The engine is the only writer; subagents never touch status files.

**Model.** `status` ∈ `todo · in_progress · blocked · done`; `step` ∈ `SELECT · RED · GREEN · REFACTOR · GATE · COMMIT` (for `blocked`, the reason). Three files carry it, all written together:

| File | Carries |
|---|---|
| `tasks/<task>.md` frontmatter | `status:` + `step:` |
| `tasks/tracker.md` | the task's row: **Status** + **Step** columns |
| `tasks.json` | `status` (absent = `todo`); `step` is markdown-only |

**Transitions:**

| Event | status / step |
|---|---|
| task picked | `in_progress` / `SELECT` |
| `test-author` dispatched | `in_progress` / `RED` |
| GOOD red quoted and accepted | `in_progress` / `GREEN` |
| `implementer` reports green | `in_progress` / `REFACTOR` |
| gate starts | `in_progress` / `GATE` |
| commit about to run | `done` / `COMMIT` (set before, so it rides in the commit) |
| commit fails (hook, conflict) | `blocked` / `COMMIT: <first line of failure>`; never leave `done` without the commit |
| retries exhausted, or `stop_on_red` halts | `blocked` / `<step>: <reason>` |
| dependents of a blocked task | `blocked` / `dep T<n> blocked` |

`tdd: false` skips the RED and GREEN handover rows; the rest stand.

**Resume.** At the start of every run read `status` from `tasks.json`: `done` → skip; `in_progress` → reset to `todo` and say which tasks were reset (that work was never committed); `blocked` → ask the human per task whether to retry or leave it blocked.

**Native task list is a mirror.** When `TaskCreate` / `TaskUpdate` exist, mirror each `T<n>` there with an `activeForm` naming the step ("T3 · GREEN: implementing word picker"). When they don't, skip silently. On any disagreement the three status files win.
