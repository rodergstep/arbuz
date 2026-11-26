---
updated_at: "<YYYY-MM-DD>"
feature_size: "<from .size>"
---

# Test plan — <feature>

## AC coverage

<!-- instruction: every spec §5 AC → ≥1 test. Tier from: unit | integration | contract | playthrough | perf | playtest.
Test names describe behaviour. Fixture = the file the test needs, or —. -->

| AC | Test | Tier | File | Fixture |
|---|---|---|---|---|
| AC-01 | `test_correct_pick_fills_a_star` | playthrough | `tests/scenes/test_bakery_cards.gd` | — |
| AC-02 | `test_wrong_pick_repeats_target_word` | playthrough | `tests/scenes/test_bakery_cards.gd` | — |
| AC-04 | `test_wrong_word_returns_in_same_session` | unit | `tests/autoload/test_learning_tracker.gd` | `tests/fixtures/words/bakery.json` |

## Toddler cases

| Case | Expected | Test |
|---|---|---|
| idle 8 s | hint level 1 | `test_idle_shows_hint_level_1` |
| mashing (≥5 taps in 2 s) | calm line + hint level 2 | `test_mashing_triggers_calm_hint` |
| walks away (60 s) | auto-pause, resume where he was | `test_long_idle_pauses_and_resumes` |
| gamepad disconnects | focus stays, mouse/touch still work | `test_gamepad_disconnect_keeps_play` |

## Contracts and fixtures

<!-- instruction: one row per persisted or shared contract this feature touches. -->

| Contract | Test | Fixture |
|---|---|---|
| save v<N>→v<N+1> | `test_migrates_v<N>_fixture` | `tests/fixtures/saves/v<N>.json` |

## Test isolation

- Tests use a temporary profile directory, created in `before_each` and removed in `after_each`; never the real `user://saves`.
- Autoload state is reset between tests (`<how>`).

## Gate observations (manual)

<!-- instruction: what /playtest should add to the next gate's checklist. N/A if nothing. -->

- **Perf:** <scene / moment to measure on the Intel MacBook>
- **Playtest:** <what to watch: does he find the card without help? does he repeat the word?>
