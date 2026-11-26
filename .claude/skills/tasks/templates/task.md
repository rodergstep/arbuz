---
id: T1
title: "<imperative, specific title>"
layer: "save|core|data|scene|ui|audio|tooling|build|tests|docs"
deps: []                # task ids that must finish first
blocks: []              # task ids waiting on this one — the inverse of `deps` (markdown only)
acs: ["AC-01"]          # spec §5 acceptance criteria this task satisfies
files_hint: ["path/or/dir/the/task/touches"]
owner: "<owner / TBD lead>"
estimate: "S"           # S/M/L or hours — how long the work takes
context_budget: "S"     # what the task costs the executing agent to hold (markdown only).
                        # Measured, not guessed: the non-empty lines from `## Why (user story)`
                        # through `## Acceptance criteria`.
                        # S = ≤40 inlined lines, ≤1 extra file to open
                        # M = ≤120 inlined lines, 2–4 files in play
                        # L = beyond that — split the task, or keep it and say why right here:
                        #     context_budget: "L"   # justified: <one line>
status: "todo"          # todo | in_progress | blocked | review | done — `implement` keeps it live
step: ""                # SELECT | BUILD | SMOKE | COMMIT — markdown only;
                        # for `blocked`, the reason: step: "GATE — lint red after 3 retries"
---

<!-- The governing rule of this file: **inline the slice the task actually needs, name where it came
from, and keep the link as the fallback for when the slice turns out not to be enough.** A task is
self-contained: it carries its own context instead of sending the executing agent off to reconstruct it.

Every inlined chunk ends with a one-line **provenance signature**:
`<file> §<section>, <identifier>, verbatim|abridged` — e.g. `spec.md §5, AC-02, verbatim`,
`contracts/save-format.md §What changes, abridged`. Never «see the spec».

**Inline budget.** Exactly what THIS task needs: only its own acceptance criteria, only the
contract items it touches. Cut a long chunk to the essential, mark it `abridged`,
and link the full text. `context_budget` in the frontmatter carries the measured number, and an `L`
either gets split or gets its `# justified:` reason on that line — the `tasks` skill checks both.

**Divergence risk.** An inline is a snapshot taken at breakdown time; upstream can move after it.
The source always wins — which is exactly why every chunk carries a signature pointing at where the
truth lives.

**To the executing agent:** work from what is inlined here. If a slice is insufficient, ambiguous,
or contradicts the code in front of you, open the named file for the full text and follow that.
Do not invent the missing part. -->

# T1 — <title>

## Place in the sequence

<!-- instruction: 2–4 lines. What must finish first (`deps`, by id + title), what is waiting on this
one (`blocks`, by id + title), and why it sits in this wave. Name the lane it shares if any — an
overlapping `files_hint` with another task, or a compile-coupled pair — so the executing agent knows
it is serialized rather than parallel. -->

- **Blocked by:** <T0 — title> · **Blocks:** <T4 — title, T5 — title> · **Wave:** <n, and why>.
- **Lane:** <shares `path/x` with T3 — serialized>, or «own lane».

## Why (user story)

<!-- instruction: the user story from spec §4 **verbatim** in its As a / I want / So that form, then
one sentence on what THIS task contributes to it. Signature under the quote. -->

> **As a** <role>
> **I want** <action>
> **So that** <observable benefit>
>
> — `spec.md §4, US-01, verbatim` · full text: [spec.md](../spec.md)

<one sentence: the part of that story this task delivers>

## Inlined context

<!-- instruction: the upstream slices the task actually needs, each as a quote + signature. Draw from:
spec §1 committed approach · spec §6 NFR and sad §11 Hard Rules the task must not violate ·
sad §5 the building block it lives in (its boundary + collaborators) · sad §6 the runtime steps it
implements · the decision line of any Accepted ADR that constrains it · `ux-flows.md` screen + its
states, for `ui` tasks. Cut to the essential, mark `abridged`, keep the link. This section replaces
the old list of links — it is never empty. -->

> <the quoted slice, cut to what this task needs>
>
> — `sad.md §6, «<flow name>» steps 3–5, abridged` · full text: [sad.md](../sad.md)

> **Hard rule:** <the constraint, verbatim>
>
> — `sad.md §11, RISK-02, verbatim` · full text: [sad.md](../sad.md)

**Fallback:** insufficient or contradicted by the code → read the named file in full
([spec.md](../spec.md) · [sad.md](../sad.md) · [ux-flows.md](../ux-flows.md) ·
[contracts/](../contracts/) · [adr/](../adr/) · [architecture map](../../../architecture-map.md)) and follow it. Do not guess.

## Contract delta

<!-- instruction: only the contract items this task touches, sliced from contracts/*.md with the signature:
save fields (+ migration name + fixture), word DB columns, Resource properties, autoload methods/signals,
tool flags. A task that touches no contract writes the sentence explicitly — an empty section is a defect. -->

- `LearningTracker.word_answered(word_id: StringName, correct: bool)` — signal, added
- Save: `words[].box: int` added, `migrate_v2_to_v3`, fixture `tests/fixtures/saves/v2.json`

— `contracts/autoloads.md §LearningTracker, abridged` · full text: [contracts/](../contracts/)

<!-- or, when the task touches no contract, the whole section is this one line: -->
No contract changes.

## Pattern to follow

<!-- instruction: the matching few-shot from docs/architecture-map.md §Pattern few-shots (name + path), and for
ui/scene tasks the SCR-NN + states from ux-flows.md and the design-system components used. -->

- Few-shot: `<name>` — `<path>`
- Screen/states: `SCR-NN` default, idle-hint-1, success, wrong — components `PictureCard`, `ChoiceRow`

## Acceptance criteria

<!-- instruction: one block per id in the `acs` frontmatter, Given-When-Then **verbatim** from
spec §5, each carrying its AC id and signature. These are what the test asserts — never paraphrase
them here. -->

### AC-01 — <coverage type>

> **Given** <preconditions>
> **When** <action>
> **Then** <observable outcome>
>
> — `spec.md §5, AC-01, verbatim` · full text: [spec.md](../spec.md)

## Checklist

<!-- instruction: atomic, ordered steps for the executing agent — the concrete change, scoped to
one commit. Each step names the file or dir it touches (consistent with `files_hint`). Save task:
the migration step + its fixture + the version bump. Keep it within one layer where possible. -->

- [ ] <step — `path/to/file`>
- [ ] <step — `path/to/file`>

## Edge cases

<!-- instruction: the cases the happy path does not cover, drawn from the §5 ACs and the sad §6
error branches. Behaviour is observable, not «handle gracefully». -->

| Case | Behaviour |
|---|---|
| <he taps the wrong card three times> | <the specified outcome> |
| <no input for 30 s> | <the specified outcome> |
| <gamepad disconnects mid-activity> | <the specified outcome> |

## Definition of Done

<!-- instruction: bullets checkable in the running game, then the smoke check. e.g.: -->
- [ ] <checked in the running game: what you did and what you saw>
- [ ] <a v<N> fixture save loads with every stat intact> (save tasks only)
- [ ] <played with mouse, keys and gamepad; reaches the spec'd state for AC-01> (scene/ui tasks)
- [ ] every Hard Rule inlined above still holds
- [ ] headless import clean (no script errors)
