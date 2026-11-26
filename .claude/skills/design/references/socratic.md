# design — delta over the shared Socratic loop

Canonical machine (Approve / Edit / Save-as-OQ / Drop), edits-log and cadence →
[`../../_shared/socratic-loop.md`](../../_shared/socratic-loop.md). Disk + commit rules →
[`../../_shared/write-and-commit.md`](../../_shared/write-and-commit.md).

## Sections walked (in order)

- **SAD-lite:** §1 → §3 (C4 Context) → §4 (areas first) → §5 (C4 Container) → §6 (sequences + AC
  coverage) → §9 → §11. The other sections are written as `<!-- N/A: SAD-lite -->`.
- **Full:** §1 → §12 in order.

## Decision types

- **Areas** (§4, first) — multi-select over the seven game areas ([`../../_shared/game-areas.md`](../../_shared/game-areas.md)),
  recommended set derived from the spec and `ux-flows.md`. Written to frontmatter `areas` on resolution.
- **Strategic** (§4) — which system owns state, signals vs calls, data format, scene composition.
  2–4 options, recommended first; the blast-radius gate usually fires.
- **Building block** (§5) — extend an existing autoload/scene vs add a new one. Gate fires when
  ≥2 systems or scenes see it.
- **Flow** (§6) — which flows get a diagram; every AC covered by a flow, branch or N/A.
- **Crosscutting bundle** (§8, full) — one question: «keep the architecture map's conventions?»
- **Quality scenario** (§10, full) — numbers verbatim from spec §6; resolve the verify method.
- **Risk** (§11) — generated from the edits-log, spec §8 and the map's gotchas.

## Per-skill gate — blast radius → ADR

On every **approved** decision, score [`./blast-radius.md`](./blast-radius.md): 2 of 3 → ADR;
1 of 3 → ask «record as ADR or keep inline?». An ADR spawn:

1. `NNNN` = number of files in `docs/features/<slug>/adr/` + 1 (zero-padded), continuing after the
   highest number in `docs/adr/` so promoted ADRs never collide.
2. Decision-form kebab-case title (`0004-store-word-stats-in-learning-tracker.md`).
3. From [`../templates/adr.md`](../templates/adr.md), `Status: Accepted`, rejected options listed,
   no strawman.
4. A §9 row written with the section; the ADR gets its own commit at the end.

## Open questions

`save_as_oq` rows land in §11 with the literal `Open question` severity, an owner and a due point
(a date or a stage such as «before `tasks`»). Missing either → Drop with a warning.
