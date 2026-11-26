---
status: Accepted
owner: "roderg"
reviewers: []
updated_at: "2026-11-26"
feature_size: "foundation"
ticket: "Phase 0–2 — core systems"
---

# 0002 — Run core systems as autoloads that talk through typed signals

- **Status:** Accepted
- **Date:** 2026-11-26
- **Deciders:** roderg (development plan, Architecture), confirmed in `/survey`

## Context

Every chapter relies on the same systems: input, interaction, learning tracker, saves, audio, quests, settings, event log. They must outlive scene changes and be testable without loading the world.

## Decision drivers

- Saves are sacred and constant: state must survive scene changes.
- Every system has automated GUT tests (Gate 2).
- Content changes must not touch engine code.

## Considered options

1. **Autoload singletons in `game/core/`, signals up and public methods down** — the plan's design.
2. **A single root "Game" scene owning systems as child nodes, passed by dependency injection** — explicit wiring, more boilerplate in every scene.
3. **Static utility classes** — no lifecycle, no signals, hard to reset in tests.

## Decision outcome

**Chosen:** Option 1. Autoloads are the Godot-native way to keep systems alive across scenes; signals keep scenes decoupled from each other. Each autoload's script is instantiable on its own, so tests create a fresh instance instead of using the global one.

## Consequences

**Positive**
- Scenes stay small and replaceable; systems are tested in isolation.

**Negative**
- Globals are easy to misuse; the rule "scenes never call each other, systems never reference scenes" must be enforced in review.
- Load order matters and is fixed in `project.godot`.

**Neutral**
- Each autoload's API is a documented contract in `docs/contracts/autoloads.md`.

## Links

- Plan: [`../development-plan.md`](../development-plan.md) — Architecture
- Map: [`../architecture-map.md`](../architecture-map.md) — Autoloads, Conventions
