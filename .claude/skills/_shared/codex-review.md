# Codex cross-vendor review

A second reviewer from a different vendor catches what a same-family model shares as a blind spot. `review` runs it in addition to the Claude `reviewer`, never instead of it.

## When

| `codex_review` setting | Runs on |
|---|---|
| `auto` (default) | `route: full` only |
| `always` | every review |
| `never` | never |

Skip silently (and say so in the review record) if `codex` is not on `PATH`.

## How

1. Write the prompt to `docs/features/<slug>/_review/codex-prompt.md`:
   - the base commit and `git diff --stat <base>..HEAD`
   - paths to `spec.md` §5, `sad.md`, the contract deltas, and `docs/architecture-map.md`
   - the review dimensions from `review/references/review-dimensions.md`, condensed
   - the output rule: every finding cites `file:line` and the AC or contract it touches; no finding without a citation; end with `REVIEW_CLEAN` if nothing is found
2. Run it read-only from the repo root:

   ```bash
   codex exec --sandbox read-only "$(cat docs/features/<slug>/_review/codex-prompt.md)" \
     > docs/features/<slug>/_review/codex-$(date +%F).md
   ```

3. Merge: keep only cited findings, tag each `source: codex`, and de-duplicate against the Claude reviewer's list (a finding both found is marked `source: both`, which raises its priority). Resolve them with the human like every other finding.

## On the PR

`ship` adds a line to the PR body suggesting `@codex review` on GitHub. Posting that comment is the human's call, never the agent's.

## Rules

- Codex never edits files in this flow (`--sandbox read-only`).
- Disagreement between the two reviewers is a signal to look closer, not a vote. The human decides.
- Never send secrets, keys or the child's personal data in the prompt. The prompt holds paths and the diff stat only; Codex reads the files itself.
