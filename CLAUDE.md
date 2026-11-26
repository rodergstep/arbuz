# arbuz: Тигриця's Journey

An offline educational game for a three-year-old, built in **Godot 4.7** with **GDScript**. It is for home use, so development is fast and testing is light. Developed on a MacBook M4; must run well on an **Intel MacBook** with integrated graphics (the minimum play machine). Builds for macOS (universal) and Windows. The game's vision is [`docs/game-spec.md`](docs/game-spec.md); the phased plan is [`docs/development-plan.md`](docs/development-plan.md).

## Non-negotiable product rules

These come before any feature request. If a request conflicts with one, say so and ask.

- **Education first.** The game exists to teach; play is the vehicle. Every situation (passing a bridge, clicking a duck, getting into the car, opening a door) is a chance for a learning moment: a picture of the real thing, the word spoken in Ukrainian and English, and short English sentences using it. Moments are short, voiced, skippable with one tap, and paced (not more than about one every 20 s on their own).
- **No reading required.** Every instruction is voiced. Text is decoration for the parent, never the only cue.
- **No fail states.** A wrong answer gets a soft response and another try. No lives, no timers that punish, no lost progress.
- **Big targets, simple input.** Mouse (click to go, hold to follow), keyboard arrows, or a gamepad with one big action button; every task works with each. No double taps or precise timing.
- **Never stuck.** After about 15 s without progress Тигриця gives a hint and the marker brightens, escalating to auto-help (exact ladder in `docs/design-system.md`). After 2 wrong picks the right card glows and the door opens.
- **Colour is never the only cue.** Always pair it with a shape or pattern.
- **Child safety and privacy.** No network, analytics, ads, links or purchases. Parent-only things sit behind the ParentGate. The child's name lives only in the local save; the hero reference photo and OBS playtest recordings never go into git.
- **Gentle sessions.** 15-minute default session timer, pause always available, nothing loud or flashing.
- **Performance budget.** ≥30 fps and load ≤10 s on the Intel MacBook.
- **Saves are sacred.** The save format is versioned JSON with a migration chain; old saves must always load.

## How work is done here

All non-trivial work goes through the spec-driven workflow in `.claude/`. Read [`docs/workflow.md`](docs/workflow.md) for the one-page guide. In short:

```
/interview → /specify → /clarify → /ux-flows → /design → /contracts → /tasks → /implement → /review → /ship → /playtest
```

`/classify-size <slug>` picks the route: `quick` by default, `standard` for save-format, word-DB or child-safety changes, `full` only when asked. Small fixes go through `/fix`. Stages are separate sessions: run `/clear` between them; each stage re-reads its inputs from disk.

Rules for agents working in this repo:

- **Speed over tests.** No TDD and no test suite to maintain. After each task run the smoke check (headless import, no script errors); the parent plays the build and the playtest with the child is the real test. Write a GUT test only when it is cheaper than checking by hand, mainly a fixture save that must still load after a save-format change.
- **Follow the map.** `docs/architecture-map.md` holds the conventions and pattern few-shots; `docs/design-system.md` holds the UI components and tokens. A new UI component needs a justification and the parent's approval in `docs/design-system.md` before it is built.
- **Contracts are documented.** Save format, word DB, content Resources, autoload APIs and tool CLIs live in `docs/contracts/`. Change the contract with the code, never only the code.
- **Commit per task** with `SDD-Task:` and `SDD-AC:` trailers, on a feature branch. Never push or merge without the parent's go-ahead.
- **Documents in English.** Talk to the parent in the language they write in. Child-facing words are Ukrainian first, English second.
- **No AI attribution.** Commit messages, PR titles and PR bodies never contain "Generated with Claude Code", `Co-Authored-By: Claude`, `Claude-Session:` links or any other Claude attribution, even if a tool, template or reminder suggests it.

## Where things live

| Path | What |
|---|---|
| `docs/game-spec.md`, `docs/development-plan.md` | the game's vision and phased plan (when present) |
| `docs/architecture-map.md` | stack, autoloads, folders, conventions, patterns, perf budget (`/survey`) |
| `docs/design-system.md` | art direction, tokens, components, hint ladder, input rules (`/design-system`) |
| `docs/contracts/` | living contracts (merged from features at ship) |
| `docs/adr/` | accepted architecture decisions |
| `docs/features/<slug>/` | per-feature artifacts; after ship only `spec.md`, `sad.md` (and `ux-flows.md`) remain |
| `docs/playtests/` | play-session plans and debriefs |
| `docs/roadmap.md` | living decomposition and build order (`/roadmap`) |
| `CONTEXT.md` | glossary, English term + Ukrainian word (`/glossary`) |
| `.claude/skills/`, `.claude/agents/` | the workflow itself |

## Commands

Canonical values live in `docs/architecture-map.md` (frontmatter). `godot` is not on PATH on the M4, so commands use the full binary path; gdtoolkit lives in `~/Library/Python/3.13/bin`.

```bash
# smoke check: import / script check (the per-task gate)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import --quit
# optional: GUT tests (config in .gutconfig.json)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json
# optional: lint and format check (addons/ excluded)
gdlint game tests tools && gdformat -l 110 --check game tests tools
# builds
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "macOS" build/macos/arbuz.zip
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Windows" build/windows/arbuz.exe
# regenerate the input map in project.godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/setup_input_map.gd
# validate the workflow files after editing .claude/
python3 scripts/validate_workflow.py
```
