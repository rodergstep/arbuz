---
contract: save-format
feature: "<slug>"
from_version: <N>
to_version: <N+1>
status: Draft   # Draft | Approved (the human approved the delta)
---

# Save format delta — <slug>

<!-- instruction: write the DELTA against docs/contracts/save-format.md, not the whole schema.
If the save format does not change, do not create this file. -->

## What changes

| Path | Change | Type | Default for old saves | Why (AC / ADR) |
|---|---|---|---|---|
| `<path.to.field>` | added / renamed from `<old>` / retyped / removed | `<int/float/String/Array[...]/Dictionary>` | `<value>` | AC-NN |

## Migration

- Function: `migrate_v<N>_to_v<N+1>(data: Dictionary) -> Dictionary` in `autoload/save/migrations.gd`
- Steps, in order:
  1. <e.g. copy `progress.chapter` into `progress.chapters["<id>"].reached = true`>
  2. <...>
- Learning history preserved: <yes, and how>

## Fixture saves (the tests)

| Fixture | Represents | Asserted after migration |
|---|---|---|
| `tests/fixtures/saves/v<N>.json` | <a realistic save at version N, e.g. "after chapter 1, 14 words seen"> | <validates; word stats equal; unlocks equal> |

## Human approval

- [ ] I read the change table and the migration, and an existing save of my child's survives it.
