<!-- PR body for `gh pr create --body-file`. -->

## Summary

<1–3 sentences: what this PR ships and why. Link [spec](docs/features/<slug>/spec.md).>

## Acceptance criteria

- AC-01: <outcome> ✓
- AC-0N: <outcome> ✓

## Design

- Spec: `docs/features/<slug>/spec.md`
- Architecture: `docs/features/<slug>/sad.md`
- Decisions: `docs/adr/<NNNN>-...md`
- Contracts changed: `docs/contracts/<name>.md` (<what changed>)

## Tasks

<`git log --format='%h %s' --grep SDD-Task <base>..HEAD`>

## Verification

- GUT unit / integration / contract: <counts, green>
- Import check + gdlint: <result>
- macOS export: <built at build/macos/... | not verified: reason>
- Playthrough / windowed run: <what was exercised | what could not run>

## Saves and content

- Save format: <version change and migration, or none>
- Content: <words/audio added, or none>

## Review

- Claude reviewer: `PASS` (record deleted at ship; see git history)
- Codex: <ran on full route | not run>. For an external pass, comment `@codex review` on this PR.
