---
name: ship
model: inherit
effort: medium
agents: [explorer]
description: >
  Use to finish a reviewed feature: re-run the full gate, build and smoke-run the game, write the
  changelog, promote the lasting artifacts (spec, SAD, ADRs, contracts), clean up the temporary
  ones, and open the GitHub PR. Triggers on "ship {slug}", "prepare the PR for {slug}", "release
  {slug}", "/ship {slug}", "випусти {slug}", "готуй PR для {slug}". Never merges and never pushes
  without your go-ahead. Refuses if review has not passed.
---

# Skill: ship

There is no server to deploy to: the game ships as a macOS build that the parent installs. So `ship` proves the build works, records what changed, keeps the documents that stay true after release, deletes the scaffolding that doesn't, and opens a PR. After merge, `/playtest <slug>` takes over the role of a post-deploy watch.

Questions follow [`../_shared/ask-style.md`](../_shared/ask-style.md).

## Inputs

- `<slug>`.
- **Gate (hard refuse):** the latest `docs/features/<slug>/_review/review-*.md` says `PASS`. Otherwise → "run `/review <slug>` first".
- Commands from `docs/architecture-map.md` machine keys (`test_cmd`, `lint_cmd`, `export_cmd`), falling back to [`../implement/references/command-detection.md`](../implement/references/command-detection.md).

## Protocol

1. **Full gate.** Run all GUT tiers that exist (unit, integration, contract), the headless import check, and lint. Anything red → stop; this goes back to `/implement`.
2. **Build.** Run the macOS export (`export_cmd`, normally `<godot> --headless --path . --export-release "macOS" build/macos/<name>.zip`). A missing export preset or template → tell the human exactly what is missing and skip the build, recording it as **not verified**, never as passed.
3. **Smoke run.** If `tests/playthrough/` exists, run the scripted playthrough for this feature headless (it drives the scenes through the main flows and asserts no errors and the expected end state). Then, if a display is available, launch the build windowed for 30 seconds and read the log for script errors. State what ran and what could not; "tests pass" is not "it works".
4. **Changelog.** Prepend an entry to `CHANGELOG.md` at the repo root from [`./templates/changelog.md`](./templates/changelog.md): what the child and the parent can now do, why, the save-format note, and the ACs delivered.
5. **Promote lasting artifacts** (code is the source of truth; these stay because they explain why):
   - `adr/*.md` → `docs/adr/NNNN-<title>.md`, renumbered to the next free global number, with links fixed.
   - each `contracts/*.md` delta → merged into the living `docs/contracts/<name>.md` (bump its `version` and `last_changed: <slug>` frontmatter). Ask the human to confirm any save-format merge.
   - `spec.md` and `sad.md` stay in `docs/features/<slug>/`; add `status: shipped` and the ship date to their frontmatter.
   - `ux-flows.md` stays if the feature has UI; NEW components are already in `docs/design-system.md`.
   - update `docs/architecture-map.md` if the feature added an autoload, a folder or a pattern (bump its `commit:` key).
6. **Clean up temporary artifacts.** Delete `idea.md`, `test-plan.md`, `tasks/`, `tasks.json`, `_review/`, `contracts/contract-check.md`, and the now-promoted `adr/` and `contracts/` folders under `docs/features/<slug>/`. They live on in git history. List what was deleted in the handoff.
7. **Roadmap.** If `docs/roadmap.md` exists, mark the feature shipped.
8. **Commit** on the feature branch (never the default branch) per [`../_shared/write-and-commit.md`](../_shared/write-and-commit.md): `ship: <slug> changelog`, `ship: <slug> promote artifacts`, `ship: <slug> cleanup`, `ship: <slug> roadmap` (skipped when nothing changed).
9. **PR.** Write the body from [`./templates/pr-body.md`](./templates/pr-body.md) to `build/pr-<slug>.md`. Remote is GitHub (`origin`): **propose** `git push -u origin <branch>` and `gh pr create --base main --body-file build/pr-<slug>.md`. Run them only after the human says go. Never merge. The body suggests `@codex review` for an external AI review; posting it is the human's call.
10. **Handoff** per [`../_shared/handoff.md`](../_shared/handoff.md), terminal variant: what was verified and what was not, the build path, what was promoted and deleted, the commits, and the PR command or URL. Run next: merge (the human's call), then `/playtest <slug>` after the first sessions with the child.

## Definition of Done

- The full gate is green; the build was produced or its absence is stated with the reason.
- The feature was exercised beyond unit tests (playthrough and/or windowed run), or the gap is stated.
- `CHANGELOG.md` has an entry; ADRs and contracts are promoted; temporary artifacts are deleted; all committed on the feature branch.
- A PR body exists and the push/PR command was proposed (or run with the human's go-ahead).

## Anti-patterns

- **"Tests pass" = "it works".** Run the game.
- **Claiming a build you didn't make.** No export template means not verified.
- **Merging, or pushing unasked.** The human merges.
- **Deleting before promoting.** Promote ADRs and contracts first, then clean up, in separate commits.
- **A changelog that lists files.** Say what the child can now do and what changed for saves.

## Templates

- [`./templates/changelog.md`](./templates/changelog.md)
- [`./templates/pr-body.md`](./templates/pr-body.md)
