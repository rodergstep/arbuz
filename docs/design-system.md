---
updated_at: "2026-11-26"
theme: "game/ui/theme/main_theme.tres"
components_dir: "game/ui/components/"
status: draft              # draft | confirmed-at-gate-1 | …
---

# Design system — Тигриця's Journey

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

How the look is made cheaply (Compatibility renderer, see `docs/architecture-map.md` §Performance budget):

| Element | Technique | Cost rule |
|---|---|---|
| Characters and props | one shared toon `ShaderMaterial`: 2–3 light bands, shadow tinted cool blue-violet (`shade.cool`), soft rim light | one material family; per-object colour comes from a gradient texture, not a new shader |
| Textures | hand-painted gradient atlases (256–512 px), shared across models | no unique 2K textures on props |
| Sky | painted panorama + 2–3 scrolling cloud layers in a sky shader | no volumetrics |
| Grass and flowers | `MultiMeshInstance3D` with a vertex-shader wind sway | low density, fades out with distance |
| Light | one directional light, short shadow distance; warm grading via `Environment` adjustments per time-of-day preset | no SSAO/SSR/SDFGI; glow off or minimal |
| UI | flat painted shapes, soft drop shadow baked into the texture | no blur shaders |

Time-of-day presets (*start*): golden morning `#F6D7A7` key / `#8FA3C9` shade; bright midday `#FFF3D6` / `#9DB4D6`; amber evening `#F2A65A` / `#7E7BB0`; soft blue night `#AFC3E8` / `#4B5A8C`.

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
| `accent.sky` | `#4F8FC7` | "this way" markers, path | arrow / chevron |
| `shade.cool` | `#7C86B8` | toon shadow tint | — |
| `focus.ring` | `#FFFFFF` + `#3B3A36` outline | gamepad focus | thick double ring |

Meaning never rests on telling `accent.leaf` from `accent.berry` (the red–green pair most affected by colour-vision deficiency): "yes / go" is always a circle + check and a rising chime; parent-only is always the lock shape. The colours chapter teaches colours on objects that also differ in shape.

### Typography (parent screens and decorative only)

| Token | Value *(start)* | Notes |
|---|---|---|
| `font.main` | Nunito (SIL OFL 1.1), Cyrillic + Latin | bundled under `assets/fonts/` with its licence file |
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
| 1 | ~15 s without progress (game spec) | Тигриця gives a voiced hint and points the way; the marker gets brighter |
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
| `BigButton` | the child's primary action | idle, focus, pressed, disabled-hidden | tap sound + optional voice | `game/ui/components/big_button.tscn` | planned |
| `PictureCard` | a choice (word, object) | idle, focus, pressed, success, wrong | its word on tap | `game/ui/components/picture_card.tscn` | planned |
| `ChoiceRow` | lays out 2–3 cards with safe spacing | 2/3 items | — | `game/ui/components/choice_row.tscn` | planned |
| `HintHand` | hint level 3 pointer | hidden, pointing, tapping | — | `game/ui/components/hint_hand.tscn` | planned |
| `DialogueBubble` | character speech (Dialogic) | showing, done | the line | via Dialogic theme | planned |
| `ProgressStars` | progress without numbers | 0..N filled | soft chime on fill | `game/ui/components/progress_stars.tscn` | planned |
| `ParentGate` | blocks parent-only areas | locked, challenge, open | none for the child | `game/ui/components/parent_gate.tscn` | planned |
| `SessionTimerOverlay` | soft end of session | hidden, winding-down, goodbye | goodbye line | `game/ui/components/session_timer_overlay.tscn` | planned |

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
| 2026-11-26 | `BigButton`, `PictureCard`, `ChoiceRow`, `HintHand`, `DialogueBubble`, `ProgressStars`, `ParentGate`, `SessionTimerOverlay` | `/design-system` setup | starter inventory; the canon was empty, and each maps to a feature the game spec names (title, password doors, hint ladder, Dialogic dialogue, parent lock, gentle session end) | approved as `planned` under roderg's standing approval for setup work |

## Theme sync

<!-- pending token changes for game/ui/theme/main_theme.tres, implemented by an implement task -->

The Theme does not exist yet. The first UI feature (Phase 1) creates `game/ui/theme/main_theme.tres` with every token above, sets it as the project's default theme (`gui/theme/custom`), and a GUT test loads it and checks the token values. Until then, nothing in `game/ui/` hard-codes a colour, font or size.
