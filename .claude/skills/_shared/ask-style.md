# Ask-style — how every skill phrases `AskUserQuestion`

> **Reference-only.** Not a skill. Every skill that asks the human a question reads this. The
> rule: an option **label is the next mechanical step** the skill takes; its **description says
> plainly what will happen**, what you gain and lose, and the hidden catch.

How **many** questions a skill asks scales with the depth dial ([`interview-depth.md`](./interview-depth.md)).
How each question is **phrased** does not: even a single easy-level question is explained.

## Language

Ask in the language the human is writing in (English or Ukrainian). Documents are always written
in English. Identifiers (ADR, GUT, autoload, signal names, file paths) stay as they are.

## Never ask dryly

1. **Gloss every non-obvious term on first use**, inline in parentheses. Not «use a Resource» but
   «use a Resource (a Godot data object saved as a `.tres` file that the editor can inspect)».
2. **Spend the words on the why and the trade-off**, not on restating the what.

## Shape

- **`question`** — 2–4 sentences: the context (what we're deciding, with a concrete game
  example), why it matters (save safety, the child's experience, performance on the Intel
  MacBook, reversibility), then «read the options».
- **Each option**:
  - `label` — 1–5 words, action form: «Accept», «Change it», «Move to open questions», «Drop»,
    «Record as ADR». Add «(Recommended)» to the first option when you recommend it.
  - `description` — 2–4 sentences covering: **what technically happens** (concrete names: the
    autoload, the scene, the file, the ADR number), **gain / loss** in plain words, **the next
    step** the skill takes, and **the hidden catch** if there is one («this only works if every
    scene goes through InteractionSystem», «old saves will need a migration»).

## Toddler-game framing

When a question affects what the child experiences, describe it from the child's side: «he taps
the wrong card three times: with option A the hint hand appears; with option B the card wiggles
and the voice repeats the word». The human judges child experience better from a scene than from
an abstraction.

## The 4-state actions (canonical set)

```
- label: "Accept as is"
  description: "I keep the decision word for word and run the next check (a gate, if this section has one)."
- label: "Change it"
  description: "You give the new wording or value; I regenerate the decision under it and ask once more. The second answer is final."
- label: "Move to open questions"
  description: "I take the decision out of the section and add a row to the open-questions table with an owner and a due point (I ask for both next). Without both it becomes a Drop."
- label: "Drop"
  description: "I remove the decision. If it is mandatory, I reframe the options and ask again; if optional, it stays out."
```

## Interview exception

`interview` asks **one substantive question at a time**, after reusing what is already known.
Facts go as open questions with no recommended answer (the human knows what happened). Decisions
get two to four real options; recommend one only with an evidence-based reason. Shorter
descriptions are fine there. No response is never consent.

## Forbidden

- Bare labels with one-line descriptions («Approve» / «Apply decision.»).
- Unglossed jargon.
- Trade-offs hidden for a follow-up question.
- Manufactured alternatives to fill a menu.
