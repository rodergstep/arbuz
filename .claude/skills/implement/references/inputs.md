# Inputs + preconditions (step 1)

## Hard gate

`docs/features/<slug>/tasks.json` must exist and parse as JSON. Missing or malformed → refuse: «run `tasks <slug>` first (it emits tasks.json)». `tasks.json` is the **contract**: the task set, the ids and the `deps` DAG come from it and are never reconstructed by parsing the markdown. The markdown is the opposite thing — the **body** of each task, reached through the `file` pointer in that same JSON (see «The task file is the agent's brief»).

## Validate the contract

The loaded `tasks.json` must satisfy the shape from the `tasks` skill:

- top-level `{ slug, tasks: [...] }`.
- each task: `id` (unique), `title`, `layer`, `deps` (array of existing ids), `acs` (array), `dod` (string), `files_hint` (array), `file` (repo-relative path to the task's markdown, `docs/features/<slug>/tasks/<task-slug>.md`). Optional: `status` (`todo | in_progress | blocked | review | done`; absent = `todo`, so an older breakdown still loads) — read for resume per [`./tdd-loop.md`](./tdd-loop.md) §Status protocol.
- `file` must resolve to a file on disk. Missing key, or a path that doesn't exist → the breakdown predates the self-contained task format (or was hand-edited): say so, fall back to the JSON fields + the upstream artifacts below for that task, and note in the run banner that the agents are working without an inlined brief. (The `_scaffold` set below is exempt — it has no task markdown, and it is redirected out of this engine anyway.)
- `deps` forms a DAG (no cycles) — verified in step 4. A cycle is a hard error: report the cycle and stop (it is a `tasks` bug, not an `implement` one).

## Scaffold task sets (from `survey` greenfield) → run `scaffold`, not `implement`

A `tasks.json` with `slug: "_scaffold"` and `layer: scaffold` tasks is the scaffold plan from
`survey`'s greenfield foundation — it is **not** an `implement` input. Redirect: «this is the
scaffold set — run `/scaffold` (the materialization protocol + the skeleton smoke-test anchor
are canonical there); `implement` is the feature engine.» After the skeleton is green, the normal
per-feature flow (`specify → … → implement`) builds into it with real feature TDD.

## The task file is the agent's brief

`tasks/<task-slug>.md` (the `file` field) is **the first thing every agent reads** and its primary brief. `tasks` writes it self-contained: the user story, the acceptance criteria verbatim, the data delta, the API slice, the edge cases — each chunk carrying a provenance signature naming the file, section and identifier it was cut from, and some marked `abridged`.

**The order is fixed:** the task file is the brief, upstream is the **fallback**. An agent opens the named upstream file when a slice is insufficient, ambiguous, or contradicted by the code in front of it — the source always wins over a snapshot, and an `abridged` chunk is by construction a snapshot. It never invents the missing part, and it never skips the task file to «go read the real thing» when the slice is sufficient: that rediscovery is exactly the cost the inlining removes.

## Context the agents read directly

The engine does not paste these into prompts; each agent reads the task file, then these when needed:

- `docs/features/<slug>/tasks/<task-slug>.md` — **the brief**. Read first, always.
- `docs/features/<slug>/spec.md` — §5 ACs (source of truth for what each test asserts) and the
  inline `## Test plan` when there is no `test-plan.md`.
- `docs/features/<slug>/test-plan.md` — the AC → test map.
- `docs/features/<slug>/contracts/*.md` — save, word DB, content, autoload API, tool deltas.
- `docs/features/<slug>/sad.md` + `adr/` — architecture and locked decisions.
- `docs/architecture-map.md` — conventions and **pattern few-shots**: new code imitates them.
- `docs/design-system.md` + `docs/features/<slug>/ux-flows.md` — for `ui`/`scene` tasks: the
  components, tokens, audio and hint rules, and the per-state manifest the scene is built to.

## Save tasks

A `layer: save` task changes the save format: it bumps the version, adds
`migrate_v<N>_to_v<N+1>` in `autoload/save/migrations.gd`, and adds the fixture
`tests/fixtures/saves/v<N>.json` (a realistic save at the old version). RED is the contract test
that migrates the fixture and asserts every learning stat survives. Never edit a shipped
migration step.

## `ui` and `scene` tasks

Same TDD cycle; the RED test is usually a scripted playthrough (GUT instantiates the scene,
simulates input with `InputEventMouseButton` / `InputEventScreenTouch` / `InputEventJoypadButton`
or GUT's input sender, advances time, and asserts the state from the manifest). Build only with
design-system components and Theme tokens; a component marked `NEW` in `ux-flows.md` must have
the parent's approval recorded there, and the task flips its design-system row to `built`.

## Repo state

- If `branch_strategy: feature` and the repo is on its default branch, create a feature branch
  (`feature/<slug>`) before the first commit.
- Touch only the files in the task's `files_hint` (plus its status files); leave unrelated
  changes alone.
