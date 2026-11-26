---
contract: word-db
feature: "<slug>"
status: Draft
---

# Word database delta — <slug>

<!-- instruction: the word DB is one row per word (data/words/*.csv or .json — whatever docs/contracts/word-db.md fixes).
Write only the delta. -->

## Columns changed

| Column | Change | Type / allowed values | Read by | Why |
|---|---|---|---|---|
| `<column>` | added / changed / removed | `<type>`, e.g. `en|uk|es|fr` | voice script / LearningTracker / <activity> | AC-NN |

## New or changed rows

<!-- instruction: list ids only when a feature adds words; the rows themselves live in data/. -->

- `<word_id>` — <english> / <ukrainian> — chapter `<id>`

## Audio naming

`audio/voice/<lang>/<word_id>.ogg` (unchanged | changed to: <...>)
