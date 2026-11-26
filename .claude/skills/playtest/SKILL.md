---
name: playtest
model: inherit
effort: medium
agents: [playtest-analyst]
description: >
  Use to plan and debrief a real play session with the child, the game's equivalent of a
  post-deploy watch. "before" mode prepares a short checklist of what to watch for a feature;
  "after" mode collects the local event log and the parent's notes, runs the playtest-analyst,
  checks the spec's success signals, and turns findings into fixes, spec changes or content
  tweaks. Triggers on "playtest {slug}", "we played {slug}", "how did the session go",
  "/playtest {slug} before|after", "ми пограли", "плейтест", "як пройшла гра".
---

# Skill: playtest

Tests prove the code does what the spec says. Only the child can prove the spec was right. `playtest` closes that loop: a short watch list before playing, and an evidence-based debrief after. It replaces the web pipeline's post-deploy monitoring: the "production" is one three-year-old and one parent, offline.

Questions follow [`../_shared/ask-style.md`](../_shared/ask-style.md) and stay short: the parent is often writing this right after a session.

## Inputs

- `<slug>` (one or more features in the build) and the mode: `before` or `after`. No mode → `after` if a session log newer than the last playtest exists, else `before`.
- `docs/features/<slug>/spec.md` §4.1 Learning objective and §7 Success signals; `ux-flows.md` if present.
- The event log the game writes to `user://logs/events-<date>.jsonl` (on macOS: `~/Library/Application Support/Godot/app_userdata/<project name>/logs/`). The format is in `docs/contracts/autoloads.md` under the event logger.

## Mode `before`

1. Read §4.1, §7 and the ux-flows states.
2. Write `docs/playtests/<date>-<slug>.md` from [`./templates/playtest.md`](./templates/playtest.md), filling the **Watch for** list: 3–6 concrete things the parent can see without a laptop open (e.g. "does she tap the speaker to hear the word again?", "does the hand hint appear, and does she follow it?"), each tied to a success signal or a risk from the spec.
3. Remind the parent of the session rules from the design system: 15-minute timer, co-play optional, stop at the first sign of tiredness. Commit `playtest: <slug> plan <date>`.

## Mode `after`

1. **Collect.** Copy the newest session logs into `build/playtest/<date>/` (gitignored; the logs never leave the machine and are never committed). If there are none, say so and continue from notes only.
2. **Notes.** Ask the parent at most three questions: what made the child smile, where they got stuck or upset, anything surprising. Free text is fine, in any language.
3. **Analyse.** Dispatch [`playtest-analyst`](../../agents/playtest-analyst.md) (`subagent_type: "playtest-analyst"`; model `opus` on `route: full`) with the log path, the notes, §7 and the performance budget. Accept cited findings only.
4. **Record.** Fill the **After** half of `docs/playtests/<date>-<slug>.md`: session facts, each success signal met / not met / not measurable, findings, and the parent's verdict.
5. **Route each finding** with the parent: **Fix** (→ `/fix <slug>` with the finding as the bug report), **Change the spec** (a game-design change → `/specify <slug>` update or a new feature via `/interview`), **Content tweak** (words, audio, timings: a quick-route task), or **Watch next time** (added to the next `before` list). Write the decision next to each finding as it is made.
6. **Commit** `playtest: <slug> debrief <date>`. Handoff per [`../_shared/handoff.md`](../_shared/handoff.md) (utility variant) with the next command for the top finding.

## Rules

- **Privacy first.** OBS recordings, photos and the child's name never go into git or into a prompt sent off the machine. The log holds game events only. Notes refer to "the child". Timestamps in the event log let the parent line it up with the OBS recording locally.
- **The child's experience outranks the metrics.** If the parent says it went badly, it went badly, whatever the log says.
- **No grading the child.** Findings are about the game ("the target was too small"), never about the child ("she couldn't do it").
- **One session is an anecdote.** Prefer "watch next time" over a big spec change after a single session, unless the child was upset or something was unsafe.

## Definition of Done

- `before`: a watch list tied to the spec, committed.
- `after`: every success signal has a status, every finding has a route and evidence, the record is committed, and no log or personal data is in git.
