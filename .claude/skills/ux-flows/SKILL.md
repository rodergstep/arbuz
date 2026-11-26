---
name: ux-flows
model: inherit
effort: medium
agents: [devils-advocate]
description: >
  Use to draw how the child (and the parent) move through a feature — scene-to-scene and
  state-to-state flows in Mermaid — plus the per-state manifest every scene/screen must
  implement (idle, hint levels, success, wrong pick, paused, parent overlay), composed from the
  design-system components. Runs after clarify, before design. Triggers on "ux flows for {slug}",
  "flows for {slug}", "what does he see when", "scene states for {slug}", "/ux-flows {slug}",
  "флоу для {slug}", "як дитина проходить {slug}", "стани екрану". Hard-refuses without spec.md.
---

# Skill: ux-flows

Draws **how the child moves** through a feature and **what every state looks and sounds like**.
One artifact, two parts:

1. **Flows** — a Mermaid `flowchart` per child-facing user story: the happy path plus the toddler
   branches the ACs demand (*idle*, *wrong pick*, *mashing*, *walked away*, *parent steps in*).
2. **State manifest** — every scene/screen the flows visit (`SCR-NN`) in every state it can be in,
   with the design-system components it uses and the voice/sound for each state.

`design` reads it as evidence; `tasks` cites `SCR-NN` + state ids; `implement` builds to the
states; `review` checks the built scene against them; `plan-tests` turns each flow into a
scripted playthrough.

Question phrasing → [`../_shared/ask-style.md`](../_shared/ask-style.md); confirm each diagram in
prose, never as raw Mermaid → [`../_shared/diagram-presentation.md`](../_shared/diagram-presentation.md);
validate per [`../_shared/mermaid-check.md`](../_shared/mermaid-check.md).

**Optional by content, not size:** the N/A condition (nothing the child or parent sees or does
changes) is in [`../_shared/size-matrix.md`](../_shared/size-matrix.md). Invoked directly, it runs.

## Inputs

- `<slug>`.
- **Gate (hard refuse):** `docs/features/<slug>/spec.md` → «run `/specify <slug>` first».
- (Expected) `docs/design-system.md` — the components, tokens, input rules and audio rules every
  state must compose. Absent → not a block: draft with the toddler defaults from the
  design-system template and recommend `/design-system` in the handoff.
- (Optional) `docs/CONTEXT.md` + the feature `CONTEXT.md`; `.size` / `.route`.

## Protocol

1. **Gate + read.** Spec §1, §4 (which stories are child-facing or parent-facing), §5, §6 NFRs;
   `docs/design-system.md` (components, input rules, hint ladder, audio rules).
2. **Depth.** `interview_depth` (or `--depth=`), one question per
   [`../_shared/interview-depth.md`](../_shared/interview-depth.md). Coverage never shrinks.
3. **Draft the flows.** For each child-facing or parent-facing user story, one flow: the happy path
   and a branch for every relevant AC. Every child flow must answer, with a node or an explicit
   N/A: **what happens if he does nothing for a while** (the hint ladder), **picks wrong**,
   **mashes buttons / taps everywhere**, **walks away mid-activity** (auto-pause, resume state),
   **wants out** (how a session ends). There are no fail states: every branch leads back to
   progress. Collect every scene/screen visited into the inventory (`SCR-NN`).
4. **Toddler pass (separate agent).** Dispatch `devils-advocate` (`subagent_type:
   "devils-advocate"`, mode: `toddler`) with the path of the draft and the spec. It returns cited
   gaps: dead ends, states that need reading, targets too small or too close, a branch that
   punishes, audio missing for an instruction. Resolve each with the human.
5. **State manifest.** For every `SCR-NN`, list its states (`default`, `idle-hint-1/2/3`,
   `success`, `wrong`, `paused`, `parent-overlay`, plus any the ACs need). For each state: what is
   on screen (design-system components only), what is **heard** (voice line id or SFX token),
   what input is accepted, and where it exits. A component not in the design system is marked
   `NEW` with a one-line justification, and **the human must approve it** before this stage
   ends; approved NEW components are listed for `/design-system` to register.
6. **Write as you go.** Bootstrap `docs/features/<slug>/ux-flows.md` from
   [`./templates/ux-flows.md`](./templates/ux-flows.md); each confirmed flow and each manifest
   row lands on disk immediately ([`../_shared/write-and-commit.md`](../_shared/write-and-commit.md)).
   Confirm each flow in prose (medium/hard: one question per flow; easy: one-line summary into the
   assumptions ledger).
7. **Structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)), 6 items:
   (1) every child/parent-facing story has a flow; (2) every child flow covers idle / wrong /
   mashing / walked-away (node or explicit N/A); (3) every flow's `SCR-NN` is in the inventory and
   every inventory row appears in a flow; (4) every state has a "heard" entry (no silent
   instruction); (5) every `NEW` component has a justification and the human's OK; (6) every
   Mermaid block parses. Report `N/6`.
8. **Commit + handoff.** `ux-flows: <slug> ux-flows.md`. Stage-handoff block
   ([`../_shared/handoff.md`](../_shared/handoff.md)): *Run next* `/design <slug>`; on `quick`
   with no system/API change, `/tasks <slug>` per the route rules.

## Definition of Done

- Flows + state manifest written; every child flow covers the toddler branches; no fail states.
- Every state composes design-system components (or an approved `NEW`), and every instruction is
  voiced.
- No architecture decided here (that is `design` input, flagged in the file's last section).

## Anti-patterns

- **A state that relies on reading.** He is three. Icons, voice, animation.
- **A punishing branch** (buzzer, lost points, a "try again" screen). Wrong picks get a gentle
  redirect and a hint.
- **Inventing a component** because it was quicker than checking the design system.
- **Only the happy path.** The idle and mashing branches are where toddler games actually break.
- **Raw Mermaid as the confirmation prompt.**
