# Config interview: four questions, two calls

Phrasing follows [`../../_shared/ask-style.md`](../../_shared/ask-style.md): every option says what changes in practice. Recommended option first. Questions are in the user's language; keys and values stay English.

## Call 1

**Q1. Models.** «Which models should the agents use?»

| Option | Writes |
|---|---|
| **Balanced (recommended):** Haiku scans, Sonnet writes tests and code, Opus judges and reviews | `judgment_model: opus`, `model_reviewer: opus`, `model_test_author/implementer/refactorer: sonnet` |
| **Cheaper:** Sonnet everywhere | all of the above `sonnet` |
| **Strongest judge:** Fable for judgment and review, Sonnet for code | `judgment_model: fable`, `model_reviewer: fable`, code roles `sonnet` |
| **Same as this session** | all `inherit` |

The session cannot list which models the account has, so this is asked, never probed.

**Q2. Interview depth.** «How much should the pipeline ask you versus decide itself?»

| Option | Writes |
|---|---|
| **Medium (recommended):** asks the decisions that matter, drafts the rest | `interview_depth: medium` |
| **Easy:** drafts almost everything, asks only blockers | `interview_depth: easy` |
| **Hard:** walks every branch with you | `interview_depth: hard` |

## Call 2

**Q3. Gate strictness.** «How strict should the per-task gate be?»

| Option | Writes |
|---|---|
| **Strict (recommended):** TDD on, lint and script check in the gate, stop on a red that survives 3 retries | `tdd: true`, `gate_lint: true`, `gate_vet: true`, `stop_on_red: true`, `max_red_retries: 3` |
| **Keep going:** same gate, but a stuck task is set aside and the rest continue | `stop_on_red: false` |
| **Loose:** TDD on, no lint in the gate (for spikes) | `gate_lint: false`, `gate_vet: false` |

**Q4. Commits and Codex.** «How should work be committed, and when should Codex review?»

| Option | Writes |
|---|---|
| **Recommended:** a feature branch, one commit per task and per document, Codex on the full route | `auto_commit: per_task`, `branch_strategy: feature`, `codex_review: auto` |
| **Codex every time** | `codex_review: always` |
| **I commit myself** | `auto_commit: off` |
| **No Codex** | `codex_review: never` |

Q4 is multiSelect: the commit choice and the Codex choice combine.

## Not asked

- `cmd_*`: empty = autodetect.
- `effort_*`: defaults are right; escalation raises them automatically.
- `godot_bin`: asked only when autodetect failed, as a free-text path.
