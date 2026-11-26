# Size matrix — Quick / Standard / Full routes for a Godot game

> **Reference-only.** Not a skill. `classify-size` owns this matrix; every other skill reads it
> to decide how much of its artifact to produce and which optional stages may be skipped.

## The primary dial: the route

Every feature gets a **route** — `quick`, `standard` or `full` — in
`docs/features/<slug>/.route`, plus a finer **size** (`XS`/`S`/`M`/`L`/`XL`) in `.size`.
Both are one bare word, no comments (wrappers grep them). The route is what the human sees and
confirms; the size only tunes artifact depth inside a route.

| Route | Default for size | Typical work in this game | Who decides skips |
|---|---|---|---|
| `quick` | XS, S | tune a value (car speed, hint delay), rename, swap a sound/texture/voice line, fix a button, a small bug | the stage itself auto-skips N/A stages and says why |
| `standard` | M | a new mini-game/activity, a new scene or location, a new UI screen, a new hint behaviour, a voice-pipeline change, a chapter's content | the stage **proposes** the skip; **the human decides** |
| `full` | L, XL | a new core system (learning tracker, save system, interaction system, quest engine), **any change to the save format or word DB schema**, child safety (parent gate, session timer, anything that could expose the child to a link/purchase/network), a new language-arc pipeline, a change to an autoload API used by many scenes | nothing is skipped |

## How to classify (the four game signals)

`classify-size` asks these four, one question each:

| Signal | XS | S | M | L | XL |
|---|---|---|---|---|---|
| **Save format / word DB schema** | untouched | untouched | read-only use | changed (→ at least L) | new format / new store |
| **Core systems / autoload API** | none | uses existing | adds a method/signal | changes a public API or adds an autoload | new subsystem |
| **What the child sees, hears or can reach** | cosmetic | one interaction | a new activity/screen | a new flow, or anything safety-related (→ at least L) | a new chapter/arc |
| **Breadth + how it is judged** | 1 file, judged by a test | a few files | several scenes, needs a quick look in-game | many scenes, needs a playtest | many sessions, needs its own roadmap step |

Hard rules (they override the table):
- **Save format or word DB schema changes → `full`.** Losing the child's progress is this
  project's "production data loss".
- **Child safety or privacy → `full`.** Parent gate, session timer, network, links, purchases,
  recordings, the child's name or photo.
- **A change to an autoload's public API used by more than one scene → at least `standard`.**

On an edge case, name the dominant signal: «Standard because it adds a new activity scene, even
though it touches only one autoload method».

> **One-sentence rule.** If you hesitate between two routes, take the heavier one for anything that
> touches saves or safety, and the lighter one for everything else.

## What each route runs

Never skippable on any route: `specify` (the trace anchor), `tasks` (`implement` consumes
`tasks.json`), `implement`, `review`, `ship`. `design` is skippable **only on `quick`**, and only
when no core system, autoload API or scene architecture changes.

| Stage | `quick` | `standard` | `full` |
|---|---|---|---|
| `interview` (idea.md) | — | optional | yes |
| `specify` | lite: 1–3 ACs, NFR block inherited | yes | yes + ideation suite |
| `clarify` | auto-skip if zero open questions | skip offered | yes |
| `ux-flows` | auto-skip if nothing child-facing changes | skip offered if N/A | yes when any UI/scene changes |
| `design` | auto-skip if no system/API change | SAD-lite | full Arc42 (12 sections) |
| `contracts` | only if a contract changes | skip offered if N/A | yes + `contract-checker` |
| `tasks` | yes (often 1–3 tasks) | yes | yes |
| `plan-tests` | inline in spec | inline or separate | separate file |
| `implement` | yes | yes | yes |
| `review` | yes | yes | yes + Codex cross-review |
| `ship` | yes | yes | yes |
| `playtest` | — | when the feature reaches a gate | yes |

Bugs go through `fix` instead (it is its own quick lane).

### The N/A conditions (when a skip is legal)

Every condition is «skip when N/A», never «skip always»: a quick tweak that changes the save
format still runs `contracts`, and is no longer quick.

| Stage | Skip when | Evaluated by |
|---|---|---|
| `clarify` | the spec has **zero §8 open questions** and no AC was flagged ambiguous | `specify`'s handoff |
| `ux-flows` | **nothing the child or parent sees or does changes** (pure logic, tooling, data pipeline) | `clarify`'s handoff (`specify`'s when clarify was skipped) |
| `design` | `quick` only: **no core system, autoload API or scene-architecture change** | `ux-flows`' handoff |
| `contracts` | **no contract change**: save schema, word DB columns, content `Resource` classes, autoload public methods/signals, tool CLIs all untouched | `design`'s handoff |
| `plan-tests` | never fully skipped — collapses to the inline `## Test plan` in `spec.md` | `tasks`' handoff |

When several consecutive stages are N/A, walk the conditions in order and jump to the first stage
whose condition does not hold.

### Route behaviour at a handoff

| Route | What the handoff does |
|---|---|
| `quick` | evaluates the N/A condition itself; holds → auto-skip with the reason, and the `↳ or` line offers the skipped stage instead |
| `standard` | names the next stage and offers the skip as `↳ or` when the N/A condition holds; the human picks |
| `full` | no skip line, ever |

Missing `.route` → behave as `standard` and say so in the handoff. The route steers handoffs only;
a stage invoked directly always runs. To change route mid-flight, re-run `/classify-size <slug>`.

## Artifact depth by size

| Artifact | XS/S | M | L/XL |
|---|---|---|---|
| `idea.md` | — | optional | yes |
| `spec.md` | yes (lite) | yes | yes |
| `ux-flows.md` | if UI | if UI | yes |
| `sad.md` | none, or SAD-lite | SAD-lite (§1, §3, §4, §5, §6, §9, §11) | all 12 Arc42 sections |
| ADRs | 0–1 | 1–3 | 3–8 |
| `contracts/` | if touched | if touched | yes |
| `tasks/` + `tasks.json` | yes | yes | yes |
| test plan | inline in spec | inline or file | separate `test-plan.md` |

A stage that finds no `.size` defaults to **M** and says so in its handoff — never silently.
