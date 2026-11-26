# Settings — the `implement` engine's delta

The canon is [`../../_shared/settings-file.md`](../../_shared/settings-file.md). This file lists
only what the engine reads and how agents are dispatched.

## Keys the engine reads

| Group | Keys | Effect |
|---|---|---|
| Smoke check | `gate_vet`, `gate_lint`, `gate_tests` | headless import (on by default); lint and existing GUT tests (off by default) |
| Commands | `godot_bin`, `cmd_test_unit`, `cmd_test_integration`, `cmd_lint`, `cmd_vet`, `cmd_export` | overrides for detection |
| Git | `auto_commit`, `branch_strategy` | per-task commits or none; feature branch or current |
| Dispatch | `model_implementer`, `model_reviewer`, `effort_*`, `judgment_model` | model + effort per agent |

## Model + effort at dispatch

Precedence and the degrade rule → [`../../_shared/agent-roster.md`](../../_shared/agent-roster.md).

## Execution

Always sequential, in the main checkout. (No agent teams or parallel worktrees: Godot's `.tscn`,
`.import` and `uid` files don't merge well, and this is a one-developer project.)
