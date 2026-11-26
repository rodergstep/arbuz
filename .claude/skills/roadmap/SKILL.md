---
name: roadmap
model: inherit
effort: medium
agents: []
description: >
  Use to break the game idea into incremental steps and keep that decomposition living: one
  docs/roadmap.md with a destination sentence, the steps table (source-anchored, sized XS–XL or
  marked fog), the fog vocabulary (in scope but not yet formulated, out of scope, open decisions),
  the dependency graph that owns every edge, and the build order grouped into the development-plan
  phases with exit gates. Triggers on "roadmap", "break this down", "what depends on what",
  "what's next", "/roadmap", "роадмап", "розбий ідею на кроки", "що від чого залежить",
  "що робити далі". Takes any scope: the whole game, a chapter, or one feature. Reads
  docs/game-spec.md, docs/development-plan.md and any docs/features/<slug>/idea.md. It decomposes
  and orders; it is NOT a scorecard and NOT a dated Gantt.
---

# Skill: roadmap

The **decomposition layer** between the idea and the per-feature pipeline. SDD builds one feature
at a time under `docs/features/<slug>/`; `roadmap` answers the question that comes *before* any
feature: **where are we going, how does the idea break into steps, what depends on what, and in
which order do we walk them, phase by phase.** One living `docs/roadmap.md`,
repo-level utility (like `survey`).

**Scope is whatever you bring.** A whole product, one epic, or a single feature — the unit of the
input does not change the unit of the output. A one-feature request gets decomposed the same way;
there are simply fewer steps, and «fewer» is a legitimate answer. The skill never refuses a request
for being too small, and never inflates one to look like a product plan.

Five load-bearing properties, in priority order:

1. **A destination** — one sentence for what is true once the last step ships. Without it the
   steps are a list of work with nothing to be a decomposition *of*.
2. **Steps** — the idea decomposed into incremental, source-anchored slices (each row cites the
   game-spec / development-plan / idea section it comes from; size XS–XL per [`../_shared/size-matrix.md`](../_shared/size-matrix.md)).
3. **A word for what you don't know yet.** `Size` is `XS…XL` **or** `fog`, in the same cell,
   because they answer the same question and only one of them can be true: sizing something nobody
   has formulated yet is how an estimate becomes a lie. Fog lives in `## Not yet specified` until a
   recon pass sharpens it, and then the row trades `fog` for a real size.
4. **Dependencies** — an explicit graph, and the graph is where edges live. Every edge has a
   one-line reason (data model, UI zone, auth precondition). No edge without a real blocker, and no
   second copy of the edges in a column that could disagree with it.
5. **Build order by phase** — the steps in a dependency-respecting order, grouped under the
   phases of `docs/development-plan.md`, each phase with its exit gate (what must be true, and
   checked with the child where relevant, before the next phase starts). Work is solo and
   sequential, so there are no parallel lanes.

**Not here:** RICE or any scoring (order IS the prioritization), dates (a decomposition, not a
promise), solution detail (lives in the feature's spec). Question phrasing →
[`../_shared/ask-style.md`](../_shared/ask-style.md).

## Owner

The parent (solo maintainer), who owns the game's direction.

## Inputs

- **Required** — at least one idea source: `docs/game-spec.md`, `docs/development-plan.md`, or a
  `docs/features/<slug>/idea.md` (written by [`interview`](../interview/SKILL.md)). This is the only hard input.
- **Optional** — `docs/architecture-map.md` (written by [`survey`](../survey/SKILL.md)): which systems already exist.
- **Optional** — `docs/design-system.md`.
- **Optional** — existing `docs/features/*/` + existing `docs/roadmap.md` — current statuses.

## Protocol

1. **Ensure the settings file (first thing, after this skill's own gate).** If `.claude/sdd.local.md` is
   absent, create it now from the canonical template — documented defaults + the self-documenting
   body — and patch `.gitignore`; if it exists, read it and never overwrite. The one procedure
   lives in [`../_shared/settings-file.md`](../_shared/settings-file.md). Creating is
   unconditional; **changing values is only ever offered by [`config`](../config/SKILL.md)**. Say
   one line: «`.claude/sdd.local.md` created with documented defaults — `/config` to tune it».
   **Then locate sources.** Find the idea sources (`docs/game-spec.md`, `docs/development-plan.md`, `docs/features/*/idea.md`).
   None found → say so and STOP: a roadmap without a source is fiction, and the fix is one
   command — `/interview` writes that brief. **That is the only hard stop.**

   `docs/architecture-map.md` is **optional and never a gate**. Present → its module inventory
   tells you which systems already exist, so steps can be cut against real code. Absent → the
   roadmap is written anyway and the handoff suggests `/survey`.

   **Greenfield (`docs/architecture-map.md` says `mode: greenfield-bootstrap`, or an empty repo with no `docs/features/*` besides `_scaffold/`): the first step is `scaffold`** — unless its `scaffold: materialize skeleton` commit already exists, then it is marked done. Every
   other step assumes a skeleton to build into — a repo with no module layout, no test harness and
   no save system cannot receive step 1 as written. Its source anchor is the foundation
   section of `docs/architecture-map.md` when the map exists, otherwise the brief itself (the
   project has to exist before anything in the brief can be built).

   If `docs/roadmap.md` exists, this run **updates** it (statuses, new steps, re-ordering), never
   silently rebuilds it.

2. **Decompose — yourself, with the owner.** Cutting an idea into steps is a live exchange with
   the person who holds the intent; it is not delegable, and a subagent standing in for the
   owner's half of it produces a plausible decomposition of a misunderstood idea. Read the sources
   and draft the steps under these rules:

   1. **Every step traces to a source.** Each row cites the section that justifies it
      (`game-spec.md §Colours`, `development-plan.md Phase 2`, `idea.md §2`). No anchor → the step does not exist. Never invent
      scope the sources don't support.
   2. **Steps are increments, not layers.** A step is a walkable slice that leaves the product
      demonstrably better for the child (scene + logic + content + audio as needed), never
      «the save system», «all the UI», «tests».
   3. **Dependencies are edges, not vibes.** An edge names two step ids and has a reason you could
      defend in one line. Edges live in `## Dependency graph` and nowhere else — a step with no
      real blocker has no edge.
   4. **Fog is a size value, not a second column.** Ask the Pocock test of each step: *can you
      state the question precisely right now?* — not «can you answer it». No → the step's `Size`
      cell reads `fog`, and the substance goes to `## Not yet specified` as **one area**. Because
      fog and XS–XL share one cell, «the unformulated thing got sized anyway» stops being possible
      to write down. Do NOT pre-chop fog into ticket-sized pieces; that's inventing structure for
      something you haven't looked at yet.
   5. **Size, don't score.** Size every non-fog step XS–XL per
      [`../_shared/size-matrix.md`](../_shared/size-matrix.md). No RICE, no priority numbers, no
      dates — order IS the prioritization.
   6. **Existing state is respected.** A step whose `docs/features/<slug>/` already exists keeps
      its real status (spec'd / building / shipped); never re-plan shipped work.
   7. **Name the destination.** One sentence in `## Destination` for what is true about the product
      once the last step ships. Write it before the steps and check it after: a step that moves
      nothing toward that sentence is scope that snuck in.

3. **Close the AFK questions in parallel.** Decomposition throws off two kinds of question. The
   ones that need the owner's judgment («is this in scope», «which of these matters more») you ask
   in step 4 — nobody can answer them for them. The ones that are just **lookup** («where does X
   live», «what format does the exporter emit», «is there already a library for this», «do steps 3
   and 5 actually touch the same file») are AFK work, and today nobody does them: they get guessed
   at, and the guess becomes a dependency edge.
   For each such question, spawn one subagent — `subagent_type: "general-purpose"` (or the host's
   `Explore` for code-only lookups), tools **Read,
   Grep, Glob, Bash, WebSearch, WebFetch** — **all in one message so they run concurrently**, one
   agent per question. Wrap each with the worker preamble from
   [`../_shared/agent-roster.md`](../_shared/agent-roster.md) and demand a fixed shape back:
   **one line of answer + one citation** (`file:line` or a URL). Uncited → dropped, and the
   question moves to `## Open decisions` with type `research`. Zero AFK questions → skip this step
   and say so; do not manufacture questions to have something to fan out.

4. **Review with the owner.** Present the draft **in prose** (destination + steps + fog + phases;
   the mermaid goes to the file, never dumped raw to the terminal — same rule as `design`), calling
   each step by its name rather than its id. Then **one `AskUserQuestion` call**: (a) steps to
   merge/split/drop (multiSelect over flagged candidates + the questions step 3 could not close),
   (b) confirm the order and phase gates, or name what must move. Apply — **writing as you go**: copy
   [`./templates/roadmap.md`](./templates/roadmap.md) to `docs/roadmap.md` (an existing roadmap is
   edited in place, never re-bootstrapped) with the destination, then write each step row, edge and phase **as soon as the owner's answer settles it**, never the whole file at the end
   ([`../_shared/write-and-commit.md`](../_shared/write-and-commit.md) §1).

5. **Ask whether the file is worth keeping.** If the pass surfaced **no fog** — every step is
   sized, `## Not yet specified` is empty, `## Open decisions` is empty — then say so and put the
   choice to the owner: a three-row file restating an already-clear plan is one more thing to keep
   current, and the alternative is to build straight from `/specify <slug>`. **It is their
   call, not a stop.** They want the file as a shared reference — write it. Say the tradeoff once,
   plainly, and take the answer; never refuse to write a roadmap because the request was small or
   clear. They decline → delete the `docs/roadmap.md` **this run created** (never a pre-existing
   one), commit nothing, and hand off straight to `/specify <slug>`.

6. **Complete.** Fill what is still placeholder in `docs/roadmap.md` (fog vocabulary, decisions so
   far, the mermaid graph); set `updated_at`.

7. **Structural self-check** — per [`../_shared/self-check.md`](../_shared/self-check.md), re-read
   from disk, verify **6 items**:
   1. Every step row carries a source anchor, **and the anchor resolves**: the named document
      exists and the cited section is greppable in it (`grep -F "<section>" <doc>`). Text in the
      column is not evidence — a source anchor nobody checked is how invented scope gets in.
   2. **Every graph edge names two existing step ids**, and no step comes before any of its
      dependencies in `## Build order`.
   3. **`## Destination` is present and is one sentence** — not a bulleted list, not a paragraph of
      goals. One sentence, or the section has failed at the only job it has.
   4. Every phase in `## Build order` has an exit gate, and every non-fog, non-shipped step
      appears in exactly one phase.
   5. **Every closed enum holds.** `Size ∈ {XS, S, M, L, XL, fog}` — and every `fog` row points
      into `## Not yet specified` and carries no XS–XL anywhere. `Status ∈ {idea, spec'd, building,
      shipped}`, and every spec'd+ step links an existing `docs/features/<slug>/` (`test -d`). In
      `## Open decisions`, `Type ∈ {research, prototype, grilling, task}` and `Owner ∈ {agent,
      human}` — a role, never a person's name. The frontmatter carries exactly the template's keys,
      none invented.
   6. Zero dates outside `## Shipped` (`\b20\d\d-` scan) and `updated_at` = today.

   Fix + re-check ≤2 cycles; surface the rest.

8. **Commit + handoff.** After the self-check passes, commit per
   [`../_shared/write-and-commit.md`](../_shared/write-and-commit.md) — one commit,
   `roadmap: roadmap.md <what changed>`; an unresolved self-check item → no commit. **Invoked
   in-flow** (a `specify` / `implement` / `ship` sync hook below) → don't commit here: the caller
   commits `docs/roadmap.md` as its own document, after its own self-check, under its own message.
   Then emit the **stage-handoff block** per [`../_shared/handoff.md`](../_shared/handoff.md)
   (utility variant) — *What I did*
   (incl. «self-check: 6/6 pass», the fog count and the commit SHA) + *Review* (`docs/roadmap.md`) + *Run next*:
   **name the first unblocked step the way the file names it, then give the command on its own
   line, ready to run** — `/specify <slug>` for that step, `/scaffold` when the first step
   is the greenfield skeleton, or a recon pass on the top `## Not yet specified` area when the
   first thing in the way is fog rather than work. When the run had no architecture map, add one
   line suggesting `/survey`.

## Sync hooks (delivery keeps it current — anti-drift)

- **`specify`** sets the step's `Status` to **spec'd** and links `docs/features/<slug>/`. A spec'd feature with no step row gets one appended (source
  anchor = its spec). A step cannot go `spec'd` while its `Size` reads `fog` — specifying it *is*
  what clears the fog, so the hook replaces `fog` with a real size in the same edit.
- **`implement`** sets the step's `Status` to **building** at its start and commits that one-line
  change (`implement: <slug> roadmap.md building`) before the first task.
- **`ship`** sets `Status: shipped` and adds the date + PR link to **Shipped**.
- Neither hook re-orders the graph — structure changes only happen here, with the owner.

## Definition of Done

- `docs/roadmap.md` exists: a one-sentence `Destination`, the steps table (every row
  source-anchored + sized XS–XL or `fog` + status), the fog vocabulary (`Not yet specified` ·
  `Out of scope` · `Open decisions`), `Decisions so far` as gists-with-links, the dependency graph
  that owns every edge, and the build order grouped by phase with exit gates.
- No scores, no dates outside Shipped; no XS–XL on a `fog` row; `updated_at` current.

## Anti-patterns

- **A prioritization scorecard.** No RICE/effort-value math here — decomposition and order are
  the deliverable. If the owner wants scoring, that's a separate conversation, not this file.
- **A dated Gantt / roadmap-as-promise.** Zero dates outside Shipped; the disclaimer stays.
- **Horizontal steps** («the save system», «all the UI», «testing») — steps are vertical increments.
- **A roadmap with no destination.** Twelve rows and no sentence saying what they add up to. The
  steps then can't be wrong, because there's nothing for them to be wrong about.
- **Phantom dependencies.** An edge you can't justify in one line distorts the order.
- **A phase with no gate.** «Phase 2 done» must be checkable, e.g. «the child finishes the
  colours chapter twice without help».
- **Sizing the fog.** A one-line step marked `L`, `spec'd`, one edge — and underneath it nine
  undecided things. The size was invented, the status was wrong, and the roadmap's unit was too
  coarse to say so. `Size: fog` is the honest cell.
- **Refusing the small request.** «This is one feature, you don't need a roadmap» is not an
  answer — it is a two-step roadmap. Say the tradeoff, then do what the owner asks.
- **Stopping on a missing architecture map.** The decomposition does not depend on it.
- **Restating a decision instead of linking it.** `## Decisions so far` is a gist plus a link to
  where the decision actually lives (the ADR, the spec, the thread). A paragraph of solution
  detail copied in here is a second source of truth that will drift.
- **Delegating the decomposition.** A subagent has the same files and less context than you, and
  it cannot have the exchange with the owner that the cut depends on. Fan out the lookups
  (step 3), keep the judgment.
- **Re-planning shipped work / duplicating specs.** Shipped rows are history; solution detail
  lives in `docs/features/<slug>/`.

## References & template

- [`./templates/roadmap.md`](./templates/roadmap.md) — the decomposition scaffold.
- [`../_shared/size-matrix.md`](../_shared/size-matrix.md) — XS–XL sizing heuristics.
- [`../_shared/agent-roster.md`](../_shared/agent-roster.md) — the shared contract every fanned-out
  question-closer follows.
