---
status: Draft
owner: "<feature owner>"
reviewers: ["Parent"]
updated_at: "<today YYYY-MM-DD>"
feature_size: "<from classify-size: XS/S/M/L/XL>"
---

# Spec — <slug>

<!-- instruction: one-line links to inputs used.
> **Glossary:** [CONTEXT](./CONTEXT.md) (if present)
> **Reference module / docs / channels used:** name the specific paths/queries read in step 5, or «None — only the interview + CONTEXT».
Do not mention competitive-research or ideation scratch work here — those inform §1, they are not inputs to cite. -->

## 1. Context

<!-- instruction: 3–4 paragraphs.
¶1 What we're solving — the concrete problem from the interview, for whom (cite a user segment).
¶2 Why now — the trigger (incident, contract, deadline, strategic shift).
¶3 The committed approach — 1–2 sentences. For M+/L this is the recommendation from the ideation pass; for XS/S it's the obvious direction from the deep-dive.
¶4 (optional) Traceability context — reference-module patterns or quoted sources, AND the slot where critic `Override` resolutions emit «Decision override: <headline> — rationale: <reason>» bullets.
This section is WHAT + WHY, not HOW. Do NOT name a concrete datastore / broker / framework / library here — that belongs to design. -->

## 2. Goals

<!-- instruction: 2–3 measurable strategic outcomes as a bullet list. Each is a manifestation of the committed approach (§1 ¶3). No raw numbers here — numbers live in §7 KPIs. -->

## 3. Non-goals

<!-- instruction: 3–4 explicit non-goals, each one sentence + a reason. Keeps scope honest. -->

## 4. User stories

<!-- instruction: enough stories to cover every role and every goal. Roles from the glossary:
usually **Child** (player, 3+, pre-reader) and **Parent** (co-player, settings, tester).

### US-NN: <3–6 word action title>
**As a** <role>
**I want** <action>
**So that** <observable benefit — for the child, a feeling or a learning outcome>

Each US is covered by ≥1 AC in §5. -->

### US-01: <title>

**As a** <role>
**I want** <action>
**So that** <benefit>

## 4.1 Learning objective

<!-- instruction: which words/concepts this feature teaches or reviews (word ids from the word DB, or "none —
pure play/navigation"), in which language(s), and how we would see that he learned them (in-game
stats, recognizing the word a few days later). -->

- **Words / concepts:** <…>
- **Evidence of learning:** <…>

## 5. Acceptance criteria

<!-- instruction: Given/When/Then, from the player's perspective. ≥1 AC of EACH of the 5 coverage types:

1. happy — the child does the main thing → the game responds and celebrates.
2. toddler-error — wrong pick / idle / mashing / walking away → gentle redirect, hint, or auto-pause; never a fail state.
3. parent-only — the child reaches something parent-only → the parent gate holds; the child is never stuck.
4. learning invariant — a rule of the learning loop holds (e.g. "a word answered wrong comes back in the same session").
5. cross-system — the outcome depends on another system's state (save, progress, unlocks) → that rule holds.

Format:

### AC-NN (US-XX) — <coverage type>
**Given** <state: who, where in the game, what they have unlocked>
**When** <what the child or parent does>
**Then** <what they see and hear / what the game remembers>

FORBIDDEN in AC text (critic F6 + regex): GDScript identifiers and calls (`func`, `signal`, `snake_case()`),
node paths (`$Node/Child`, `res://`, `user://`), autoload names, file names and extensions (.tscn, .gd, .tres, .json),
numeric frame/physics constants. Those belong to design and contracts. Timings the child experiences
("after about 8 seconds") are allowed. -->

### AC-01 (US-01) — happy

**Given** the child is in the bakery with three picture cards on screen
**When** he taps the card the voice asked for
**Then** the card bounces, he hears the word again and a soft success sound, and a star fills in

### AC-02 (US-01) — toddler-error

**Given** the bakery asks for "bread"
**When** he taps a different card
**Then** that card wiggles and says its own name, the voice asks for "bread" again, and nothing is lost

## 6. Non-functional requirements

<!-- instruction: the standing rules below apply to every feature; keep them and add feature-specific rows.
Targets are numeric where possible. -->

| Aspect | Target | Measurement |
|---|---|---|
| Frame rate | ≥30 fps on the Intel MacBook (8 GB, integrated GPU) | perf check at the gate |
| Load time | scene/chapter loads in ≤10 s on the Intel MacBook | timed at the gate |
| Input | works with mouse/trackpad, touch, and the gamepad (USB, 2.4G, Bluetooth) | controls check at the gate |
| Reading | zero reading needed by the child; every instruction is voiced | review + playtest |
| Fail states | none; every wrong path leads back to progress | review + scripted playthrough |
| Offline | no network access of any kind | review (no HTTPRequest/WebSocket nodes) |
| Session | respects the session timer (15 min default) and auto-pause on idle | scripted playthrough |
| <feature-specific> | <…> | <…> |

## 6.1 Safety and privacy

<!-- instruction:
- What the child can reach: nothing outside the game (no links, purchases, OS dialogs, network) — confirm, or list the exception.
- Parent-only areas touched: none / list, and how the parent gate protects them.
- Personal data: none / the child's name, voice recordings, photos — where they are stored (local only, never in git if private).
- Content check: anything that could startle or upset a 3-year-old (sounds, motion, characters).
- Safety review: Required (anything above is touched) or N/A with a reason. -->

- **Reachable outside the game:** <none>
- **Parent-only areas:** <…>
- **Personal data:** <…>
- **Content check:** <…>
- **Safety review:** <Required / N/A — reason>

## 7. Success signals

<!-- instruction: ≥2 signals, each how we observe it and when. For a toddler game these are playtest and
learning observations, not analytics. -->

- **<signal, e.g. "finishes the activity without help">** — observed in: <playtest at Gate N>.
- **<signal, e.g. "recognizes 3 of 5 food words after a few days">** — observed in: <learning check>.

## 8. Open questions

<!-- instruction: 0–4 open questions. Format: `- [ ] <question>? Default now: <X>. — owner: <name/role>, due: <date or stage, e.g. "before /tasks">`. -->

- [ ] <question>? Default now: <...>. — owner: <name/role>, due: <date or stage>
