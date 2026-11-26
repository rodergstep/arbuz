---
name: config
model: inherit
effort: medium
agents: []
description: >
  Use to create and tune the per-machine settings file `.claude/sdd.local.md`: how deeply the
  pipeline interviews you, which models the agents run on, how strict the TDD gate is, how work
  is committed, where Godot lives, and when Codex reviews. Triggers on "config", "settings",
  "tune the pipeline", "change the judgment model", "set the interview depth", "/config",
  "налаштування", "налаштуй sdd", "зміни модель", "глибина опитування". Creates the file with
  defaults first, shows what differs, asks four grouped questions, and patches only the keys
  you confirm, preserving comments, key order and unknown keys.
---

# Skill: config

The settings file has many creators and **one editor: this one**. `interview`, `survey`, `roadmap`, `scaffold`, `specify`, `implement` and this skill create `.claude/sdd.local.md` with defaults when it is missing, so the pipeline always finds a real file. Only `config` offers to change values.

The template, create procedure, `.gitignore` patch and key meanings are canonical in [`../_shared/settings-file.md`](../_shared/settings-file.md). This skill is the conversation over it.

## Inputs

Nothing is required. An existing `.claude/sdd.local.md` is read, diffed against the defaults, and patched in place, never regenerated.

## Protocol

1. **Ensure the file.** Absent → create it per [`../_shared/settings-file.md`](../_shared/settings-file.md) and say «`.claude/sdd.local.md` created with defaults». Present → read it.
2. **Report the current state** in three lines: keys that differ from the defaults (both values), unknown keys and comments (kept verbatim), and whether the frontmatter parsed. A malformed frontmatter is never repaired silently: show the failing lines and offer «rewrite from the template» (naming what is lost) or «fix it by hand».
3. **Defaults or tune?** One question per [`../_shared/ask-style.md`](../_shared/ask-style.md). «Stay on defaults» → step 6.
4. **Ask the four grouped questions** in two `AskUserQuestion` calls, grouped by decision, not by key. Wording and the question → keys map → [`./references/interview.md`](./references/interview.md). The `cmd_*` keys are not asked: empty means autodetect, which beats a pinned command that rots. `godot_bin` is asked only if Godot was not found on PATH or in `/Applications`.
5. **Patch the confirmed keys**, key by key, keeping comments, key order and unknown keys. Print `old → new` per changed key, and list separately anything derived rather than asked (for example `godot_bin` found automatically).
6. **Self-check + handoff.** Re-read from disk ([`../_shared/self-check.md`](../_shared/self-check.md)) and verify 5 items: (1) the file exists; (2) the frontmatter parses and every confirmed key holds its value; (3) no key present before was dropped; (4) every inline comment survived; (5) `.gitignore` contains `.claude/*.local.md` exactly once. Commit `config: .gitignore sdd settings` only if `.gitignore` changed; the settings file itself is gitignored. Emit the handoff per [`../_shared/handoff.md`](../_shared/handoff.md) (utility variant).

## Definition of Done

- `.claude/sdd.local.md` exists and parses.
- Confirmed keys hold the confirmed values; everything else is byte-identical.
- Derived values were named separately from asked ones.
- `.gitignore` covers `.claude/*.local.md`.

## Anti-patterns

- **Asking before creating.** The file lands with defaults first.
- **Regenerating from the template.** That is how a hand-written comment disappears.
- **Asking about `cmd_*`.** Autodetect is the recommended answer.
- **A settings question inside another skill.** Other skills create and read; only `config` tunes.

## References

- [`../_shared/settings-file.md`](../_shared/settings-file.md): template, procedure, key meanings.
- [`./references/interview.md`](./references/interview.md): the four questions and the key map.
- [`../_shared/agent-roster.md`](../_shared/agent-roster.md): what the model choices change.
- [`../implement/references/settings.md`](../implement/references/settings.md): how the engine reads its keys.
