---
name: review
model: inherit
effort: high
agents: [reviewer, contract-checker]
description: >
  Use to run an independent, clean-context review of an implemented feature against its spec,
  contracts and the toddler-UX rules before shipping. Triggers on "review {slug}", "code review
  {slug}", "is {slug} ready to ship", "/review {slug}", "переглянь зміни {slug}", "код-рев'ю фічі
  {slug}". Dispatches the reviewer subagent over the whole feature diff (stage 1 spec, contracts
  and child safety; stage 2 quality, toddler UX, performance), adds a Codex cross-vendor pass on
  the full route, and resolves each cited finding with you. Refuses if nothing is implemented.
---

# Skill: review

The independent review gate. After `implement` has written, tested and committed the code, `review` looks at the **whole change at once, with fresh eyes**. The per-task gate proves each task green; review asks whether the feature as a whole does what the spec says, keeps the save and word contracts, and is safe and pleasant for a three-year-old.

It uses the clean-context discipline in [`../_shared/critic.md`](../_shared/critic.md), the read-only [`reviewer`](../../agents/reviewer.md) agent, and on the full route a Codex pass per [`../_shared/codex-review.md`](../_shared/codex-review.md). Questions follow [`../_shared/ask-style.md`](../_shared/ask-style.md).

## Inputs

- `<slug>`.
- **Gate (hard refuse):** commits on the feature branch, or a non-empty working diff. Nothing to review → "run `/implement <slug>` first".
- The reviewer re-reads these itself (no paraphrase): `spec.md` §4–§6, `sad.md` (§4 areas, §6 flows), `contracts/` deltas, Accepted ADRs, `ux-flows.md` if present, `test-plan.md`, `tasks.json`, `docs/architecture-map.md`, `docs/design-system.md`.

## Protocol

1. **Scope the diff.** `git diff <base>..HEAD`, where base is the branch point. Note the `SDD-AC` trailers: the ACs the work claims.
2. **Contract drift check** (skip on quick when no contract was touched). Dispatch [`contract-checker`](../../agents/contract-checker.md) per [`../contracts/references/drift-check.md`](../contracts/references/drift-check.md) against the code as built. `DRIFT_FOUND` items become stage-1 findings.
3. **Dispatch the reviewer.** `subagent_type: "reviewer"`, read-only, clean context, model per `judgment_model` (effort `xhigh` on L/XL) per [`../_shared/agent-roster.md`](../_shared/agent-roster.md), along [`./references/review-dimensions.md`](./references/review-dimensions.md):
   - **stage 1** (blocks ship): AC compliance; the end-to-end trace of the whole §4/§5 set (not only the trailers); contract fidelity; save compatibility; child safety and privacy.
   - **stage 2** (usually non-blocking): conventions and patterns, toddler UX, performance budget, content, test adequacy.
   - **mutation spot-check** on `route: full`: the reviewer names up to three lines in core logic whose mutation (flip a comparison, drop a call, return early) should break a test, and the engine tries each one and reverts it. A surviving mutant is a stage-2 finding about test strength.
   For a large diff, fan out one reviewer per stage and merge.
4. **Codex pass** when [`../_shared/codex-review.md`](../_shared/codex-review.md) says so. Merge its cited findings tagged `source: codex`.
5. **Resolve each finding with the human, writing as you go.** Before the first question, create `docs/features/<slug>/_review/review-<date>.md` (scope, diff stat, gate `pending`). After **each** resolution append the finding and its verdict. Options: **Fix now** (a follow-up task back through the TDD loop) / **Defer** (spec §8 row with owner and due) / **Not an issue** (record why). Never ship with an open stage-1 finding.
6. **Finalize** the record with `PASS` or `CHANGES REQUESTED`.
7. **Commit** per [`../_shared/write-and-commit.md`](../_shared/write-and-commit.md): `review: <slug> review-<date>.md` (and `review: <slug> spec.md deferred findings` if a Defer changed the spec).
8. **Handoff** per [`../_shared/handoff.md`](../_shared/handoff.md): `PASS` → `/clear`, then `/ship <slug>`. `CHANGES REQUESTED` → `/implement <slug>` for the fixes (stay in context), then re-review the changed part.

## Definition of Done

- The clean-context reviewer ran over the whole feature diff; on full, Codex ran too (or its absence is recorded).
- The whole §4 story set and §5 AC set was traced spec → flows → contracts → tasks → code and test.
- Contract drift was checked when contracts were touched.
- Every finding is resolved; no open stage-1 finding.
- A review record exists with a verdict. The reviewer pass is this skill's structural self-check ([`../_shared/self-check.md`](../_shared/self-check.md)).

## Anti-patterns

- **Reviewing in the context that wrote the code.** The point is fresh eyes.
- **Uncited findings.** Cite `file:line` and the AC or contract, or drop it.
- **Trusting the trailers as the full AC set.** An AC no task claimed is the most dangerous gap.
- **Waving through a save-format change without a fixture test.** Old saves must load; that is stage 1.
- **Judging toddler UX by adult taste.** Check against the design-system rules (voiced instruction, no fail state, target size, hint ladder), not preference.
- **Letting the two reviewers vote.** Codex and Claude disagreeing is a reason to look closer; the human decides.

## References

- [`./references/review-dimensions.md`](./references/review-dimensions.md): dimensions and dispatch shape.
- [`../_shared/codex-review.md`](../_shared/codex-review.md): the cross-vendor pass.
- [`../_shared/critic.md`](../_shared/critic.md): clean-context dispatch discipline.
