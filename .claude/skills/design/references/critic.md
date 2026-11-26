# design — delta over the shared critic

Canonical dispatch + F1–F6 → [`../../_shared/critic.md`](../../_shared/critic.md).

## Placeholders

- **`{{ARTIFACT_NAME}}`** = "Solution Architecture Document (Arc42, <lite|full> mode)".
- **`{{DRAFT}}`** = `sad.md` as written.
- **`{{EDITS_LOG}}`** = the edits-log + the ADR-spawns log.
- **`{{UPSTREAM_FILES}}`** (paths only): `docs/features/<slug>/spec.md`,
  `docs/features/<slug>/ux-flows.md` (if present), `docs/architecture-map.md`,
  `docs/CONTEXT.md` (+ feature `CONTEXT.md`), `docs/features/<slug>/adr/`, `docs/adr/`,
  `docs/contracts/`.

## F5 structural floor

- Every section of the mode is filled or marked N/A with a reason.
- §3 has a real `C4Context`, §5 a real `C4Container` (no placeholders, names match the
  architecture map), §6 ≥1 `sequenceDiagram` and an AC coverage table where every spec §5 AC
  appears.
- Frontmatter `areas` is non-empty and consistent with §5.
- §9 is closed against `adr/` both ways; §11 has a row (owner + due) for every `save_as_oq`.

## F6 specialization

- **NFR-number leak** — a number in §10 (or §1 goals) not in spec §6.
- **Strawman ADR** — a considered option an existing constraint excludes (e.g. a networked
  backend when the constraints say offline only).
- **Constraint vs map** — §2/§8 contradicts `docs/architecture-map.md` conventions without an
  override note.
- **Toddler-rule leak** — a flow in §6 where an error, a wait or a reading step reaches the child
  without the hint/redirect the spec or design system requires.

## F1 specialization

A §4 choice contradicted later (e.g. §4 says scenes report through InteractionSystem, but a §6
flow shows a scene calling LearningTracker directly).
