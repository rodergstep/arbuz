---
name: survey
model: inherit
effort: medium
agents: [explorer]
description: >
  Use to establish the repo's architecture map the rest of the pipeline reads. Two modes: on an
  EXISTING codebase it scans once and persists what's there; on an EMPTY/greenfield repo it runs a
  short, level-adaptive foundation session — picks the stack / folder structure / data approach /
  conventions WITH you (defaults-heavy), fixes them as the foundation + foundational ADRs, and emits
  a scaffold tasks.json that the scaffold skill materializes into a real skeleton. Triggers on "survey the
  codebase", "map the architecture", "set up a new project", "bootstrap the foundation",
  "/survey", "вивчи кодову базу", "карта архітектури", "новий проєкт", "заклади фундамент".
  Output: docs/architecture-map.md (+ adr/ + scaffold tasks.json on greenfield). Records
  reflects_commit for staleness; reads, never overwrites, an authored architecture doc.
---

# Skill: survey

The pipeline's anchor on architecture. It produces `docs/architecture-map.md` — the single source of "what the system is" that `specify` (constraints), `design` (matches against it), `contracts`, and `implement` all read instead of re-discovering the code. It runs in one of **two modes**, auto-detected:

- **Brownfield** (the repo has source) → scan it once and persist the **current** architecture.
- **Greenfield** (empty / near-empty repo) → run a short, **level-adaptive foundation session**: pick the stack / structure / data approach / conventions *with* the user (defaults-heavy), fix them as the **foundation** + foundational ADRs, and emit a **scaffold `tasks.json`** that [`scaffold`](../scaffold/SKILL.md) turns into a real skeleton. Greenfield detail → [`./references/foundation.md`](./references/foundation.md).

Repo-level utility (one map serves every feature). The scan is delegated to [`explorer`](../../agents/explorer.md); question phrasing → [`../_shared/ask-style.md`](../_shared/ask-style.md); depth → [`../_shared/size-matrix.md`](../_shared/size-matrix.md).


## Owner

The parent confirms; Claude scans and writes. Re-run after each phase gate, or whenever `reflects_commit` is far behind HEAD.

## Inputs

- (Optional) a path/scope hint (default: repo root).
- (Read, never overwrite) an authored architecture doc if present (`docs/architecture.md`, `ARCHITECTURE.md`, root `CLAUDE.md`, ADRs) — a strong input the map reconciles with, never clobbers.
- (Optional, greenfield) `docs/features/<slug>/idea.md` — the intent G3 would otherwise ask for; present → confirmed, not re-asked.

## Protocol

1. **Ensure the settings file (first thing, after this skill's own gate).** If `.claude/sdd.local.md` is absent, create it now from the canonical template — documented defaults + the self-documenting body — and patch `.gitignore`; if it exists, read it and never overwrite. The one procedure lives in [`../_shared/settings-file.md`](../_shared/settings-file.md). Creating is unconditional; **changing values is only ever offered by [`config`](../config/SKILL.md)**. Say one line: «`.claude/sdd.local.md` created with documented defaults — `/config` to tune it». **Then detect mode + freshness (incremental re-survey on stale).** If `docs/architecture-map.md` exists and is fresh (its `reflects_commit` ≈ current HEAD) → «map is fresh (reflects `<commit>`). Reuse or refresh?»; STOP on reuse. If it exists but is **stale**, prefer the **incremental re-survey**: `git diff --name-only <reflects_commit>..HEAD`, group the changed paths by top-level module, and dispatch the step-3 explorer **scoped only to the changed subfolders**; update just the touched map rows/sections (autoloads, folders, conventions, few-shots, machine keys) and re-stamp `updated_at` + `reflects_commit`. Fall back to the **full re-scan only when the diff spans more than half the modules** in the inventory (or `reflects_commit` no longer resolves) — say which mode ran in the handoff. No map at all → decide the mode: **brownfield** if the repo has source (modules/packages beyond config), else **greenfield** (empty or only scaffolding like a bare `go.mod` / `package.json`).

### Brownfield path (existing code)

2. **Read authored docs first.** Any hand-maintained architecture doc / root `CLAUDE.md` / ADRs → authoritative input; reconcile with it, never overwrite.
3. **Scan via explorer.** Dispatch the [`explorer`](../../agents/explorer.md) agent — `subagent_type: "explorer"` (`haiku`/`low`, clean-isolated per [`../_shared/agent-roster.md`](../_shared/agent-roster.md)): «Report (a) Godot version, renderer, addons + versions (from `project.godot` and `addons/*/plugin.cfg`), (b) every autoload in load order with its script, public methods and `signal` declarations, (c) the folder layout and what each folder holds, (d) conventions with one cited example each (typing, naming, signals vs calls, input routing, saves, errors, tests), (e) save format: where it is written and the current `version`, (f) content data: word DB format and `Resource` classes, (g) the UI foundation: Theme files, component scenes, (h) 3–5 short real excerpts to use as pattern few-shots (an autoload, a Resource, a scene script, a GUT test), (i) the test/lint/export commands actually configured.» Large repo → fan out per subtree. (Fallback `subagent_type: "Explore"`.) Items (g) and (h) are the reuse sources: `implement` imitates the few-shots, and new UI composes the listed components.
4. **Synthesize + stamp + validate + write.** Copy [`./templates/architecture-map.md`](./templates/architecture-map.md) to `docs/architecture-map.md` as soon as the first explorer report lands (a stale map is edited in place, never re-bootstrapped), and write each section **as it is synthesized** — per fanned-out subtree too — never the whole map at the end ([`../_shared/write-and-commit.md`](../_shared/write-and-commit.md) §1). Fill it (stack diagram, autoload table, folder inventory, cited conventions, pattern few-shots, data and saves, UI foundation, precedents, performance budget, constraints) with real `file:line` anchors. **Fill the machine-readable frontmatter keys** (`godot_version`, `renderer`, `test_cmd`, `lint_cmd`, `vet_cmd`, `export_cmd`, `save_format_version`) from the explorer's findings — a key with no evidence stays `""` (unknown), **never a guess**; `implement`'s command detection reads the `*_cmd` keys from here. Record `updated_at` + `reflects_commit: <short HEAD>`. **Validate the Mermaid per [`../_shared/mermaid-check.md`](../_shared/mermaid-check.md)** (render-parse with `mmdc` if available, else the structural lint; fix before committing). Then the **structural self-check** (per [`../_shared/self-check.md`](../_shared/self-check.md)) — re-read the map from disk and verify: (1) every machine key holds an explorer-backed value or the explicit `""`; (2) every convention line cites a file that exists; (3) the Mermaid validated and every few-shot block is a real excerpt with its path; (4) `reflects_commit` = current short HEAD. Only after it passes, commit per [`../_shared/write-and-commit.md`](../_shared/write-and-commit.md): `survey: architecture-map.md (reflects <commit>)` (a failed self-check → no commit). Then **emit the stage-handoff block** per [`../_shared/handoff.md`](../_shared/handoff.md) — *What I did* (incl. the commit SHA) + *Review* (`docs/architecture-map.md`) + *Run next* (`/clear`, then `/specify <slug>`). (The greenfield path emits its own handoff in G6 — forward to `/roadmap` when a brief exists and no roadmap yet, else to `/scaffold`.)

### Greenfield path (empty repo) → [`./references/foundation.md`](./references/foundation.md)

G2. **Confirm the pre-decided foundation.** Read `docs/development-plan.md` and `docs/game-spec.md`; show the pre-decided table from [`./references/foundation.md`](./references/foundation.md) and confirm it in one bundled question.
G3. **Ask only what is still open** (the "Still to ask" list), never something the plan already settles.
G4. **Write the foundation.** From the first confirmed pick, `docs/architecture-map.md` exists on disk (template copied, `mode: greenfield-bootstrap`) and each pick lands in its section **as soon as it is confirmed** ([`../_shared/write-and-commit.md`](../_shared/write-and-commit.md) §1). Choice menus + defaults → [`./references/foundation.md`](./references/foundation.md).
G5. **Fix the foundation.** Complete `docs/architecture-map.md` as the **established foundation** (mark `mode: greenfield-bootstrap`; the C4 is the *target* baseline) + spawn **foundational ADRs** in `docs/adr/` for the irreversible picks (engine/renderer, autoload architecture, saves, content as data) — each ADR written to disk as it is decided. **Fill the machine-readable frontmatter keys** from the chosen foundation (`godot_version`, `renderer`, `test_cmd`, `lint_cmd`, `vet_cmd`, `export_cmd`, `save_format_version`) — here they encode the *decided* toolchain; anything not yet decided stays `""`. Record `reflects_commit`. **Validate the Mermaid per [`../_shared/mermaid-check.md`](../_shared/mermaid-check.md)** and run the same step-4 structural self-check — nothing is committed before it passes.
G6. **Emit the scaffold plan + hand off.** Write a scaffold `tasks.json` (the Phase 0 skeleton: project settings, LFS, addons, folders, an example autoload + test, GUT, lint, macOS export, the gamepad check scene, the event log) per the contract in [`./references/foundation.md`](./references/foundation.md). Each task's DoD anchors on the **skeleton smoke test** — «the project imports headless with no script errors + a macOS export builds» (canonical in [`../scaffold/SKILL.md`](../scaffold/SKILL.md)). Then commit per [`../_shared/write-and-commit.md`](../_shared/write-and-commit.md) — one commit per document: `survey: architecture-map.md (greenfield foundation)`, **each** ADR on its own (`survey: ADR-NNNN <title>`), `survey: _scaffold tasks.json`. Then **emit the stage-handoff block** per [`../_shared/handoff.md`](../_shared/handoff.md) — *What I did* (incl. the commits with short SHAs) + *Review* (`docs/architecture-map.md`, `docs/adr/`, `docs/features/_scaffold/tasks.json`) + *Run next*, picked from what is on disk: **`docs/features/<slug>/idea.md` present and no `docs/roadmap.md`** → `/clear`, then `/roadmap` (it cuts the idea into steps with the skeleton as step 1, and its own handoff then gives `/scaffold`), with the skip line «`/scaffold` also runs now — it reads only the map and `_scaffold/tasks.json`, not the roadmap»; **otherwise** → `/clear`, then `/scaffold` (it materializes the skeleton; the per-feature flow starts afterwards with `/specify <slug>`). One order across the pipeline: interview → survey → roadmap → scaffold → specify.

## Definition of Done

- `docs/architecture-map.md` exists with `updated_at` + `reflects_commit`; an authored doc (if any) was reconciled, never overwritten.
- **Brownfield:** C4 of what exists + module inventory + cited conventions + precedent guide, real anchors (no placeholders).
- **Greenfield:** foundation fixed (stack/structure/data/conventions) at the user's calibrated level + foundational ADRs + a scaffold `tasks.json` whose tasks carry the skeleton smoke-test DoD, ready for `/scaffold`.
- The step-4 **structural self-check** passed ([`../_shared/self-check.md`](../_shared/self-check.md)): machine keys explorer-backed or explicitly `""`, convention citations resolve, C4 validated, `reflects_commit` current; its result is reported in the handoff.

## Anti-patterns

- **Re-scanning the repo in every downstream skill** — the point is to scan once; others read the map (drift detection is the only re-read, of real domain files).
- **Overwriting a hand-maintained `docs/architecture.md`** — survey writes its own map and reconciles.
- **A map with no `reflects_commit`** — it silently rots; nobody knows it's stale.
- **Greenfield: a full product brief.** The foundation session picks the *architecture*, not the features — the idea/briefing is `specify`'s job, per feature. Keep it to intent + foundation choices.
- **Greenfield: re-asking settled choices.** The Development Plan already decided the engine, addons and folders.
- **Placeholders / guessed layout** — cited or `UNKNOWN`; a fictional map is worse than none.

## References & template

- [`./references/foundation.md`](./references/foundation.md) — greenfield: the calibration question, level-adaptive depth, the stack/structure/convention choice menus + defaults, foundational-ADR list, and the scaffold `tasks.json` contract.
- [`./templates/architecture-map.md`](./templates/architecture-map.md) — output scaffold (same file for current OR foundation; a `mode:` marker distinguishes).
- [`../_shared/agent-roster.md`](../_shared/agent-roster.md) — the explorer contract.
