# Contract drift check — what `contract-checker` compares

Run by the `contract-checker` agent in a clean context. It reads files itself and writes
`docs/features/<slug>/contracts/contract-check.md` with two sections.

## Section A — origins table

One row per contract item (save field, word DB column, `Resource` property, public method,
signal, CLI flag):

| item | origin | confidence |
|---|---|---|
| `save.words[].box` | spec AC-04 + LearningTracker `autoload/learning_tracker.gd:41` | high |
| `LearningTracker.word_answered(word_id, correct)` | SAD §6 flow 2 | high |
| `word-db.audio_file` | voice script `tools/voice/generate.py:12` | medium |

- **high** — the item exists in code or is forced by an AC/SAD line, with matching type.
- **medium** — forced by the spec but not yet in code (new in this feature).
- **low** — inferred only; flag it for the human.

## Section B — the four drift points

Each ✓ or ✗ with a one-line diagnostic and a citation on ✗.

1. **Contract ↔ spec** — every AC that persists, loads, announces or reads data maps to a
   contract item; no contract item is unexplained by an AC, a SAD decision, or existing code.
2. **Contract ↔ code** — for unchanged items, the contract matches the code (names, types,
   signal arguments). A mismatch in an untouched item is pre-existing drift: report it separately.
3. **Save ↔ migration ↔ fixtures** — every save-shape change has a version bump, a migration
   step, and a fixture for the previous version; the migration handles every changed field.
4. **Data ↔ contract** — every existing data file (`data/**`) still validates against the new
   schema (sample at most 20 files if there are many, and say how many were checked); every word
   id in the word DB has the audio file the naming contract promises.

Output ends with `CONTRACTS_CLEAN` when all four are ✓, otherwise `DRIFT_FOUND`.
