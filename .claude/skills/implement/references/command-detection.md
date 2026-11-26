# Command detection (step 3)

Resolve five commands: **unit**, **integration**, **lint**, **vet** (headless parse/import
check) and **export**. First hit wins per command; print the resolved set.

## Cascade (first match wins)

1. **Settings override** — non-empty `cmd_test_unit` / `cmd_test_integration` / `cmd_lint` /
   `cmd_vet` / `cmd_export` in `.claude/sdd.local.md`.
2. **Architecture map** — `test_cmd` / `lint_cmd` / `vet_cmd` / `export_cmd` in
   `docs/architecture-map.md` frontmatter (recorded by `survey`/`scaffold` from what worked).
3. **Godot defaults** (when `project.godot` exists):
   - Godot binary: `godot_bin` setting → `godot` on PATH → `/Applications/Godot.app/Contents/MacOS/Godot`.
   - **unit + integration + contract** (one GUT run; GUT's directory config decides what runs):
     `<godot> --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
     (if `.gutconfig.json` exists, `-gconfig=res://.gutconfig.json` replaces the `-g*` dir flags).
     To run one file: add `-gselect=<file_name.gd>`; one test: `-gunit_test_name=<test_name>`.
   - **lint**: `gdlint <dirs>` and `gdformat --check <dirs>` from `gdtoolkit`, over
     `autoload scenes ui data tests` (only those that exist).
   - **vet**: `<godot> --headless --path . --import --quit` — fails on script parse errors and
     broken resources. (Check the exit code and grep the output for `SCRIPT ERROR` / `Parse Error`.)
   - **export**: `<godot> --headless --path . --export-release "<preset>" <out path>` with the
     first preset in `export_presets.cfg` (macOS first).
4. **Python tools** (`tools/**/pyproject.toml` or `requirements.txt`): `python3 -m pytest tools`
   is added to the unit tier for `tooling` tasks.
5. Nothing found → ask the human for the command and suggest `/config` to persist it. Never guess.

## Reporting

```
detected commands:
  godot   = /Applications/Godot.app/Contents/MacOS/Godot (4.7.1.stable)
  unit    = godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
  lint    = gdlint autoload scenes ui data tests   (gdtoolkit: present)
  vet     = godot --headless --path . --import --quit
  export  = godot --headless --path . --export-release "macOS" build/macos/arbuz.zip
```

Missing lint/vet tool → skip that gate with a one-line warning. Missing GUT runner → stop.
Detection is read-only: never install tools without asking.

## Notes

- GUT's exit code is non-zero on any failing test; also scan the output for `Orphans` warnings and
  report them (leaked nodes usually mean a test didn't free a scene).
- The first headless run after adding assets may import for a while; run `--import --quit` once
  before the first test run of a session.
- Scripted playthrough tests that need a real window (shaders, viewport textures) are tagged in
  their file name (`test_*_windowed.gd`) and run without `--headless` when a display is available;
  otherwise they are reported NON-run, never silently passed.
