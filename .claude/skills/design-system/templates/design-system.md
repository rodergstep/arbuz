---
updated_at: "<YYYY-MM-DD>"
theme: "ui/theme/main_theme.tres"
components_dir: "ui/components/"
status: draft              # draft | confirmed-at-gate-1 | …
---

# Design system — Tygrytsa's Journey

> The toddler UI canon. Values marked *(start)* are starting points to confirm at the Gate 1
> playtest. Components may be added only with a written justification and the parent's OK.

## Principles

1. **No reading.** Every instruction is voiced; icons, motion and voice carry meaning. Text only on parent screens.
2. **No fail states.** A wrong pick gets a gentle redirect and a hint; nothing is lost.
3. **Big and forgiving.** Large targets, generous spacing, hit areas larger than the art.
4. **Answer every touch.** Every tap or press produces sound and motion within ~100 ms *(start)*.
5. **Calm.** Soft sounds, slow motion, no flashing, no sudden loud stingers.
6. **Colour never alone.** Meaning-carrying colours always come with a shape or pattern.
7. **Same input, same result** across mouse, touch and gamepad.

## Art direction (summary)

Original, soft, hand-painted look inspired by Miyazaki films: painted skies, warm light, wind in the
grass, cozy houses. Toon shading with coloured shadows, hand-painted gradient textures, warm
grading per time of day. Budget: ≥30 fps on the Intel MacBook. Judged at Gate 3.

## Tokens

### Colour

| Token | Hex *(start)* | Use | Paired shape/pattern when it carries meaning |
|---|---|---|---|
| `bg.sky` | `#CFE6F2` | backgrounds | — |
| `bg.paper` | `#FFF6E5` | card faces, panels | — |
| `ink` | `#3B3A36` | outlines, parent-screen text | — |
| `accent.sun` | `#F4B942` | highlights, stars | star shape |
| `accent.leaf` | `#6BAA75` | "yes / go" | circle + check |
| `accent.berry` | `#C8576B` | parent-only areas | lock shape |
| `focus.ring` | `#FFFFFF` + `#3B3A36` outline | gamepad focus | thick double ring |

### Typography (parent screens and decorative only)

| Token | Value *(start)* | Notes |
|---|---|---|
| `font.main` | a rounded OFL font with Cyrillic + Latin (e.g. Nunito) | confirm licence |
| `size.parent.body` | 28 px at 1280×720 | parent screens |
| `size.title` | 48 px | decorative titles |

### Size and spacing (at 1280×720 reference resolution)

| Token | Value *(start)* | Rule |
|---|---|---|
| `target.min` | 128 × 128 px | smallest thing the child taps |
| `target.hit_extra` | +24 px each side | hit area beyond the art |
| `gap.min` | 48 px | between two child targets |
| `edge.safe` | 64 px | no child target closer to the screen edge |
| `choices.max` | 3 *(start)* | choices on screen at once for a 3-year-old |

### Motion

| Token | Value *(start)* | Use |
|---|---|---|
| `motion.tap` | 120 ms squash + bounce | every tap |
| `motion.success` | 600 ms bounce + sparkle | correct pick |
| `motion.wrong` | 300 ms gentle wiggle | wrong pick, never red flash |
| `motion.transition` | 500 ms fade | scene/screen change |

## Audio rules

- Every instruction has a voice line id (from the word DB or the dialogue list); no silent instruction.
- Every tap: a soft tap sound. Correct: `sfx.success_soft` + the word spoken. Wrong: the tapped item says its own name, then the instruction repeats.
- Volume ceiling for SFX below voice; no sound louder than the voice track.
- Voice in the session language (Ukrainian narration, English target words in the England arc).

## Hint ladder

| Level | After *(start)* | What happens |
|---|---|---|
| 0 | — | instruction voiced on entry |
| 1 | ~15 s without progress (game spec) | Tygrytsa gives a voiced hint and points the way; the marker gets brighter |
| 2 | +10 s | the target glows softly |
| 3 | +10 s | `HintHand` points at the target |
| auto-help | +10 s | the game does it with him, with praise |

Choices (password doors, pick-the-picture): after 2 wrong picks the right card glows and the
door opens with praise (game spec). He never gets stuck.

Any input resets the ladder. Mashing (≥5 taps in 2 s on non-targets) *(start)* plays a calm
"let's look together" line and shows level 2.

## Input rules

| Input | Rule |
|---|---|
| Mouse / trackpad | click-to-go and hold-to-follow; no double-click, no drag-only actions |
| Touch | tap anywhere on the hit area; no multi-finger gestures |
| Gamepad | D-pad/stick moves focus between targets (big focus ring), A confirms; B never quits a scene |
| All | no long-press needed by the child; parent gate uses an input a 3-year-old is unlikely to do |

## Components

<!-- status: built (scene exists) | planned (approved, not built) — a row without approval is not allowed. -->

| Component | Purpose | States | Heard | Scene | Status |
|---|---|---|---|---|---|
| `BigButton` | the child's primary action | idle, focus, pressed, disabled-hidden | tap sound + optional voice | `ui/components/big_button.tscn` | planned |
| `PictureCard` | a choice (word, object) | idle, focus, pressed, success, wrong | its word on tap | `ui/components/picture_card.tscn` | planned |
| `ChoiceRow` | lays out 2–3 cards with safe spacing | 2/3 items | — | `ui/components/choice_row.tscn` | planned |
| `HintHand` | hint level 3 pointer | hidden, pointing, tapping | — | `ui/components/hint_hand.tscn` | planned |
| `DialogueBubble` | character speech (Dialogic) | showing, done | the line | via Dialogic theme | planned |
| `ProgressStars` | progress without numbers | 0..N filled | soft chime on fill | `ui/components/progress_stars.tscn` | planned |
| `ParentGate` | blocks parent-only areas | locked, challenge, open | none for the child | `ui/components/parent_gate.tscn` | planned |
| `SessionTimerOverlay` | soft end of session | hidden, winding-down, goodbye | goodbye line | `ui/components/session_timer_overlay.tscn` | planned |

## Screens

| Screen | Who | Notes |
|---|---|---|
| Title | child | one big Play button, voiced |
| Profile pick | child (+ parent) | pictures, not names |
| World map | child | places unlock visually |
| In-scene HUD | child | stars, hint hand; no text |
| Parent settings | parent | behind `ParentGate`; text allowed |

## Approvals log

| Date | Component | Requested by | Why nothing existing fit | Decision |
|---|---|---|---|---|

## Theme sync

<!-- pending token changes for ui/theme/main_theme.tres, implemented by an implement task -->
