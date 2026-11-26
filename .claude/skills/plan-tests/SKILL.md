---
name: plan-tests
model: inherit
effort: medium
agents: []
description: >
  Use to map every acceptance criterion to at least one test before any code exists — GUT unit,
  GUT integration, contract (save fixtures, data validation), scripted playthrough (GUT driving
  input through a scene), plus the manual performance check and playtest observations at gates.
  Triggers on "test plan for {slug}", "plan tests", "how do we test {slug}", "/plan-tests {slug}",
  "план тестів {slug}", "як тестуємо {slug}". Writes an inline ## Test plan in spec.md (quick /
  small) or docs/features/{slug}/test-plan.md (standard M+ / full). Hard-refuses without spec.md.
---

# Skill: plan-tests

Ties every `spec.md` §5 AC to named tests **before** the code exists, so the `test-author` agent
writes tests from the ACs and not from whatever the code happens to do (the oracle problem).

Question phrasing → [`../_shared/ask-style.md`](../_shared/ask-style.md). Target (inline vs file)
→ [`../_shared/size-matrix.md`](../_shared/size-matrix.md). Areas → tiers →
[`../_shared/game-areas.md`](../_shared/game-areas.md).

## The test tiers (fixed vocabulary)

| Tier | What it proves | How it runs |
|---|---|---|
| `unit` | one script's logic: a rule, a calculation, a state change | GUT, headless, every task |
| `integration` | autoloads working together (InteractionSystem → LearningTracker → SaveSystem) | GUT, headless, every task |
| `contract` | saves, data and APIs hold their contract: every fixture save migrates and validates; every data file loads; every word id has audio; public methods/signals exist with the right arguments | GUT, headless, every task |
| `playthrough` | a scene reaches the spec'd state under simulated input (taps, idle time, mashing, gamepad focus) | GUT with input simulation, headless where the scene allows, else windowed |
| `perf` | ≥30 fps / ≤10 s load on the Intel MacBook | manual at gates; a scripted fps probe scene helps |
| `playtest` | the child can do it, enjoys it, learns from it | manual at gates (`/playtest`) |

**Mutation spot check** (`full` only): the reviewer flips 2–3 conditions in the new code and
confirms a test fails each time; a surviving mutation means a missing test. There is no mature
GDScript mutation tool, so this is a manual check, recorded in the review.

## Inputs

- `<slug>`; **gate (hard refuse):** `docs/features/<slug>/spec.md`.
- (Optional) `ux-flows.md` (flows → playthrough scripts; states → assertions), `sad.md` §6
  (sequences → integration tests), `contracts/*.md` (→ contract tests, fixtures), `.size`/`.route`.

## Protocol

1. **Gate + target.** Quick route or XS/S → inline `## Test plan` in `spec.md`; otherwise
   `docs/features/<slug>/test-plan.md` from [`./templates/test-plan.md`](./templates/test-plan.md).
   Bootstrap the target now; rows land on disk as they are decided.
2. **Map every AC.** For each §5 AC propose tiers by heuristic (a rule → `unit`; a flow across
   systems → `integration`; anything persisted → `contract` with a fixture; anything the child
   does in a scene → `playthrough`; a performance NFR → `perf`; "he can do it / learns it" →
   `playtest`). Confirm with the human (one multi-select question per AC at medium/hard; a
   batched ledger at easy). Name each test after the behaviour (`test_wrong_pick_repeats_target_word`).
3. **Toddler rows.** Every toddler-error AC gets its own rows (wrong pick, idle per hint level,
   mashing, walking away, gamepad disconnect) — never folded into the happy path.
4. **Fixtures and data.** Name the fixtures: save files per version under `tests/fixtures/saves/`,
   small word lists under `tests/fixtures/words/`, any scene stubs. State cleanup: tests never
   write to the real `user://`; they use a temp profile directory set up and removed per test.
5. **Gates.** List which `perf` and `playtest` observations this feature adds to the next gate
   (they go into the `/playtest` checklist).
6. **Structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)), 5 items:
   (1) every §5 AC id is in the table; (2) every toddler-error AC has its own rows; (3) every tier
   value is from the vocabulary; (4) every persisted change has a `contract` row with a fixture;
   (5) the plan sits at its target. Report `N/5`.
7. **Commit + handoff.** `plan-tests: <slug> test-plan.md` (or `spec.md`). Handoff per
   [`../_shared/handoff.md`](../_shared/handoff.md): `/implement <slug>`.

## Anti-patterns

- **An AC with no test.**
- **Tests that write to the real `user://`** — they corrupt the child's saves on the dev machine.
- **Only unit tests for a scene feature.** The bugs toddlers find are in the playthrough tier.
- **Planning tests from the code** (after it exists). The plan comes from the ACs.
- **Inventing a perf target** the spec doesn't state.
