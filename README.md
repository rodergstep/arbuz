# arbuz: Tygrytsa's Journey

An offline educational game for a three-year-old, in Ukrainian and English. Built with Godot 4.7 and GDScript, for macOS.

- Project rules for humans and agents: [`CLAUDE.md`](CLAUDE.md)
- How features are built: [`docs/workflow.md`](docs/workflow.md)
- Changes: `CHANGELOG.md` (from the first shipped feature)

## Getting started

1. Install Godot 4.7 (standard build) and `gdtoolkit` (`pip install gdtoolkit`) for `gdlint` and `gdformat`.
2. Open the project in Godot, or run the tests headless (see `CLAUDE.md`).
3. In Claude Code, start with `/survey`, then `/scaffold` if the Godot project doesn't exist yet.

The spec-driven workflow in `.claude/` is adapted from [genkovich/sdd](https://github.com/genkovich/sdd) v2.4.1.
