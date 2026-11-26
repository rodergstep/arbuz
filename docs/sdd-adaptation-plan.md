# SDD framework → Тигриця's Journey: adaptation plan

Status: **draft, waiting for roderg's OK** · 2026-11-26
Source framework: `genkovich/sdd` v2.4.1, currently copied at the root of `arbuz/` (commit `84bb22c`).
Game plan: [Development Plan](https://claude.ai/artifact/T1jCJU2rnErz2JChm7d1Ze) (Godot 4.7, GDScript, GUT, 7 phases with gates).

---

## 0. What we have today, and the core problem

- `arbuz/` currently contains **only the framework** (23 skills, 10 agents, evals, plugin manifests). No game code yet; Phase 0 hasn't started. Git remote: `github.com/rodergstep/arbuz`.
- The framework is good at the *shape* you described (sizing → idea → PRD → critic → SAD/ADR → contracts → task graph → TDD → review → PR) and already has most pieces: `classify-size` with quick/standard/full routes, `survey` → Architecture Map bound to a commit, `design-system`, clean-context `reviewer`/`critic`, model-by-role roster, a TDD engine with separate `test-author` and `implementer`.
- But it is written for a **web backend team**: SQL migrations, OpenAPI, Docker integration tests, Figma/Pencil, 7 "surfaces" (backend/web/mobile/CLI…), forge deploys. About a third of the text is irrelevant to an offline, solo-family Godot game for a 3-year-old, and every irrelevant line is context the agent reads and can get confused by (context rot).

**Goal of the adaptation:** keep the pipeline and its gates, swap every web-backend concept for its game equivalent, cut what has no equivalent, and make it live inside the game repo so Claude Code picks it up without installing a plugin.

## 1. Target repo layout

The framework moves out of the repo root (which will become the Godot project root) into project-level Claude Code folders. Project skills are picked up automatically and are called without a prefix (`/specify`, not `/sdd:specify`).

```
arbuz/
├── project.godot              ← Phase 0 creates it
├── CLAUDE.md                  ← NEW: project rules + "how we work" (short, points to docs/workflow.md)
├── .claude/
│   ├── skills/<skill>/        ← the adapted skills (SKILL.md + templates/ + references/)
│   ├── skills/_shared/        ← shared policy (size matrix, agent roster, handoff…)
│   ├── agents/*.md            ← subagents (model per role)
│   └── sdd.local.md           ← per-machine settings (gitignored)
├── addons/                    ← GUT, Dialogic 2, Phantom Camera, Beehave
├── autoload/  scenes/  ui/  data/  audio/  tests/  tools/   ← per the game plan
└── docs/
    ├── game-spec.md, development-plan.md   ← exported from the Claude Docs
    ├── workflow.md            ← NEW: one-page guide to the pipeline (replaces the framework README)
    ├── architecture-map.md    ← from /survey, tied to a commit
    ├── design-system.md       ← toddler UI canon
    ├── roadmap.md             ← phases + gates + features
    ├── CONTEXT.md             ← glossary (UA/EN terms)
    ├── contracts/             ← LIVING contracts: save format, word DB, autoload APIs
    ├── adr/                   ← LIVING decision records (promoted from features)
    ├── playtests/             ← playtest notes + analyses
    └── features/<slug>/       ← temporary working artifacts during development
```

## 2. Task sizing: three routes, game signals

Keep the framework's mechanism (`.size` + `.route` files, route default from size, human confirms), but make **Quick / Standard / Full the primary dial** you see, and rewrite the signals for a game.

| Route | When (game examples) | Stages that run |
|---|---|---|
| **Quick** | Tuning a value (car speed, hint delay), renaming, swapping a sound or texture, fixing a button, a typo in a voice line, a small bug | `fix` for bugs; otherwise `specify` (lite: 1–3 ACs inline) → `tasks` → `implement` → `review` → `ship`. One session. |
| **Standard** | A new mini-game or activity, a new scene/location, a new UI screen, a new hint behavior, a voice-pipeline change, a new chapter's content | Framework **proposes** skips (clarify, sequences, contracts, separate test plan) when their N/A condition holds; **you decide** at each handoff. |
| **Full** | A new core system (learning tracker, save system, interaction system, quest engine), **any change to the save format or word DB schema**, anything about child safety (parent lock, session timer, anything that could expose the child to a link/purchase/network), a new language arc pipeline, changes to an autoload's public API used by many scenes | Nothing skipped: interview → specify → critic → ux-flows → full SAD + ADRs → contracts + checker → tasks → TDD → refactor → review (+ cross-vendor) → playtest gate. |

"Finance / legal / public contract" from the original map become, for us: **child safety + privacy** (recordings and the son's name stay offline and out of git where needed), **the save file** (losing a child's progress is our "prod data loss"), and **autoload APIs** (our "public contracts").

Signals `classify-size` asks about (replacing PR count / migrations / consumers):
1. Does it touch the save format or word DB schema? (yes → Full)
2. Does it add or change a core system or an autoload's public API?
3. Does it change what the child sees, hears or can reach (safety)?
4. How many scenes/files does it touch, and does it need a playtest to judge?

## 3. Stage-by-stage mapping

Legend: **Keep** (small edits), **Adapt** (rewrite for Godot), **Merge**, **Replace**, **Cut**, **New**.

| # | Framework skill | Decision | What it becomes for the game |
|---|---|---|---|
| 0 | `interview` | **Adapt** | Writes `docs/features/<slug>/idea.md` (problem, who: child / parent, learning goal, risks, out of scope). The game-level brief already exists: the game spec becomes `docs/game-spec.md`, so the project-level `idea-brief.md` is not needed. Asks one question at a time (already does). |
| 0 | `survey` | **Adapt** | Writes `docs/architecture-map.md` with `reflects_commit`. Template rewritten for Godot: stack diagram (Godot 4.7, GDScript, Compatibility renderer, addons), **autoload table** (name, responsibility, signals, owner file), folder/module table, conventions (typed GDScript, signal naming, scene-vs-code rules, data-driven content), and **Pattern Few-Shot** blocks: a reference autoload, a reference data `Resource`, a reference GUT test, a reference scene script. Machine keys: `godot_version`, `test_cmd`, `lint_cmd`, `export_cmd`, `save_format_version` (replaces `migration_tool`/`frontend`). |
| 0 | `scaffold` | **Adapt** | = **Phase 0**. Smoke test becomes: project opens headless, GUT runs an empty suite, `gdlint` passes, a macOS export builds, the gamepad check scene exists. Drops the migration tool. |
| 0 | `roadmap` | **Adapt** | `docs/roadmap.md` = the 7 phases and their **gates** from the Development Plan, with features as steps under each phase. Keeps "spec'd / building / shipped" statuses. Drops parallel worktree "waves" (solo project; see §5). New ideas go to a Backlog section, per the plan's rule. |
| 0 | `design-system` | **Adapt (big)** | The **toddler UI canon**. Tool = `code` only (markdown + a Godot `Theme` .tres as the token source). Drops Figma/Pencil. Tokens: warm Miyazaki-inspired palette with **colour-blind-safe pairs that always come with a shape/pattern**, rounded Cyrillic+Latin font, very large hit targets, spacing, animation timings, **audio tokens** (every tap has a sound; every instruction is voiced; no reading required). Components: BigButton, PictureCard, ChoiceRow, HintHand (hint ladder), DialogueBubble (Dialogic), ProgressStars, ParentGate, SessionTimer overlay. Screens: title, profile pick, world map, in-scene HUD, parent settings. **Rule kept: the agent must justify and get your OK before adding a new component.** |
| 1 | `specify` | **Adapt** | PRD = `spec.md`: goals, user stories (actors: *child, pre-reader, 3+* and *parent*), **learning objective** (which words/concepts), Given/When/Then ACs. Non-functional block pre-filled with our standing rules: no fail states, forgiving input, works with mouse/touch/gamepad, 30 fps + <10 s load on the Intel MacBook, fully offline, no external links/ads/purchases, 15-min session default. |
| 2 | `clarify` + `critic` | **Keep** | The autonomous critic looks for contradictions in the PRD. Add toddler-specific checks: "what happens if he mashes, walks away, picks wrong 5 times, holds a button down". |
| 3 | `ux-flows` + `screens` | **Merge → `ux-flows`** | One artifact: the Mermaid flow of how the child moves between scenes/states **plus** the per-state manifest (idle, hint level 1/2/3, success, wrong pick, paused, parent overlay). Error branches become *idle / wrong / mashing / walked away*. |
| 4 | `design` | **Adapt** | SAD in Arc42 with C4 + Mermaid. **Full route: all 12 sections. Standard: a "SAD-lite"** (§1 goals, §3 context, §4 strategy, §5 building blocks, §6 runtime, §9 decisions, §11 risks). Heavy decisions → ADRs. The 7 web "surfaces" are replaced by game **areas**: `core-system` (autoload), `scene`, `ui`, `content-data`, `audio-pipeline`, `tooling` (Python voice script, Blender scripts), `build`. |
| 5 | `sequences` | **Keep (folded into design)** | Mermaid sequence diagrams of signal flows, e.g. *Input → InteractionSystem → LearningTracker → SaveSystem → AudioDirector*. Becomes a step inside `design` instead of a separate stage. |
| 6–7 | `data-model` + `api` | **Merge → `contracts`** | Replaces SQL + OpenAPI with what a game actually has: (a) **save-file JSON schema** with `version` and a **migration function per version** (`migrate_v1_to_v2`) tested against fixture saves; (b) **word database schema** (columns the voice script and the tracker read); (c) content `Resource` classes for chapters/quests; (d) **autoload public APIs** (methods + signals) as `contracts/autoloads.md`. Living copies in `docs/contracts/`. Keeps the **drift check** as a separate agent (contracts ↔ data ↔ spec). The "developer must review migrations" rule stays as: **you review every save-format change** so his progress is never lost. |
| 8 | `tasks` | **Keep** | Atomic tasks + `tasks.json` DAG; each task file is self-contained (requirements, slice of contracts, ACs, checklist, DoD). Size rule becomes "one commit, fits comfortably in one agent context". Adds a Godot rule: tasks that edit the same `.tscn` are serialized. |
| 9 | `plan-tests` | **Adapt** | Tiers: **GUT unit**, **GUT integration** (scene + autoloads), **contract** (save fixtures round-trip, migrations, word DB validates), **scripted playthrough** (GUT drives input through a scene: the game's E2E), **performance check** (fps/load on the Intel MacBook, manual at gates), **playtest** (manual, at gates). Mutation testing: no mature GDScript tool, so a light "mutate-and-rerun" spot check by the reviewer on Full features only. Visual regression: cut for now. |
| 10 | `implement` | **Adapt** | TDD engine keeps the oracle fix: `test-author` writes the GUT test from ACs and **proves it fails**, `implementer` makes it pass. **New third agent `refactorer`** for conventions (as you described). Command detection gains a Godot branch: `godot --headless -s addons/gut/gut_cmdln.gd -gexit` (unit), `gdlint`/`gdformat --check` (lint), headless import/script check (vet). Docker probe, migration promotion and team/workflow parallel modes are cut. |
| 11 | `review` | **Adapt** | Clean-context Opus/Fable reviewer against spec + ACs + conventions. Adds review dimensions: **child safety** (no network, no links, no purchases, parent gate works), **toddler UX** (no reading needed, no dead ends, no punishment), **performance budget**, content tone. Optional **cross-vendor review** (Codex CLI) on Full features, via a small adapter note. |
| 12 | `ship` | **Replace "deploy" with "build + gate"** | Re-run GUT + lint, export the macOS build, run a scripted smoke scene, write changelog, open the PR on GitHub (never auto-merge). On the PR, external AI review (Claude GitHub review or Codex) if you enable it. Then the **artifact cleanup** (§6). |
| 13 | *post-deploy watch* | **Replace → New `playtest` skill** | Two modes. **Before:** writes a playtest checklist for the gate (what to watch: where he stops, looks to you, wrong clicks, wants to continue, words he repeats) into `docs/playtests/<date>-<gate>.md`. **After:** a `playtest-analyst` agent reads the game's **event log** (the timestamped click/idle/pick log from Phase 1) + your notes + any Godot error log, summarizes confusion points and bugs, and drafts `fix` tasks or a draft PR. This is our "20-minute watch". |
| — | `fix`, `glossary`, `decide-adr`, `classify-size`, `config` | **Keep** | `glossary` → `docs/CONTEXT.md` with UA/EN terms (word card, repetition box, hint ladder, password door…). `classify-size` gets the new signals (§2). `config` gets game defaults. |

Net result: **23 skills → 19** (2 merges, sequences folded in, +1 new `playtest`), all shorter.

## 4. Subagents and model roles

| Agent | Role | Model | Status |
|---|---|---|---|
| `explorer` | scan repo, logs, addons docs; return a short summary | Haiku | Keep |
| `researcher` | bounded web research (Godot docs, child-dev facts) with citations | Sonnet | Keep |
| `test-author` | write failing GUT tests from ACs | Sonnet | Keep (GUT-specific prompt) |
| `implementer` | make tests pass, run the gate | Sonnet | Keep (drop refactor duty) |
| `refactorer` | refactor to project conventions while staying green | Sonnet | **New** |
| `contract-checker` | drift between contracts, data files and spec | Sonnet | **New** (extracted from `api` drift check) |
| `playtest-analyst` | read event log + notes, find confusion points, draft fixes | Sonnet (Opus on Full) | **New** |
| `reviewer` | clean-context final review | Opus / Fable | Keep |
| `critic` | contradictions in PRD / SAD | Opus / Fable | Keep |
| `devils-advocate` | ambiguity + toddler failure modes | Opus / Fable | Keep |
| `strategist` + `analyst` | 3 approaches + multi-lens review | Opus | **Keep for Full only** (expensive; useful for core systems) |
| `pen-keeper` | Pencil design-file sync | — | **Cut** |

Context rules stay as the framework has them (they match your notes exactly): every agent starts with a clean context, gets everything it needs in its prompt, returns only a short report; `/clear` between stages because each stage re-reads its inputs from disk. Judgment agents default to Opus and never run below the session model (`judgment_model` setting; set it to `fable` if you want Fable for reviews).

## 5. Settings defaults for this project

`max_parallel_agents: 1`, `isolation: inplace`, `team_mode: false`, `workflow_mode: off` (solo project; Godot `.tscn`/`.import`/`uid` files conflict badly across parallel worktrees). `tdd: true`, `stop_on_red: true`, `gate_lint: true`. `artifact_language: en` (code, agents and the existing plan are English; can flip to `uk` per project). Commands pinned to the Godot ones from §3.

## 6. Artifact lifecycle

- While building: everything in `docs/features/<slug>/` (idea, spec, ux-flows, sad, adr, contracts drafts, tasks, test-plan, review records).
- At `ship`: ADRs are promoted to `docs/adr/`, contract changes are merged into the living `docs/contracts/`, and `tasks/`, `_review/`, `idea.md`, `test-plan.md` are deleted.
- What stays per feature: `spec.md` (PRD) and `sad.md`. The code is always the source of truth; docs that disagree with code get fixed, not the other way round.

## 7. What gets deleted outright

`.claude-plugin/`, `.codex-plugin/`, `.agents/`, `install.sh`, `CONTRIBUTING.md`, `assets/` (framework logo), the framework `README.md` (→ `docs/workflow.md` + a short game README), `evals/` (they test the framework itself with web fixtures; we can add 2–3 game-specific evals later if a skill misbehaves), `agents/pen-keeper.md`, `skills/_shared/tool-adapters.md` (kept only as a short Codex-review note), and the Figma/Pencil, OpenAPI, SQL migration, Docker and team/workflow-mode references. `scripts/validate_plugin.py` is **repurposed** into a link/frontmatter checker for `.claude/skills/`, because the rename will touch hundreds of cross-links. The `sdd-main.zip` in `projects/` stays untouched as the pristine original.

## 8. Rollout order (each step = one commit)

1. **Restructure:** move `skills/` → `.claude/skills/`, `agents/` → `.claude/agents/`; rewrite `sdd:<name>` → `<name>` and `/sdd:x` → `/x` everywhere; delete §7 files; repurpose the validator and make it pass.
2. **Shared policy:** rewrite `size-matrix.md` (§2), `agent-roster.md` (§4), replace `surfaces.md` with game areas, settings defaults (§5), Godot command detection.
3. **Merges:** `data-model`+`api` → `contracts`; `ux-flows`+`screens` → `ux-flows`; fold `sequences` into `design`.
4. **Stage rewrites + templates:** survey (Godot architecture map + few-shot), design-system (toddler canon), specify (NFR block), plan-tests (tiers), review (dimensions), ship (build + cleanup).
5. **New pieces:** `refactorer`, `contract-checker`, `playtest-analyst` agents; `playtest` skill.
6. **Entry docs:** `CLAUDE.md`, `docs/workflow.md`, export the game spec + development plan into `docs/`.
7. **Dry run on real work:** `/scaffold` = Phase 0, then one Standard feature (the greybox "drive to the marker") end to end; fix the rough edges the run exposes.

Rough effort: 2–3 sessions for steps 1–6, then the dry run is normal Phase 0/1 work.

## 9. Decisions for you

1. **OK to restructure and delete** per §1 and §7? (Nothing is changed until you say yes.)
2. **Artifact language:** English (recommended, matches the plan and code) or Ukrainian?
3. **Cross-vendor review:** do you have Codex (or another vendor) available, or should reviews stay Claude-only (clean context + Opus/Fable)?
4. **Git remote:** the copied repo already points at `github.com/rodergstep/arbuz`. Keep that as the game's remote (it would also settle the open "where the Git remote lives" question in the plan)?
