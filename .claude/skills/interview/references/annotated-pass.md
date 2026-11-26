# Annotated adaptive pass — game feature

Illustrative dialogue, **not an executed eval or evidence of real play sessions**.
The owner's replies below are test inputs, not verified facts.

## Starting context

Owner: “She keeps asking what sound the cow makes. I want an animal sounds activity on the farm
map. Ukrainian voice, maybe English later. No new menu.”
Saved ceiling: medium. No opening depth question. The interviewer preserves this raw text and reads
`docs/game-spec.md` (farm map section) and `docs/development-plan.md` (current phase).

> Illustrative file evidence: the game spec lists the farm map as the hub and the hint ladder
> as a standing rule. A real run must cite the actual file and section, not this example.

## Questions adapt to evidence

**Q1 — fact, open text:** “When she asks about the cow, what does she do right after you answer?”
Owner: “She makes the sound herself and laughs, then asks about another animal.”

Record this as owner-reported. Do not infer a learning outcome or how often it happens.

**Q2 — decision:** “Should the first version be ‘tap an animal, hear its sound and name’, or ‘hear a
sound, find the animal’?”
Recommend tap-to-hear first: it has no wrong answer, matches what she already does, and the
find-the-animal game can reuse it later. Explain that the find game adds wrong-answer handling and
a hint ladder.
Owner: “Tap-to-hear first. Six animals.”

**Scoped evidence check:** look for an existing word-DB entry format and voice-line folder. If absent,
record that the word DB is a prerequisite and do not assume its shape.

**Q3 — accepted direction:** “Six farm animals on the map, tap to hear the sound then the Ukrainian
name, no wrong answers, no new menu. Is that the direction to specify?”
Owner: “Yes.”

Three substantive questions under a medium ceiling; no quota.
The owner confirmed the direction, not independent truth of every premise.

## Result

Outcome: `ready-for-specify` when the word DB exists or is listed as a dependency. §2 records the
reported behaviour and intent; §5 keeps "no new menu" and "Ukrainian first"; §6 separates owner
report from file evidence; §7 records the rejected find-the-animal variant as a later step.

## Contrasting endings

- If recording or storing the child's own voice comes up, dispatch `mode: interview` critique even
  at an easy ceiling: it is a privacy decision.
- If no word DB exists and its shape is unknown, outcome is `needs-evidence` or a roadmap
  dependency: name it. Do not promise the activity can ship alone.
- If the owner says “summary” before Q3, record the recommendation as unconfirmed; not ready.
- In Plan Mode, return the proposed brief in the conversation without writes.
- In headless mode, stop before this dialogue: example answers are not a live owner.
