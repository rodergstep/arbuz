# Agent roster — model per role, dispatch rules, the shared agent contract

> **Reference-only.** Not a skill. Skills read this for which agent to dispatch, at which model,
> and the contract every spawned agent follows. Agent definitions live in `.claude/agents/*.md`.

## Why subagents

Long sessions degrade: **context rot** (quality drops as the window fills), **context poisoning**
(one wrong fact keeps getting reused), **lost in the middle** (the middle of a long context is
ignored). So heavy reading (repo scans, logs, web research, Godot docs) and every judgment that
needs fresh eyes run in a **subagent with its own clean context**. It returns a short report; its
working mess never enters the main conversation. Between pipeline stages the human runs `/clear`
because every stage re-reads its inputs from disk.

## The roster

Model is chosen by the kind of work: scanning is cheap, execution is balanced, judgment gets the
strongest model. Skills run on the session model.

| Agent | Kind of work | `model` | `effort` | Tools |
|---|---|---|---|---|
| `explorer` | scan repo / logs / addon code, categorize, return a cited summary | `haiku` | `low` | Read, Grep, Glob, Bash |
| `researcher` | bounded web research (Godot docs, child-development facts), cited | `sonnet` | `medium` | Read, Grep, Glob, WebSearch, WebFetch |
| `implementer` | build one task directly + the smoke check (for tasks too big to do inline) | `sonnet` | `medium` | + Write, Edit, Bash |
| `contract-checker` | drift between contracts, data files, code and spec | `sonnet` | `medium` | Read, Grep, Glob, Bash |
| `playtest-analyst` | read the playtest event log + notes, find confusion points, draft fixes | `sonnet` (`opus` on `full`) | `medium` | Read, Grep, Glob, Bash |
| `reviewer` | independent clean-context review of the whole change | `opus` | `high` | Read, Grep, Glob, Bash |
| `critic` | contradictions and gaps in a spec or SAD | `opus` | `high` | Read, Grep, Glob |
| `devils-advocate` | ambiguity and toddler failure modes | `opus` | `high` | Read, Grep, Glob |
| `strategist` | three real alternative approaches (`full` route only) | `opus` | `high` | Read, Grep, Glob |
| `analyst` | multi-lens review of those approaches (`full` route only) | `opus` | `high` | Read, Grep, Glob |

**Code is written fast, not test-first.** This is a home-use game with no production: code is
written inline or by one `implementer`, checked by the headless smoke check and by playing it.
The playtest with the child is the real test.

**Cross-vendor review.** For blind spots shared by one model family, `full`-route features also
get a Codex review → [`codex-review.md`](./codex-review.md).

## Dispatching

Project agents are dispatched by their bare name: `subagent_type: "explorer"`,
`"implementer"`, `"contract-checker"`, `"playtest-analyst"`,
`"reviewer"`, `"critic"`, `"devils-advocate"`, `"researcher"`, `"strategist"`, `"analyst"`.
If a named agent isn't available at runtime, fall back to `general-purpose` (or `Explore` for
read-only scans) with the same prompt. A fallback agent never reads `.claude/agents/*.md`, so
everything it needs must be in the prompt.

## Override precedence (highest wins)

```
env var  >  per-invocation (the Agent call)  >  model_<role>  >  judgment_model  >  frontmatter  >  session
```

- **`judgment_model`** (`.claude/sdd.local.md`) — one switch for the judgment agents (`reviewer`,
  `critic`, `devils-advocate`, `strategist`, `analyst`). Values: `haiku | sonnet | opus | fable`,
  `inherit`, or a full model id. Default `opus`. Set `fable` to run reviews on Fable.
- **The default is a floor, not a pin:** if `judgment_model` is unset and the session runs a
  stronger tier than `opus` (order `haiku < sonnet < opus < fable`), judgment agents use
  `inherit`. An explicit value is always honoured.
- Env levers: `CLAUDE_CODE_SUBAGENT_MODEL` (model), `CLAUDE_CODE_EFFORT_LEVEL` (effort — the
  reliable lever; some builds ignore the `effort:` frontmatter).

## Model availability — degrade, don't block

If a dispatch fails because the model is unavailable, retry once with `model: inherit`, name the
degradation in the handoff, and suggest pinning `judgment_model`. A missing tier never blocks a
stage.

## Scale with the route

- `quick` / `standard` → roster defaults.
- `full` → `reviewer` and `critic` at `xhigh` (via
  `CLAUDE_CODE_EFFORT_LEVEL`, capped at what the model supports); `playtest-analyst` on `opus`.

## The shared agent contract (every spawned agent)

1. **Clean context.** The agent sees only its prompt. The dispatching skill passes paths, the
   draft or diff, and the decisions; the agent re-reads upstream files itself. Only its final
   message returns. Never use fork mode for `reviewer` / `critic` / `devils-advocate` — their
   value is independence.
2. **The report must reach the dispatcher.** In background mode, append to the prompt: «also send
   your full final report as a message to your dispatcher». A completion signal without content
   is not a verdict.
3. **Worker preamble.** When a skill delegates a task: «execute directly, do not spawn sub-agents,
   use tools directly, report results with absolute file paths».
4. **Verify before claiming done.** Identify the command that proves it, run it, read the output,
   then claim with the evidence. «should / probably / seems» means it wasn't verified.
5. **Cite or drop.** Judgment agents emit only cited findings (`file:line` + the spec/AC clause).
   An uncited finding is dropped.
6. **Short reports.** A report is a summary for the main conversation: findings, paths, verdict.
   No file dumps, no logs pasted whole.
