# Probing frames — choose the lens that changes a decision

Internal lenses, not a script to exhaust. Ask one question, use the answer, then choose again.
Follow the [interview question exception](../../_shared/ask-style.md): open text for facts;
meaningful choices for decisions. A recommended option requires a basis in known constraints.
Do not label a speculative story as an observed incident.

| Lens | When useful | Engineering example | What to record |
|---|---|---|---|
| Premortem | Costly/uncertain change | “Six months after rollout we revert this. What is the most plausible reason, given these incidents?” | Assumption and a check that could disprove it |
| Second-order | Success increases load or ownership | “If adoption doubles, who operates this and what limit is reached first?” | Ownership/capacity unknown; evidence needed |
| Naive listener | Vague value or audience | “What would an engineer using this do differently after the change?” | Observable outcome in the actor's terms |
| Inversion | Solution chosen before problem | “Could the existing mechanism solve the incident if we changed its configuration?” | Reuse/no-change alternative; inspect the mechanism before claiming it works |
| Cost of waiting | Urgency drives scope | “What concrete consequence follows if this waits a month?” | Reported deadline/impact, or no established urgency |
| The other person | Another team owns a dependency | “What has the owning team actually agreed to support?” | Confirmed agreement vs assumption; never speak for the absent team |

## Toddler checks (for anything the child touches)

- **Alone:** can a 3-year-old do it with no reading and no adult, using only the hint ladder?
- **Wrong and idle:** what happens on a wrong pick, on 30 s of nothing, on random mashing?
- **Attention:** does one round fit in about 1–3 minutes? Does it end on a success?
- **Feelings:** could anything startle, frustrate or scare him (loud sounds, sudden motion, losing)?
- **Learning:** which words or concepts does it teach, and how will we see that he learned them?
- **Safety:** can it reach anything outside the game (links, purchases, network, the OS)?

## Engineering checks

Use the relevant checks, not all on every idea:

- **Existing contract:** what behavior must users/consumers retain?
- **Reversibility:** what could not be restored if the change fails?
- **Operational owner:** who monitors, supports, and decides rollback?
- **Observability:** what observation would distinguish success from apparent success?

A question about an existing fact may be answerable from a supplied issue or project file.
Read that first; ask the owner about intent, missing observations, or a consequential choice.
When an answer reveals a new assumption, drill it. When the position is clear, move on.
Explicit “summary” stops the questioning; a known blocker survives into the brief.
