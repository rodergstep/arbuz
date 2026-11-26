---
name: contracts
model: inherit
effort: medium
agents: [contract-checker, explorer]
description: >
  Use to fix the contracts a feature changes — the save-file JSON schema and its version
  migrations, the word database schema, content Resource classes, autoload public APIs (methods +
  signals), and tool CLIs — then run the contract-checker for drift against data, code and spec.
  Triggers on "contracts for {slug}", "save format for
  {slug}", "autoload API for {slug}", "word db schema", "/contracts {slug}", "контракти для {slug}",
  "формат збереження". Hard-refuses without spec.md; reads sad.md areas when present.
---

# Skill: contracts

A game's contracts are not REST endpoints. They are the things many parts of the game (and old
save files on the child's machine) depend on, so changing them silently breaks something far away:

| Contract | File (feature draft → living copy after `ship`) | Who depends on it |
|---|---|---|
| **Save format** | `contracts/save-format.md` → `docs/contracts/save-format.md` | every existing save file, SaveSystem, LearningTracker |
| **Word database** | `contracts/word-db.md` → `docs/contracts/word-db.md` | the voice script, LearningTracker, every activity |
| **Content data** (`Resource` classes for chapters, quests, dialogue) | `contracts/content.md` → `docs/contracts/content.md` | chapter scenes, QuestSystem |
| **Autoload APIs** (public methods + signals) | `contracts/autoloads.md` → `docs/contracts/autoloads.md` | every scene and UI that calls them |
| **Tool CLIs** (voice script, Blender scripts, build scripts) | `contracts/tools.md` → `docs/contracts/tools.md` | the pipeline that generates assets |

Question phrasing → [`../_shared/ask-style.md`](../_shared/ask-style.md). Which contracts a
feature touches follows its declared `areas` → [`../_shared/game-areas.md`](../_shared/game-areas.md).

## Owner

The human reviews **every save-format change** personally. This is the rule that replaces "review
migrations so the big table doesn't lock on prod": here the risk is that the child opens the game
after an update and his progress, stickers and learned words are gone.

## Inputs

- `<slug>`.
- **Gate (hard refuse):** `docs/features/<slug>/spec.md` → «run `/specify <slug>` first».
- `docs/features/<slug>/sad.md` (expected on standard/full): frontmatter `areas`, §5 building
  blocks, §6 sequences. Absent (legal on `quick`) → derive the touched contracts from the spec
  and the code, and say so.
- The living contracts in `docs/contracts/` (the current truth) and the code they describe.
- `docs/features/<slug>/.size`, `.route`.

## Protocol

1. **Gate + scope.** Read the spec, the SAD, and the living `docs/contracts/*.md`. List which of
   the five contracts this feature changes, citing the AC or SAD line that forces each change.
   None changes → say so and hand off to `/tasks <slug>` (that is the N/A condition).
2. **Ground in the code.** Dispatch `explorer` (`subagent_type: "explorer"`, fallback `Explore`)
   for the current state of each touched contract in code: the save serializer, the word DB
   loader, the autoload scripts (public methods and `signal` declarations), the `Resource`
   classes. It returns `file:line` citations only, no dumps.
3. **Draft each touched contract** from its template, as a **delta** against the living copy
   (what is added, changed, removed), one contract at a time, confirming each with the human:
   - **Save format** → [`./templates/save-format.md`](./templates/save-format.md): bump
     `version` whenever a field is added, renamed, retyped or removed; write the migration
     function signature (`migrate_v<N>_to_v<N+1>(data: Dictionary) -> Dictionary`) and the
     **fixture saves** it must pass (an old-version save file under `tests/fixtures/saves/`). Rules
     → [`./references/save-migrations.md`](./references/save-migrations.md). Ask the human to
     approve the save delta explicitly, even at `easy` depth.
   - **Word DB** → [`./templates/word-db.md`](./templates/word-db.md): columns, types, allowed
     values, which tool and which system read each column.
   - **Content** → [`./templates/content.md`](./templates/content.md): `Resource` class name,
     exported properties, validation rules.
   - **Autoloads** → [`./templates/autoloads.md`](./templates/autoloads.md): for each touched
     autoload, the public methods (typed signatures), the signals (typed arguments), who calls or
     connects, and what is private. A removed or renamed public method/signal is a breaking change:
     list every caller and record an ADR via `/decide-adr` if one doesn't exist.
   - **Tools** → [`./templates/tools.md`](./templates/tools.md): command, flags, inputs, outputs,
     exit codes.
   Write each section to disk as soon as it is confirmed ([`../_shared/write-and-commit.md`](../_shared/write-and-commit.md)).
4. **Contract check (separate agent).** Dispatch `contract-checker` (`subagent_type:
   "contract-checker"`, clean context) with the paths of the drafted contracts, the spec, the SAD
   and the code roots. It checks the four drift points in
   [`./references/drift-check.md`](./references/drift-check.md) and writes
   `docs/features/<slug>/contracts/contract-check.md`. Resolve each finding with the human:
   fix the contract, fix the spec (rare, via `clarify`), or record a deliberate exception.
5. **Structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)) — the
   contract-checker report is the heavy verifier; add only: (1) every touched contract file
   exists and has no template placeholders; (2) a save-format change bumps `version` and names a
   migration and ≥1 fixture save; (3) every removed/renamed public API item lists its callers;
   (4) `contract-check.md` has no open `✗` without a recorded resolution. Report `N/4`.
6. **Commit + handoff.** One commit per contract file (`contracts: <slug> save-format.md`, …) plus
   `contracts: <slug> contract-check.md`. Then the stage-handoff block
   ([`../_shared/handoff.md`](../_shared/handoff.md)): *Review* lists every contract with a
   one-liner (save changes first), *Run next* `/tasks <slug>`.

The living copies in `docs/contracts/` are **not** edited here; `ship` merges the feature's
deltas into them once the code is merged, so the living copy always matches the code.

## Definition of Done

- Every contract the feature changes has a delta file; untouched contracts are listed as such.
- Save-format changes: version bumped, migration named, fixture saves listed, human approved.
- `contract-check.md` exists and every finding is resolved or explicitly accepted.

## Anti-patterns

- **Changing a save field without a version bump.** Old saves then load with silent defaults or crash.
- **Deleting a migration step** "because no one has that version anymore". The child's Mac might.
- **Calling an autoload's private method from a scene** instead of adding it to the contract.
- **Content in code.** A new chapter's words or quest steps belong in `data/`, validated by the
  contract, not hard-coded in a scene script.
- **Copying the whole living contract** into the feature folder. Write the delta.
