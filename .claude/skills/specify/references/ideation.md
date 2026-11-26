# Ideation — which analyses run, and what they feed

Specify step 3. Reuse first: if `docs/features/<slug>/idea.md` already settled the direction
(see [`brief-reuse.md`](./brief-reuse.md)), run only the gaps it left open.

## What runs (route first, depth second)

| Route / depth | Analyses (named subagents, clean context) |
|---|---|
| `quick`, or depth `easy` | none — the deep-dive answers only; the chosen direction goes in the assumptions ledger |
| `standard` | `devils-advocate` in **toddler** mode (failure modes for a 3-year-old) · `researcher` only for a decision-changing factual gap (child development, a Godot capability, an addon limit) |
| `full`, or depth `hard` | `researcher` + `strategist` (three real approaches) + `analyst` (engineer / parent / child lenses) + `devils-advocate` |

Dispatch with `subagent_type: "<name>"` per [`../../_shared/agent-roster.md`](../../_shared/agent-roster.md).
Each gets the raw idea, the accepted decisions and the open unknowns, never a persuasive summary.

## What each returns and where it goes

- **researcher** → cited facts with dates and limits (`RESEARCH_LIMITED` is acceptable). Feeds §1 ¶3
  and §6 when a fact changes a target. Typical questions: attention span at 3, touch-target size
  for small hands, how Godot 4.7 handles gamepad hot-plug on macOS.
- **strategist** → three genuinely different approaches (not one idea and two strawmen), each with
  what the child experiences, the cost in sessions, and the risk.
- **analyst** → the approaches through three lenses: engineer (build and content cost, frame
  budget on the Intel MacBook, save impact), parent (learning value, plan fit, co-play), child
  (fun on the fifth play, frustration, motor demands). A 3×3 matrix.
- **devils-advocate** → at most five cited failure modes; in toddler mode: dead ends, reading,
  punishment, overstimulation, too-long rounds, unsafe reach.

The confirmed direction becomes §1 ¶3. Rejected approaches go into §1 ¶4 with one line each.

## Rules

- Analyses stay at the experience level; implementation choices belong to `design`.
- Never invent findings to fill a table. «Not researched» is a valid row.
- The human confirms the direction; an analysis never decides it.
