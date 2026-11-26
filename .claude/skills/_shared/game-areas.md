# Game areas — what a feature touches (replaces web "surfaces")

> **Reference-only.** Not a skill. `design` owns the **selection**: it declares the areas a feature
> touches in `sad.md` frontmatter `areas: [...]`. `contracts`, `tasks`, `implement`
> and `review` **read** that list and gate their output by the table below. They never re-derive it.

## The taxonomy

| Area | What it is | Lives in |
|---|---|---|
| `core-system` | an autoload singleton (InteractionSystem, LearningTracker, SaveSystem, AudioDirector, QuestSystem, SessionTimer…) | `autoload/` |
| `scene` | a playable scene or level: nodes, scripts, camera, movement, triggers | `scenes/` |
| `ui` | anything the child or parent taps or reads: HUD, menus, cards, parent settings | `ui/` (+ `docs/design-system.md`) |
| `content-data` | words, chapters, quests, dialogue: data files and `Resource` classes | `data/` |
| `audio-pipeline` | voice generation, music, SFX, the word-to-audio mapping | `audio/`, `tools/voice/` |
| `tooling` | scripts outside the game: the Python voice script, Blender scripts, build scripts | `tools/` |
| `build` | export presets, platform settings, performance budget | `export_presets.cfg`, `project.godot` |

Most features touch one or two. A feature that touches `core-system` **and** many scenes is
large; say so when sizing.

## The gating table

| Area | `contracts` form | `tasks` layer | how it is checked |
|---|---|---|---|
| `core-system` | autoload public API (methods + signals) in `contracts/autoloads.md`; save schema if it persists | `core` | run it in the game; a GUT test only for save/migration logic |
| `scene` | signals the scene emits/consumes; required nodes | `scene` | play the scene with mouse, keys and gamepad |
| `ui` | none (consumes system APIs); states come from `ux-flows.md` | `ui` | look at each state in the running game |
| `content-data` | data schema (`contracts/word-db.md`, `contracts/content.md`) | `data` | the game loads every data file without warnings |
| `audio-pipeline` | word-id → file naming contract; tool CLI | `audio` | the tool reports any word id without an audio file |
| `tooling` | CLI flags + input/output files (`contracts/tools.md`) | `tooling` | run the tool once on real input |
| `build` | none | `build` | export builds + performance check on the Intel MacBook (manual at gates) |

Anything that persists player state adds the **save contract** (`contracts/save-format.md`) and
its migration tests, whatever the area.

## Rules

- **Reuse the UI foundation.** `ui` work composes `docs/design-system.md` components and `Theme`
  tokens. A new component needs a written justification and the human's OK before it is built.
- **Data, not code, for content.** Adding a chapter, a word or a language never touches engine
  code; if a feature would, that is an architecture decision (an ADR).
- **Godot files are shared state.** Two tasks editing the same `.tscn` or `project.godot` are
  serialized (`tasks` marks them), because text merges of scene files break easily.
