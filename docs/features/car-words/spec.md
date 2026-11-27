---
status: building
feature_size: S
route: quick
updated_at: "2026-11-27"
---

# Spec (lite) — The car's words (roadmap step 28, part 1)

## 5. Acceptance criteria

- **AC-01 Words as they happen.** While he drives, Tygrytsa names what the car does: "Go! The car
  goes!" when it starts, "Stop! The car stops." when it stops, "Left! We turn left." / "Right! We
  turn right." on a real turn (relative to the car), "Beep beep! The horn!" for the horn.
- **AC-02 Teach first.** The first time each of go, stop, left, right, horn comes up, its learning
  card opens (paced by the LearningDirector), with scenes for its sentences (arrows for left and
  right). After that only the short line.
- **AC-03 Not chatty.** One car word at most every 6 s, the same word not again for 25 s, never
  over other speech or a card.

## Part 2 — hidden treasures

- **AC-04 Treasures to find.** Each town hides three treasures, peeking out beside a house or a
  barn with a twinkling star above: the village a teddy, a kite and a star; England an umbrella,
  a teapot and a crown.
- **AC-05 Each teaches a word.** Clicking one: "A treasure! You found a teddy!", its learning
  card (with scenes), and it is remembered (`treasure:<id>`); found ones don't come back. All
  three found: "You found all the treasures! Hooray!".
