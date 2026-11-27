---
version: 2
last_changed: greybox
---

# Contract — save format

**File:** `user://saves/<profile_id>.json` (default profile: `default`). Written by `SaveSystem`
(`game/core/save_system.gd`) to `<file>.tmp`, then renamed over the old file. ADR-0003.

## Version 2 (current)

```json
{
  "version": 2,
  "profile_id": "default",
  "encountered": ["line:intro", "word:bridge"],
  "words": {"bridge": {"heard": 3, "right": 1, "wrong": 1, "box": 2, "last_seen": 1795000000.0}},
  "settings": {"session_minutes": 15, "volume": 0.85}
}
```

| Field | Type | Meaning |
|---|---|---|
| `words` | object | per word id: `heard` (times on a learning card), `right`/`wrong` (answers when asked), `box` 1–5 (repetition box; right → +1, wrong → 1), `last_seen` (unix seconds) |
| `settings` | object | parent settings: `session_minutes` (int), `volume` (0..1), `microphone` (bool, default true; added without a version bump: missing keys take defaults) |

Migration v1 → v2 (`_v1_to_v2`): adds empty `words` and default `settings`; keeps `encountered`.
Fixtures: `tests/fixtures/saves/v1.json`, `v2.json`.

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
- The user folder moved from `Тигриця's Journey` to `Tygrytsa's Journey` (rename); on first start `SaveSystem` copies an existing save from the old folder.


### Settings added 2026-11-27 (no version bump: optional keys)

- `car_color` (string, HTML colour): the paint he chose for his car.
- `hat` (string: `cap`, `sun_hat`, `crown`): the hat the boy wears.

- `words.<id>.said` (int, optional, default 0): times the microphone heard him say the word when
  asked (added 2026-11-27 for the parent's progress view; no version bump).
