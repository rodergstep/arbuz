# The development workflow

How a feature goes from an idea to a build the child plays. Skills live in `.claude/skills/`, agents in `.claude/agents/`. Every stage writes a file, commits it, and tells you the next command.

## Once per project

| Step | Command | Output |
|---|---|---|
| Map the codebase (or plan the foundation on an empty repo) | `/survey` | `docs/architecture-map.md` |
| Create the skeleton (Godot project, GUT, lint, export preset) | `/scaffold` | a booting project with one passing test |
| Design system | `/design-system` | `docs/design-system.md` |
| Roadmap from the game spec and development plan | `/roadmap` | `docs/roadmap.md` |
| Tune settings (optional) | `/config` | `.claude/sdd.local.md` (gitignored) |

## Per feature

| # | Stage | Command | Writes (under `docs/features/<slug>/`) | Who checks |
|---|---|---|---|---|
| 0 | Size it | `/classify-size <slug>` | `.route`, `.size` | you confirm the route |
| 1 | Interview | `/interview` | `idea.md` | `researcher`, `devils-advocate` as needed |
| 2 | Spec (Given/When/Then) | `/specify <slug>` | `spec.md` | `critic`; on full also `strategist`, `analyst` |
| 3 | Clarify | `/clarify <slug>` | edits `spec.md` | `devils-advocate` (ambiguity) |
| 4 | UX flows + screen states | `/ux-flows <slug>` | `ux-flows.md` | `devils-advocate` (toddler); you approve NEW components |
| 5 | Architecture (Arc42, C4, sequences, ADRs) | `/design <slug>` | `sad.md`, `adr/` | `critic` |
| 6 | Contracts | `/contracts <slug>` | `contracts/*.md` | `contract-checker`; **you approve save-format changes** |
| 7 | Task graph | `/tasks <slug>` | `tasks/`, `tasks.json` | self-check |
| 8 | Test plan | `/plan-tests <slug>` | `test-plan.md` (or inline) | self-check |
| 9 | Build with TDD | `/implement <slug>` | code + tests, one commit per task | `test-author` → `implementer` → `refactorer`, then the gate |
| 10 | Review | `/review <slug>` | `_review/review-<date>.md` | `reviewer` (clean context); on full also Codex |
| 11 | Ship | `/ship <slug>` | `CHANGELOG.md`, promoted ADRs and contracts, the PR | you push and merge |
| 12 | Playtest | `/playtest <slug> before` / `after` | `docs/playtests/<date>-<slug>.md` | `playtest-analyst` |

Bugs: `/fix <slug>` (reproduce → failing test → minimal fix → spec patch). Decisions made outside `/design`: `/decide-adr`. Terms: `/glossary`.

## Routes

| Route | When | What runs |
|---|---|---|
| `quick` | tune a value, swap a sound, small bug | spec-lite → tasks → implement → review → ship; other stages auto-skip |
| `standard` | a new activity, scene, screen or chapter content | everything; optional stages offer a skip, you decide |
| `full` | a core system, **any save-format or word-DB change**, **anything about child safety** | everything, plus ideation, contract-checker and Codex review |

Full table: [`.claude/skills/_shared/size-matrix.md`](../.claude/skills/_shared/size-matrix.md).

## Models

Haiku scans (`explorer`). Sonnet writes tests, code and refactors. Opus judges and reviews (`reviewer`, `critic`, `devils-advocate`, `strategist`, `analyst`). Change it with `/config`. Details: [`.claude/skills/_shared/agent-roster.md`](../.claude/skills/_shared/agent-roster.md).

## Context hygiene

- Run `/clear` between stages. Every stage re-reads what it needs from disk.
- Heavy reading and every judgment run in subagents with a clean context, so the main session stays small and unpoisoned.
- The reviewer never sees the conversation that wrote the code.

## What stays after release

Code is the source of truth. At ship: ADRs move to `docs/adr/`, contract deltas merge into `docs/contracts/`, and `spec.md` + `sad.md` (+ `ux-flows.md`) stay in the feature folder marked shipped. `idea.md`, `tasks/`, `test-plan.md` and `_review/` are deleted; git history keeps them.

## Codex

On the full route `/review` runs `codex exec --sandbox read-only` as a second-vendor reviewer and merges its cited findings. On any PR you can also comment `@codex review`. See [`.claude/skills/_shared/codex-review.md`](../.claude/skills/_shared/codex-review.md).
