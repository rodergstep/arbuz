# Settings — the `implement` engine's delta

The canon is [`../../_shared/settings-file.md`](../../_shared/settings-file.md). This file lists
only what the engine reads and how agents are dispatched.

## Keys the engine reads

| Group | Keys | Effect |
|---|---|---|
| TDD loop | `tdd`, `stop_on_red`, `max_red_retries` | skip RED (warned); halt vs continue on a surviving red; attempts before escalation |
| Gate | `gate_lint`, `gate_vet` | include lint / the headless check |
| Commands | `godot_bin`, `cmd_test_unit`, `cmd_test_integration`, `cmd_lint`, `cmd_vet`, `cmd_export` | overrides for detection |
| Git | `auto_commit`, `branch_strategy` | per-task commits or none; feature branch or current |
| Dispatch | `model_test_author`, `model_implementer`, `model_refactorer`, `model_reviewer`, `effort_*`, `judgment_model` | model + effort per agent |

## Model + effort at dispatch

Precedence and the degrade rule → [`../../_shared/agent-roster.md`](../../_shared/agent-roster.md).
On escalation the engine raises the stuck agent's effort to `high` (and may raise its model one
tier) for that task only. On the `full` route execution agents start at `high`.

## Execution

Always sequential, in the main checkout. (No agent teams or parallel worktrees: Godot's `.tscn`,
`.import` and `uid` files don't merge well, and this is a one-developer project.)
