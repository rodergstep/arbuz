# The settings file — `.claude/sdd.local.md` (template + procedure)

> **Reference-only.** Not a skill. Every skill that ensures, reads or edits the per-machine
> settings file reads this. The template below is written **verbatim**: the frontmatter at the
> top of the file, the «What each key does» section as its body, so the file explains itself.
> Which keys `implement` reads and how they resolve → [`../implement/references/settings.md`](../implement/references/settings.md).

## Who creates it, who changes it, who reads it

| Role | Who | What they do |
|---|---|---|
| **Create** (unconditional, idempotent) | `interview`, `survey`, `roadmap`, `scaffold`, `specify`, `implement`, and `config` | first protocol step after the skill's own gate: absent → write the template + patch `.gitignore`; present → read, never overwrite |
| **Change values** | [`config`](../config/SKILL.md) only | asks, then patches confirmed keys in place |
| **Read** `interview_depth` | `interview`, `specify`, `clarify`, `design`, `ux-flows` | the depth dial → [`interview-depth.md`](./interview-depth.md) |
| **Read** model keys | every skill that dispatches an agent | → [`agent-roster.md`](./agent-roster.md) |
| **Read** engine keys (`tdd`, `stop_on_red`, `max_red_retries`, `gate_*`, `auto_commit`, `branch_strategy`, `godot_bin`, `cmd_*`) | `implement`, `fix`, `ship` | → [`../implement/references/settings.md`](../implement/references/settings.md) |
| **Read** `codex_review` | `review` | → [`codex-review.md`](./codex-review.md) |
| **Read** `auto_commit` | every skill that writes a document | `off` → no commits, the handoff prints the commands |

All pipeline documents are written in **English**. There is no language setting.

## Create when absent (the procedure)

1. `.claude/sdd.local.md` exists → read it and stop. Never overwrite or regenerate it.
2. Absent → write the frontmatter below at the top and the «What each key does» section as the
   body. Keep the inline comments; they carry the allowed values.
3. Patch `.gitignore` so it contains `.claude/*.local.md` (don't duplicate an existing line).
4. Say one line and move on: «`.claude/sdd.local.md` created with defaults — `/config` to tune it».

The settings file is never committed. The `.gitignore` patch rides in the stage's first commit.

## The documented frontmatter

```yaml
interview_depth: medium    # easy | medium | hard — default depth for interview/specify/clarify/design
tdd: true                  # enforce red→green→refactor
stop_on_red: true          # halt on a red that survives escalation, vs drop-and-continue
max_red_retries: 3         # integer ≥1 — RED→GREEN attempts before escalation
gate_lint: true            # include gdlint/gdformat in the per-task gate
gate_vet: true             # include the headless script check in the per-task gate
auto_commit: per_task      # per_task | off — off also stops document-stage commits
branch_strategy: feature   # feature | current
godot_bin: ""              # empty = autodetect (godot on PATH, then /Applications/Godot.app/Contents/MacOS/Godot)
cmd_test_unit: ""          # empty = autodetect (GUT headless, see implement/references/command-detection.md)
cmd_test_integration: ""
cmd_lint: ""
cmd_vet: ""
cmd_export: ""             # empty = autodetect from export_presets.cfg
codex_review: auto         # auto (full route only) | always | never
model_test_author: sonnet  # per-role model; inherit = session model
model_implementer: sonnet
model_refactorer: sonnet
model_reviewer: opus
judgment_model: opus       # haiku | sonnet | opus | fable | inherit | full model id — all judgment agents
effort_test_author: medium # raised to high on escalation
effort_implementer: medium
effort_refactorer: medium
effort_reviewer: high
```

## What each key does

- **`interview_depth`** — `easy | medium | hard`. Pre-selects the depth dial in the Q&A skills
  (how much they decide for you vs ask). Never changes what gets covered. `--depth=` overrides
  it for one run.
- **`tdd`** — false skips RED (the engine warns: you lose the oracle protection).
- **`stop_on_red`** — true halts the run on a red that survives escalation; false drops that task,
  blocks its dependents and continues.
- **`max_red_retries`** — RED→GREEN attempts before escalation.
- **`gate_lint` / `gate_vet`** — include lint / the headless script check in the per-task gate
  (skipped with a warning if the tool is missing).
- **`auto_commit`** — `per_task` commits each task (and each document at the end of a stage);
  `off` leaves commits to you and prints the commands.
- **`branch_strategy`** — `feature` makes sure work is on a feature branch; `current` commits
  where you are.
- **`godot_bin`** — path to the Godot 4.7 binary when it isn't on PATH.
- **`cmd_*`** — explicit command overrides. Empty is better: detection reads the repo.
- **`codex_review`** — when `review` also runs a Codex pass → `codex-review.md`.
- **`model_*` / `effort_*`** — per-role model and effort for the execution agents and the reviewer.
- **`judgment_model`** — one switch for all judgment agents; `opus` default is a floor, not a pin.

## Editing an existing file (only `config` does this)

Patch key by key; keep comments, key order and unknown keys; write values in their documented
form; show `old → new` for every key touched. A malformed frontmatter is never fixed silently:
show what failed and offer «rewrite from the template» or «fix it by hand».

## Reading semantics

Unknown keys are ignored. A missing key falls back to the default above. A malformed file → warn
and use all defaults; a reader never rewrites the file.
