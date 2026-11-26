---
name: tasks
model: inherit
effort: medium
agents: []
description: >
  Use to break a designed feature into atomic tasks (one commit each, fits one agent context) with a dependency graph, a
  per-task Definition of Done, and a machine-readable tasks.json that the implement engine
  consumes. Triggers on "task breakdown for {slug}", "break down tasks for {slug}",
  "tasks for {slug}", "plan the work for {slug}", "/tasks {slug}", "розбий на задачі {slug}",
  "декомпозиція {slug}", "список задач". Reads spec.md + sad.md + Accepted ADRs (+ ux-flows +
  contracts if present), writes docs/features/{slug}/tasks/{_epic,tracker,<task>}.md AND
  docs/features/{slug}/tasks.json. Tracker export to any issue tracker is optional and
  tool-neutral. Hard-refuses if spec.md or sad.md or an Accepted ADR is missing.
---

# Skill: tasks

Task-breakdown generator: atomic tasks, each one commit that fits comfortably in one agent's context (≤~300 changed lines preferred), with a visible dependency graph and a Definition of Done per task. One task = one focused session = one PR. "Build the feature" is not a task — break it down.

A task file is **self-contained**. The rule that governs every task body: **inline the slice the task actually needs, name where it came from, and keep the link as the fallback for when the slice turns out not to be enough.** A task that only points at `spec.md §AC-N` makes the executing agent go and rebuild the context this breakdown already had — it burns its budget on rediscovery and still misses. Alongside the human-facing markdown, this skill emits **`tasks.json`**, the contract the `implement` engine reads to build its dependency DAG.

Every inlined chunk carries a one-line **provenance signature** — `<file> §<section>, <identifier>, verbatim|abridged`, e.g. «`spec.md` §5, AC-02, verbatim» — never «see the spec». The signature is what makes an inline re-checkable: an inline is a snapshot taken at breakdown time, upstream can move after it, and the source always wins.


## Owner

Tech Lead.

## Inputs

- `<slug>` — feature slug.
- **Gate (hard refuse):** `docs/features/<slug>/spec.md`, and `docs/features/<slug>/sad.md` unless `.route` is `quick` and design was legally skipped (no system/API change). Missing → STOP and point at the producing skill. ADRs are read when present; SAD-lite features may have none.
- Read directly (not via an index): spec §5 AC + §6 NFR, sad §5 module boundaries + §6 runtime + §9 ADR index, each Accepted ADR, and — if present — `ux-flows.md` (the state manifest `ui`/`scene` tasks cite) and `contracts/*.md` (save, word DB, content, autoload API, tools deltas).
- (Expected) `sad.md` frontmatter `areas` — gates which layers appear (step 4). **Absent or empty → derive from the spec and say so** (→ [`../_shared/game-areas.md`](../_shared/game-areas.md)).

## Protocol

1. **Prereq check (hard).** spec.md (+ sad.md unless legally skipped), else refuse with the missing one named.
2. **Read upstream directly.** Each task will carry the slices it needs, quoted from the source — so read the source text itself, never a paraphrase of it: the quote goes into the file.
3. **Read the templates from disk, then scaffold output.** **Read [`./templates/task.md`](./templates/task.md) before writing a single task file** — its frontmatter keys and its `## ` section list are the contract, and its `<!-- instruction … -->` comments are the per-section brief. Same for [`./templates/_epic.md`](./templates/_epic.md) and [`./templates/tracker.md`](./templates/tracker.md). **Never write a task from memory of what a task file looks like:** the self-contained format (the `blocks` / `context_budget` keys, the nine sections, the provenance signatures) is younger than most recollections of it, and a remembered shape silently reverts this skill to the link-only tasks it exists to replace. Output: `docs/features/<slug>/tasks/` with `_epic.md` (summary + links + the DAG `flowchart`), `tracker.md` (status table), one `<task-slug>.md` per task. **Validate the `_epic.md` `flowchart` per [`../_shared/mermaid-check.md`](../_shared/mermaid-check.md)** (render-parse with `mmdc` if available, else the structural lint; fix before committing).
4. **Identify work-items by layer.** Layers: `save` (save format + migration + fixtures) · `core` (autoload systems) · `data` (Resource classes, word DB, content files) · `scene` (playable scenes) · `ui` (Control scenes, Theme, components) · `audio` (voice/SFX wiring, generation runs) · `tooling` (Python/Blender/build scripts) · `build` (export presets, project settings) · `tests` (shared fixtures, scripted playthroughs) · `docs`. **`sad.md` frontmatter `areas` gates which layers appear** (→ [`../_shared/game-areas.md`](../_shared/game-areas.md)). Each `ui`/`scene` task **names the design-system components and Theme tokens it uses** and **cites the `SCR-NN` + states** from `ux-flows.md`; a new component appears only if it was approved there. Typical count: quick 1–3, standard 4–10, full 8–20.
5. **Atomic check — work size and context size.** Each task is one commit and fits one agent's context. Count the inlined lines the finished body will carry (from `## Why (user story)` through `## Acceptance criteria`) against the `context_budget` bands — `S` ≤40 · `M` ≤120 · `L` beyond. An `L` is a split signal: split it, or keep it and write the reason on the frontmatter line (`context_budget: "L"   # justified: <one line>`). A change >~300 lines is a smell. **API-change rule:** a task that changes an autoload's public method or signal is folded into the first task that uses the change, or both tasks list the autoload file in `files_hint` so `implement` runs them back to back.
6. **Dependency graph.** For each task, `deps: [...]` — and its exact inverse `blocks: [...]`, the ids waiting on this one, so a task shows what it holds up without the reader reconstructing the graph. This graph IS the DAG `implement` sorts topologically; work runs sequentially, so order the graph so each task leaves the game runnable.
7. **Per-task DoD.** Each task is checkable in the running game in one sentence: «in the game, a word picked wrong comes back in the same session (AC-04)», «a v2 save loads in the v3 build with all word stats (a fixture GUT test, the one place a test is worth it)», «idle 15 s: Тигриця gives hint level 1 (AC-06)». No subjective «done when I say so».
8. **AC refs + files hint.** Each task lists the `acs` it satisfies (spec §5 IDs) and a `files_hint` — the directories/files it will touch. `files_hint` lets `implement` keep tasks that share a file (a `.tscn`, `project.godot`, an autoload) adjacent; `layer: save` tasks run in version order. A save task's `files_hint` includes `autoload/save/migrations.gd` and its fixture under `tests/fixtures/saves/`.
9. **Fill the task body — self-contained, not a link list.** Every section of [`./templates/task.md`](./templates/task.md) is sourced from a named artifact:
    - *Place in the sequence* ← the DAG (step 6): `deps` and `blocks` by id + title, the wave, and the lane it shares (overlapping `files_hint` / compile-coupled pair).
    - *Why (user story)* ← `spec.md` §4 — the `US-NN` block **verbatim**, then one sentence on what this task contributes to it.
    - *Inlined context* ← `spec.md` §1 committed approach · `spec.md` §6 NFR + `sad.md` §11 for the Hard Rules this task must not violate · `sad.md` §5 for the building block it lives in (boundary + collaborators) · `sad.md` §6 for the runtime steps it implements, toddler branches included · the decision line of each Accepted ADR that constrains it · `ux-flows.md` `SCR-NN` + the states, for `ui`/`scene` tasks · the matching pattern few-shot from `docs/architecture-map.md`.
    - *Contract delta* ← `contracts/*.md` — only the save fields, word DB columns, Resource properties, autoload methods/signals or tool flags this task touches, with the migration name and fixture for `layer: save`. Nothing touched → the literal «No contract changes.», never an empty section.
    - *Acceptance criteria* ← `spec.md` §5 — the Given-When-Then of **every** id in `acs`, verbatim. The tests assert these; a paraphrase here becomes a wrong test downstream.
    - *Edge cases* ← the negative branches of those §5 ACs + the `sad.md` §6 error paths, as a case/behaviour table.

    Record the file you just wrote as the task's `file` (repo-relative `docs/features/<slug>/tasks/<task-slug>.md`) — step 11 emits it into `tasks.json`, and that pointer is the only way `implement` reaches this body.

    **Signature.** Each chunk ends with `<file> §<section>, <identifier>, verbatim|abridged` and the link to the full text. **Cutting a long chunk:** keep the sentences that change what gets built (the constraint, the number, the branch, the error code), drop narrative and anything belonging to another task, mark the result `abridged`, keep the link. **Budget:** only this task's ACs, only the fields and endpoints it touches — a task carrying another task's context is as broken as one carrying none. The template also addresses the executing agent directly: an insufficient or code-contradicting slice means go read the named file, never invent the missing part.
10. **Estimate + owner + context budget.** `estimate` S/M/L or hours (how long the work takes); a named owner (or `<TBD lead>`); `context_budget` S/M/L — the honest cost of holding this task, measured (not guessed) as the step-5 count: `S` ≤40 inlined lines and ≤1 extra file to open · `M` ≤120 lines, 2–4 files · `L` beyond, carrying its `# justified:` reason. Adapt `estimate` to the team's sizing if any; the budget bands are fixed.
11. **Emit `tasks.json`** (step contract below) — the same model the markdown reflects, in machine form, at `docs/features/<slug>/tasks.json`. Every entry carries `file`, the repo-relative path of the markdown written in step 9; that pointer is what lets `implement` hand the agent the inlined context instead of sending it back upstream.
12. **No external tracker.** `tracker.md` + `tasks.json` are the tracker. (If the human asks, GitHub issues can be created from the task files; never by default.)
13. **Self-check.** Every task is one commit; DAG acyclic; `blocks` is the exact inverse of `deps`; DoD per task; every task's *Inlined context* and *Acceptance criteria* are non-empty; no upstream reference without a provenance signature; every task's inlined-line count sits inside its `context_budget` band, and every `L` carries its `# justified:` reason; every `file` points at a markdown that exists on disk; `acs` cover every spec §5 AC; `tasks.json` validates against the contract.
14. **Commit + handoff.** After the step-13 self-check passes, commit per [`../_shared/write-and-commit.md`](../_shared/write-and-commit.md) — the whole `tasks/` directory + `tasks.json` are **one** commit (one model rendered twice): `tasks: <slug> breakdown + tasks.json`. Then **emit the stage-handoff block** per [`../_shared/handoff.md`](../_shared/handoff.md) — *What I did* + *Review* (`tasks/`, `tasks.json`) + *Run next* — **resolve the next stage per `.route`** (the Routes table in [`../_shared/size-matrix.md`](../_shared/size-matrix.md)): forward `/implement <slug>`.

## `tasks.json` contract (read by `implement`)

```json
{
  "slug": "<slug>",
  "tasks": [
    {
      "id": "T1",
      "title": "imperative, specific",
      "layer": "save|core|data|scene|ui|audio|tooling|build|tests|docs",
      "deps": ["T0"],
      "acs": ["AC-01", "AC-02"],
      "dod": "one testable sentence",
      "files_hint": ["path/or/dir/the/task/touches"],
      "file": "docs/features/<slug>/tasks/<task-slug>.md",
      "status": "todo"
    }
  ]
}
```

- **`file` is what makes the inlined context reachable.** It is a **repo-relative** path (same convention as `files_hint` in the same object — not feature-folder-relative), and it is the pointer `implement` follows to hand the executing agent its task file. Without it the engine physically cannot find the markdown, and everything inlined per step 9 is read by humans only. Emit it for **every** task; a task whose `file` does not exist on disk is a hard error, not a warning.
- The markdown task files and `tasks.json` use the **same field names** (`deps`, `acs`, `files_hint`, …) — this skill emits both from one model, so there's no translation layer to drift. Downstream parses the **JSON**: `implement` builds its DAG from `tasks.json` and reads the markdown body through `file`; the frontmatter keys are the human-readable mirror of the same model. **Never rename or drop one on either side** — the mirror is what keeps them auditable against each other.
- `blocks` and `context_budget` stay **markdown-frontmatter only** and are deliberately absent from the JSON: `blocks` is derivable from `deps` (it is its inverse) and `context_budget` is a breakdown-time budget check (step 5 / step 13), not an input to the DAG. **Do not «fix» that by adding them to `tasks.json`.** `file` is the opposite case and no exception to this rule: it adds no content, it is a **pointer** to content the engine otherwise cannot reach.
- **`status`** is **optional** — `todo | in_progress | blocked | review | done`; absent means `todo`, so a breakdown written before this field still loads. This skill emits `"status": "todo"`; `implement` keeps it live (its Status protocol) and reads it on resume. **`step`** (`SELECT · BUILD · SMOKE · COMMIT`, or a blocked reason) is the opposite case to `file`: like `blocks` it lives in the **markdown only** — the task frontmatter and the `tracker.md` Step column — because it is progress narration, not a DAG input.
- `deps` must form a **DAG** (no cycles) and reference only ids present in the file.
- `implement` runs tasks sequentially in topological order; among ready tasks it prefers ones that share `files_hint` with the task just finished, and `layer: save` tasks run in version order.
- Which layers are present is gated by `sad.md` frontmatter `areas` → [`../_shared/game-areas.md`](../_shared/game-areas.md).

## Definition of Done

- `tasks/_epic.md` + `tasks/tracker.md` + one `tasks/<task>.md` per task exist.
- Every task file is **self-contained**: a non-empty *Inlined context* and *Acceptance criteria*, a *Contract delta* section that either carries a slice or states the explicit «No contract changes.», and a provenance signature on every quoted chunk — no bare «see the spec».
- `tasks.json` exists and validates: acyclic `deps`, every `acs` entry is a real spec §5 AC, every task has a `dod`, a `files_hint` and a `file` that resolves to an existing markdown.
- Every task's inlined-line count matches its `context_budget` band; an `L` carries its `# justified:` reason on the frontmatter line.
- Every task is one commit, fits one agent's context, and leaves the game runnable.
- Every spec §5 AC is covered by ≥1 task's `acs`.
- The step-13 check (atomicity, acyclic DAG, `deps`/`blocks` inverse, per-task DoD, self-containment, signature coverage, context budget, `file` resolves, AC coverage, `tasks.json` contract) is this skill's **structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)); its result is reported in the handoff.

## Anti-patterns

- **«Build the feature»** as one task. Split by layer and by AC.
- **Monster tasks** that an agent can't hold in context. Split.
- **No per-task DoD** → «done when I decide».
- **A task that is only links** («derives from spec §5, see sad §6») — the executing agent goes off to rebuild the context this breakdown already had, burns its budget, and still misses. Inline the slice.
- **An inline with no provenance signature** — an unattributable quote can't be re-checked when upstream moves, so nobody trusts it or updates it.
- **A task file with no `file` pointer in `tasks.json`** — the body is then unreachable by `implement`, every inlined slice is decoration, and the agent goes back to re-reading spec/sad. This is the failure mode the inlining exists to kill.
- **A wholesale paste of a whole upstream document** — the opposite failure, and just as expensive. Inline the slice THIS task needs, cut long chunks and mark them `abridged`, link the rest.
- **A task written from memory instead of from [`./templates/task.md`](./templates/task.md)** — the giveaway is a task with `## Why` / `## What` / `## Notes` instead of the nine sections, or a frontmatter missing `blocks` / `context_budget`. Re-read the template and rewrite.
- **`tasks.json` entries without `file`** — the engine then cannot reach the body, every inlined slice becomes decoration, and the executing agent goes back to re-reading `spec.md`. That is the exact failure this format exists to remove.
- **`tasks.json` out of sync with the markdown** — they must reflect the same model.
- **A task that violates a Hard Rule** from spec §6 / sad §11 (e.g. a scene writing the save file directly, or a new UI colour outside the Theme).

## References & template

- [`./templates/_epic.md`](./templates/_epic.md) · [`./templates/tracker.md`](./templates/tracker.md) · [`./templates/task.md`](./templates/task.md)
- [`../_shared/size-matrix.md`](../_shared/size-matrix.md) — how many tasks for the feature size.
- [`../_shared/game-areas.md`](../_shared/game-areas.md) — `areas` (read from `sad.md`) gates which layers appear.
