---
status: Accepted
owner: "roderg"
reviewers: []
updated_at: "2026-11-26"
feature_size: "foundation"
ticket: "Phase 2 — saving"
---

# 0003 — Store each profile as versioned JSON with a migration chain

- **Status:** Accepted
- **Date:** 2026-11-26
- **Deciders:** roderg (development plan, Save file), confirmed in `/survey`

## Context

The game autosaves constantly. A three-year-old must never lose progress, and updates over the years must keep loading old saves. The format is fixed now so every system that persists anything agrees on it.

## Decision drivers

- Saves are sacred: old saves must always load (CLAUDE.md).
- The child's name lives only in the local save (privacy).
- Readable by a parent and by tests; diffable fixtures.

## Considered options

1. **One JSON file per profile in `user://saves/`, a top-level integer `version`, step-by-step migrations `v(n) → v(n+1)`** — the plan's design.
2. **Godot `ConfigFile` / binary `var_to_bytes`** — compact, but opaque and fragile across engine versions.
3. **Godot `Resource` saved as `.tres`** — convenient, but can execute embedded scripts on load, which is unsafe and couples to class names.

## Decision outcome

**Chosen:** Option 1. JSON is engine-independent, inspectable and safe to parse; the version plus a migration chain is the simplest way to guarantee old saves load. Writes go to a temp file then rename, so a crash never leaves a half-written save. The first version is `1`.

## Consequences

**Positive**
- Old saves are testable with committed fixtures for every version.

**Negative**
- Every format change needs a migration function and a fixture (full route).
- JSON has no int/float distinction; the loader must coerce types explicitly.

**Neutral**
- Dialogic's own state is not stored in our save; our save keeps only our data.

## Links

- Plan: [`../development-plan.md`](../development-plan.md) — Project structure and data
- Map: [`../architecture-map.md`](../architecture-map.md) — Data and saves
- Contract (Phase 2): `docs/contracts/save-format.md`
