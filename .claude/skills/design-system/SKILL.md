---
name: design-system
model: inherit
effort: medium
agents: [explorer, researcher]
description: >
  Use to establish or update the game's toddler UI canon — docs/design-system.md plus the Godot
  Theme resource that holds the tokens: palette (warm, colour-blind-safe pairs that always come
  with a shape), typography, hit-target sizes and spacing, motion timings, audio rules (every
  instruction voiced, every tap answered), the hint ladder, input rules for mouse/touch/gamepad,
  and the component inventory (BigButton, PictureCard, HintHand, ParentGate…). Once per project,
  updated when a component is added. Triggers on "design system", "UI canon", "add a component",
  "toddler UI rules", "/design-system", "дизайн-система", "новий компонент". Any new component
  needs a written justification and the human's OK before it is built.
---

# Skill: design-system

Fixes the **design canon** in `docs/design-system.md` and its code twin, the Godot `Theme`
(`ui/theme/main_theme.tres`) plus component scenes under `ui/components/`. `ux-flows` composes
states from it, `implement` builds with it, `review` checks against it.

The audience is a **3-year-old pre-reader**, playing alone or with a parent, on a Mac with a
mouse/trackpad, a touchscreen, or a gamepad. Everything in the canon serves that: no reading, big
forgiving targets, every instruction spoken, no fail states, calm feedback. The visual direction is
the project's original, soft, hand-painted look inspired by Miyazaki films (painted skies, warm
light, wind in the grass; nothing copied), and it must still hold 30 fps on the Intel MacBook.

Question phrasing → [`../_shared/ask-style.md`](../_shared/ask-style.md). There is one drawing
tool: **code** (Markdown + Mermaid for flows, the Godot Theme and component scenes for the real
thing). Mock-ups, if wanted, are screenshots of the real scene.

## Inputs

- (Optional) an existing `docs/design-system.md` — updated in place, never silently overwritten.
- `docs/architecture-map.md` §UI foundation, the Theme and `ui/components/` if they exist.
- `docs/game-spec.md` (characters, art direction) and the art-direction section of
  `docs/development-plan.md`.
- (Optional) the latest `docs/playtests/` notes — real evidence beats defaults.

## Protocol

1. **Check existing.** If the canon exists, show a summary and ask: update a section / add a
   component / rebuild. Never overwrite silently.
2. **Scan the code side.** Dispatch `explorer` (`subagent_type: "explorer"`) for the Theme files,
   component scenes and any hard-coded colours, fonts or sizes in `ui/` and `scenes/` (each with
   `file:line`). Hard-coded values become cleanup items for a later task.
3. **Fill or update the canon** from [`./templates/design-system.md`](./templates/design-system.md),
   one section at a time, each confirmed with the human and written to disk at once. Defaults in
   the template are **starting values to be confirmed at the Gate 1 playtest**, not facts; when the
   human asks for evidence (target sizes for small hands, attention span, colour-vision
   statistics), dispatch `researcher` for a cited answer.
4. **New component requests** (from `ux-flows`, `implement` or the human). For each: what it is
   for, which states it has, which existing component came closest and why it doesn't fit. The
   human approves or rejects; an approved component gets an inventory row (`status: planned`)
   and `implement` flips it to `built` with its scene path. **No approval → no new component.**
5. **Keep the Theme in sync.** When tokens change, the change list for `ui/theme/main_theme.tres`
   goes into the canon's «Theme sync» section; the actual `.tres` edit is an `implement` task
   (it needs a test that loads the Theme and checks the token values).
6. **Structural self-check** ([`../_shared/self-check.md`](../_shared/self-check.md)), 6 items:
   (1) every colour token has a paired shape/pattern rule for meaning-carrying use; (2) every
   component row has states, a "heard" rule and a status; (3) every `built` row cites its scene
   path, which exists; (4) every `planned` row has an approval note; (5) the hint ladder and audio
   rules are filled; (6) no `<placeholder>` remains. Report `N/6`.
7. **Commit + handoff.** `design-system: design-system.md` (one commit). Utility handoff per
   [`../_shared/handoff.md`](../_shared/handoff.md): resume your stage, usually `/ux-flows <slug>`.

## Anti-patterns

- **Colour alone carries meaning.** About 1 in 12 boys has some colour-vision deficiency; the
  colours chapter must work with shapes and patterns too.
- **Text in the child's path.** Labels are for the parent screens only.
- **A second styling system** (inline `add_theme_color_override` everywhere instead of the Theme).
- **A component built before it is approved**, or approved without saying why nothing existing fit.
- **Overstimulation**: flashing, loud stingers, fast camera moves. Calm, warm, slow.
