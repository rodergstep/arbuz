# Save-file migrations — the rules

The save file is one JSON file per profile in `user://saves/<profile>.json`, with a top-level
`version` integer. SaveSystem loads it, runs the migration chain from the file's version up to
the current one, then validates.

## Rules

1. **Any shape change bumps `version`**: a field added, renamed, retyped, moved or removed.
   Adding an optional field with a default still bumps, so the migration can write the default
   explicitly and the validator can stay strict.
2. **One function per step**: `migrate_v<N>_to_v<N+1>(data: Dictionary) -> Dictionary`, pure
   (no file access, no autoload calls), in `autoload/save/migrations.gd`. The chain runs steps in
   order; steps are never skipped or merged.
3. **Never delete or edit a shipped migration step.** Fix forward with a new version.
4. **Fixture saves are the tests.** For every version ever shipped, keep one realistic save under
   `tests/fixtures/saves/v<N>.json`. The contract test loads each fixture, migrates to current,
   and asserts: it validates, and the learning stats, progress and unlocks survive with the right
   values.
5. **Backup before writing.** SaveSystem writes `<profile>.json.bak` (the pre-migration file)
   before saving a migrated file for the first time.
6. **Unknown future version** (a save from a newer build) → do not overwrite it; load read-only
   and tell the parent in the parent screen.
7. **Corrupt file** → keep it as `.corrupt`, start from the `.bak` if it validates, otherwise a
   fresh profile; never crash, and never show the child an error.

## What the human checks on every save change

- Which fields change, and what an existing save of the child's will look like after migration.
- That no learning history (times heard, right, wrong, repetition box, last seen) is lost.
- That the fixture for the previous version is a realistic copy of a real save shape.
