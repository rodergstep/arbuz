# design — question shapes (examples)

Phrasing rules → [`../../_shared/ask-style.md`](../../_shared/ask-style.md).

## A strategic decision that will spawn an ADR

```
question: "Where should the per-word learning stats live? Every activity reports picks, and the
  stats decide which words come back for review, so whichever part owns them is seen by every
  chapter. Moving them later means touching every activity scene and the save format. Read the
  options below."
options:
  - label: "LearningTracker owns them (Recommended) → ADR-0004"
    description: "One autoload keeps the stats; scenes only send picks through InteractionSystem.
      Gain: one place to test with GUT, one save section, scenes stay dumb. Loss: every new
      activity must go through InteractionSystem, never around it. Next: I write ADR-0004 and a
      §9 row, and the save contract gets a `words` section."
  - label: "Each activity keeps its own stats"
    description: "Each scene saves what it learned. Gain: activities are independent. Loss:
      review choice needs to merge stats from many places, and each scene touches the save file.
      Catch: two scenes counting the same word differently is likely."
```

## A borderline gate

```
question: "This is borderline for an ADR: using a Tween instead of an AnimationPlayer for the
  card bounce is cheap to change, but three activities will copy the pattern. Record it?"
options:
  - label: "Keep it inline (Recommended)"
    description: "I note it in §5's block table. If more activities copy it, a later task will
      flag it and we can record an ADR then."
  - label: "Record as ADR"
    description: "I write a short ADR so later activities follow the same pattern."
```

## Save-as-open-question follow-up

```
question: "Who decides this, and by when? Without an owner and a due point it becomes a Drop."
options:
  - label: "Parent, before tasks (Recommended)"
    description: "I add a §11 row with severity `Open question`, owner Parent, due «before /tasks»."
  - label: "Parent, at the next gate"
    description: "Same row, due «at Gate N playtest»."
```
