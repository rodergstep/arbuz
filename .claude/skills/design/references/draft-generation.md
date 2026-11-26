# Draft generation — per-section sourcing for design

The per-section contract is the `<!-- … -->` comment in [`../templates/sad.md`](../templates/sad.md).
The draft is held in memory; each section is written only once resolved.

## Inputs in priority order

1. `docs/CONTEXT.md` glossary (+ the feature's) — canonical terms.
2. `spec.md` — goals, non-goals, NFRs (fps, load, input, offline, safety), open questions.
3. `ux-flows.md` — scenes, states, components; the "Design input" section.
4. `docs/architecture-map.md` — autoloads, folders, conventions, pattern few-shots; living
   `docs/contracts/` and `docs/adr/`.
5. Your own earlier sections (§4 constrains §5/§6).

## Per-section sources

- **§1** — intent from spec §1–§2; top-3 quality goals from spec §6 ranked by what would hurt the
  child most if it failed.
- **§2** (full) — the template's fixed constraints + anything from the map.
- **§3** — actors (child, parent), external pieces (user:// storage, offline tools). 4–8 elements.
- **§4** — areas first, then 2–4 strategic choices (the ADR seeds).
- **§5** — the autoloads/scenes/UI/data this feature adds or changes; the block table links
  contracts.
- **§6** — the primary flow always; an idle/interruption flow for anything child-facing; a save
  or migration flow if anything persists. Then the AC coverage table.
- **§7** (full) — export/presets/import settings and the performance budget, or N/A.
- **§8** (full) — inherit the map's conventions; list overrides only.
- **§9** — filled as ADRs spawn.
- **§10** (full) — ≥3 scenarios, numbers verbatim from spec §6, verify method concrete (a GUT
  test, a scripted playthrough, the perf check on the Intel MacBook, a playtest observation).
- **§11** — from the edits-log, spec §8 and the map's gotchas.
- **§12** (full) — glossary terms used, new ones flagged for `/glossary`.

## Question budget

SAD-lite: 4–10 questions in total. Full: 8–18. Bundle convention defaults into one question.
