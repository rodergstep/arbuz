---
version: 1
last_changed: greybox
---

# Contract — save format

**File:** `user://saves/<profile_id>.json` (default profile: `default`). Written by `SaveSystem`
(`game/core/save_system.gd`) to `<file>.tmp`, then renamed over the old file. ADR-0003.

## Version 1

```json
{
  "version": 1,
  "profile_id": "default",
  "encountered": ["line:intro", "word:bridge", "door:question"]
}
```

| Field | Type | Meaning |
|---|---|---|
| `version` | int | format version; `SaveSystem.VERSION` |
| `profile_id` | string | file name stem |
| `encountered` | array of strings | lines and things he has met; the first meeting is Ukrainian + English, later ones English only. Keys: `line:<id>`, `hint:<id>`, `door:<id>`, `word:<word id>` |

## Rules

- A missing or corrupt file starts fresh with a warning; the game never crashes on a save.
- A newer version than the game knows is read as-is with a warning.
- Every format change bumps `version`, adds a `migrate` step and a fixture
  `tests/fixtures/saves/v<N>.json`; `tests/core/test_save_system.gd` must load every fixture.
  This is the one test the project insists on (saves are sacred). Standard route.
- Dev tools write to `user://dev_saves`, never to `user://saves`.
