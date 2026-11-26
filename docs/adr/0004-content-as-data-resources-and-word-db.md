---
status: Accepted
owner: "roderg"
reviewers: []
updated_at: "2026-11-26"
feature_size: "foundation"
ticket: "Phase 2 — content pipeline"
---

# 0004 — Keep content as data: a CSV word database and Resource files for chapters

- **Status:** Accepted
- **Date:** 2026-11-26
- **Deciders:** roderg (development plan, Project structure and data), confirmed in `/survey`

## Context

The game grows by chapters, words and languages (Ukrainian, English, then Spanish and French). The voice script generates audio from the word list. Adding content must not mean editing engine code.

## Decision drivers

- Adding a chapter or a language never touches engine code (plan).
- One source of truth for words, read by both the game and the voice-generation script.
- Content validated by GUT tests at load.

## Considered options

1. **`content/words/words.csv` for words, typed `Resource` (`.tres`) files for chapters and tasks, Dialogic timelines for dialogue** — the plan's layout.
2. **Everything as JSON** — one format, but no editor inspector, no typed fields.
3. **Everything as `.tres`** — typed, but the Python voice script can't read it easily and diffs are noisy.

## Decision outcome

**Chosen:** Option 1. CSV is trivially read by Python and edited by a parent; `Resource` files give typed fields and the inspector for structured chapter data. Each format gets a contract and a validation test.

## Consequences

**Positive**
- New words and chapters are data-only changes; the voice script and the game share one list.

**Negative**
- Two formats to validate; CSV escaping (commas, quotes in phrases) must be handled.
- Any word-DB format change is a full-route change.

**Neutral**
- Generated audio is named by line id and reproducible from the CSV.

## Links

- Plan: [`../development-plan.md`](../development-plan.md) — Project structure and data
- Map: [`../architecture-map.md`](../architecture-map.md) — Data and saves
- Contracts (Phase 2): `docs/contracts/word-db.md`, `docs/contracts/content-resources.md`
