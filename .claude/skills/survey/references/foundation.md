# Greenfield foundation — the Godot game skeleton

Used by `survey` when the repo has no `project.godot` yet. Most foundation choices are already
made by the Development Plan; the session **confirms** them and asks only what is still open.

## Pre-decided (confirm in one bundled question, don't re-ask one by one)

| Choice | Decision | Source |
|---|---|---|
| Engine | Godot 4.7.x standard (not .NET), GDScript (typed) | Development Plan, Phase 0 |
| Renderer | Compatibility (OpenGL) — the Intel MacBook is the floor | Development Plan, risks |
| Addons | GUT, Dialogic 2, Phantom Camera, Beehave | Development Plan, Phase 0 |
| Version control | Git + Git LFS for `glb, png, ogg, wav, blend` | Development Plan, Phase 0 |
| Folders | `autoload/ scenes/ ui/ data/ audio/ tests/ tools/ docs/` | architecture-map template |
| Saves | one JSON per profile in `user://saves`, `version` field, migrations | Development Plan, architecture |
| Lint | `gdtoolkit` (`gdlint`, `gdformat`) via `pip` | this framework |

## Still to ask (only if not settled on disk)

- The exact Godot binary path on the M4 (for `godot_bin`), if `godot` is not on PATH.
- Whether `gdtoolkit` may be installed with `pip` (else lint is skipped with a warning).
- Export presets to create now: macOS (universal) first; Windows later.

## Foundational ADRs (written to `docs/adr/`)

1. `0001-use-godot-4-7-gdscript-compatibility-renderer.md`
2. `0002-core-systems-as-autoloads-with-signal-contracts.md`
3. `0003-versioned-json-saves-with-migration-chain.md`
4. `0004-content-as-data-resources-and-word-db.md`

## Scaffold `tasks.json` (→ `docs/features/_scaffold/tasks.json`)

Each task's DoD includes the **skeleton smoke test**: the project imports headless, GUT runs an
empty suite and exits 0, lint runs, and a macOS export builds.

| id | title | files_hint |
|---|---|---|
| S1 | `project.godot` with Compatibility renderer, window/stretch settings for 1280×720 and touch | `project.godot` |
| S2 | `.gitignore` (`.godot/`, `build/`, `*.import` rules per Godot docs), `.gitattributes` with LFS rules | `.gitignore`, `.gitattributes` |
| S3 | Install addons (GUT, Dialogic 2, Phantom Camera, Beehave) and enable them | `addons/`, `project.godot` |
| S4 | Folder skeleton + one example autoload (`GameState`) with a typed signal and a GUT test | `autoload/`, `tests/` |
| S5 | GUT config (`.gutconfig.json`) and the headless test command; a failing-then-passing example test | `.gutconfig.json`, `tests/` |
| S6 | `gdtoolkit` config (`gdlintrc`) and lint command | `gdlintrc` |
| S7 | macOS export preset + export command | `export_presets.cfg` |
| S8 | Gamepad check scene: shows every button/stick press, tests rumble | `scenes/dev/gamepad_check/` |
| S9 | Playtest event log stub (timestamped JSON lines to `user://logs/`) | `autoload/event_log.gd`, `tests/` |
| S10 | `CLAUDE.md` conventions section updated with the real commands | `CLAUDE.md` |
