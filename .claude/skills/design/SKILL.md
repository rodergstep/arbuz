---
name: design
model: inherit
effort: high
agents: [explorer, critic]
description: >
  Use to write the Solution Architecture Document for a feature — Arc42 (full: 12 sections;
  SAD-lite on standard), C4 Context/Container and the runtime sequence diagrams in Mermaid,
  plus ADRs for the decisions that are expensive to reverse. Declares which game areas the
  feature touches (core-system, scene, ui, content-data, audio-pipeline, tooling, build).
  Triggers on "design {slug}", "architecture for {slug}", "SAD for {slug}", "sequence diagram
  for {slug}", "/design {slug}", "архітектура для {slug}", "спроєктуй {slug}". Hard-refuses
  without spec.md.
---

# Skill: design

Writes `docs/features/<slug>/sad.md` (Arc42 + C4 + Mermaid sequences) and
`docs/features/<slug>/adr/NNNN-*.md`. Mermaid is used everywhere because it is text: the agent
can read and edit it as easily as code. The runtime view (§6) is drawn here too: one
`sequenceDiagram` per critical flow, e.g. *input → InteractionSystem → LearningTracker →
SaveSystem → AudioDirector*.

Shared machinery: [`../_shared/socratic-loop.md`](../_shared/socratic-loop.md) ·
[`../_shared/critic.md`](../_shared/critic.md) · [`../_shared/size-matrix.md`](../_shared/size-matrix.md) ·
[`../_shared/ask-style.md`](../_shared/ask-style.md) · [`../_shared/interview-depth.md`](../_shared/interview-depth.md) ·
[`../_shared/diagram-presentation.md`](../_shared/diagram-presentation.md) ·
[`../_shared/mermaid-check.md`](../_shared/mermaid-check.md) · [`../_shared/game-areas.md`](../_shared/game-areas.md).

## Two modes

| Mode | When | Sections |
|---|---|---|
| **SAD-lite** | route `standard`, or `quick` when design isn't skipped | §1 goals, §3 context (C4 Context), §4 strategy (+ areas), §5 building blocks (C4 Container), §6 runtime (sequences), §9 decisions, §11 risks. Others are written as `<!-- N/A: SAD-lite -->`. |
| **Full** | route `full` | all 12 Arc42 sections |

The human may switch mode at the depth question.

## Inputs

- `<slug>`.
- **Gate (hard refuse):** `docs/features/<slug>/spec.md` → «run `/specify <slug>` first».
- (Optional) `docs/features/<slug>/ux-flows.md` — evidence for areas and building blocks.
- (Expected) `docs/architecture-map.md` — the current system: autoloads, folders, conventions,
  pattern few-shots. If stale (`reflects_commit` far behind HEAD) or absent, dispatch `explorer`
  for the parts this feature touches and suggest `/survey`.
- `docs/CONTEXT.md` (+ the feature's `CONTEXT.md`), living `docs/contracts/` and `docs/adr/`.
- `.size`, `.route` (absent → M / standard, said in the handoff).

## Protocol

1. **Gate, size, depth, mode.** Read `.size` / `.route`. Resolve depth (`--depth=` or one
   question; on `quick` recommend `easy`). Announce the mode (lite / full).
2. **Read upstream.** Spec §2 goals, §3 non-goals, §6 NFRs (fps, load time, input, offline,
   safety), §8 open questions; `ux-flows.md`; the architecture map; living contracts and ADRs.
3. **Bootstrap** `sad.md` from [`./templates/sad.md`](./templates/sad.md); stamp frontmatter.
4. **Draft in memory, then walk section by section** with the shared 4-state machine. Sourcing per
   section → [`./references/draft-generation.md`](./references/draft-generation.md); design's
   delta → [`./references/socratic.md`](./references/socratic.md). **§4 opens with the areas
   decision**: which of the seven game areas the feature touches; write `areas: [...]` to the
   frontmatter as soon as it resolves. Run the **blast-radius gate** on every approved decision
   (2 of 3: irreversible / seen by ≥2 systems or scenes / a real alternative exists → ADR) →
   [`./references/blast-radius.md`](./references/blast-radius.md). Write each resolved section and
   its ADRs to disk immediately; never return to a written section.
5. **Diagrams.** §3 C4Context and §5 C4Container (syntax →
   [`./references/c4-mermaid-syntax.md`](./references/c4-mermaid-syntax.md)); §6 one
   `sequenceDiagram` per critical flow from [`./templates/sequence.md`](./templates/sequence.md),
   with participants named after real autoloads/scenes. **Every §5 AC is shown by a flow, a
   branch, or an explicit N/A** (a coverage table under §6). Write → validate → describe in prose
   → confirm (easy: summary + proceed).
6. **Critic + finalize.** Dispatch `critic` (`subagent_type: "critic"`, `judgment_model`, `xhigh`
   on `full`) with [`./references/critic.md`](./references/critic.md); resolve findings with the
   human. Backstops: every Mermaid block parses; ADR titles in decision form with `Status:
   Accepted`; §9 closed against `adr/`; no `<placeholder>` left. These are this skill's
   **structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)).
7. **Commit + handoff.** One commit per ADR (`design: <slug> ADR-NNNN <title>`), one for `sad.md`.
   Handoff per [`../_shared/handoff.md`](../_shared/handoff.md): forward `/contracts <slug>`; its
   N/A condition (no contract change) → `/tasks <slug>`, resolved per `.route`.

## Definition of Done

- `sad.md` written in the announced mode; `areas` frontmatter non-empty; §3/§5 real C4 blocks;
  §6 sequences cover every AC (flow, branch or N/A).
- ADRs: lite 1–3, full 3–8 typical; each `Accepted`, decision-form title, no strawman options.
- §10 (full) cites spec NFR numbers verbatim (e.g. «≥30 fps on the Intel MacBook»).
- §11 has a row with owner + due for every deferred decision.

## Anti-patterns

- **An ADR for every decision.** Only the expensive-to-reverse ones.
- **Architecture by scene tree.** The SAD decides which autoload owns state and which signals
  cross scenes; it doesn't list nodes.
- **Logic in a scene that another scene needs** without making it a system (or vice versa: a new
  autoload for something only one scene uses).
- **Inventing performance numbers** the spec doesn't have.
- **Raw Mermaid as the confirmation prompt.**
