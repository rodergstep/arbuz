---
version: 1
last_changed: greybox
---

# Contract — word database

**File:** `content/words/words.csv` (UTF-8, comma-separated, RFC 4180 quoting). Imported with
Godot's `keep` importer (`words.csv.import`) so it is shipped as-is and never turned into a
translation. Loaded by the `WordDB` autoload (`game/core/word_db.gd`) into `WordEntry` objects.

| Column | Required | Meaning |
|---|---|---|
| `id` | yes | stable word id, `snake_case` (`bridge`, `sunflower`); used by scenes, saves and audio file names |
| `topic` | yes | `places`, `nature`, `animals`, `food`, `toys`, `transport`, … |
| `uk` | yes | Ukrainian word (what Тигриця says) |
| `en` | yes | English word |
| `es`, `fr` | no | Spanish and French words (later arcs) |
| `model` | no | path of the model under `assets/` (Phase 3) |
| `examples_en` | no | short English sentences using the word in different situations, separated by `|`; the learning card speaks the first two |

Rules: ids never change once shipped (saves reference them); adding a row or a column is a data
change; removing or renaming a column, or changing an id, is a `standard`-route change. Bad rows
are skipped with a warning; the game never crashes on content.

API: `WordDB.get_word(id) -> WordEntry` (null + warning if unknown), `WordDB.has_word(id)`,
`WordDB.count()`, `WordDB.load_csv(path) -> int` (rows loaded).
