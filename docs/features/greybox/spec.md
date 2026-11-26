---
status: building
feature_size: L
route: quick
updated_at: "2026-11-26"
---

# Spec (lite) — Greybox prototype (Phase 1)

> Roadmap steps 2–7 and 30. Proves that walking, driving and the password door are fun for a
> three-year-old before any art. Mouse and keyboard are the primary input for now (no gamepad
> yet; D8 in the roadmap). Voices are the operating system's text-to-speech.

## 5. Acceptance criteria

- **AC-01 Walk.** Given the village, when he clicks the ground the hero walks there around
  obstacles; holding the button makes the hero follow the cursor; arrow keys walk directly.
- **AC-02 Drive.** Given the hero near the car, when he clicks the car (from anywhere: the hero
  walks over first) or presses Space, he gets in and the camera blends higher and wider. Arrow
  keys point the way to drive; a click on the ground drives there. Bumping bounces softly with a
  funny sound. Clicking the car while driving honks (H too); Space gets out.
- **AC-03 Guidance.** A glowing marker shows the next spot (car → a drive spot → the door).
  Тигриця follows and points at it. After ~15 s without getting closer she gives a voiced hint
  and the marker brightens; after +10 s she runs to the marker.
- **AC-04 Speaking objects.** Clicking a tree, flower, sunflower, ball, duck, dog or house says
  its name in Ukrainian then English and shows the written word briefly.
- **AC-05 Password door.** Walking up to the door, Тигриця asks how to say a word in English;
  three blank cards rise and each says its word when pointed at or clicked (left/right + Space
  on the keyboard). A wrong pick wiggles, says its word and repeats the question, never a sad
  sound. After 2 wrong picks the right card glows and the door opens with praise. The loop
  restarts with a new word.
- **AC-06 Event log.** Every click, idle pause (≥5 s), hint, card pick, car enter/exit, bump and
  step is written with a timestamp to `user://logs/<session>.jsonl`.
- **AC-07 Pause.** Esc or P pauses with a dim screen and a big play button; any click resumes.

- **AC-08 Learning moments (education first).** Passing the bridge, the river, the road or the
  fence (walking or driving), clicking any object, or getting into the car for the first time
  opens a card: a live picture of that thing, the English word large and the Ukrainian word
  under it, spoken («Це міст!», "bridge", "bridge"), then two short English sentences, each
  shown while spoken. The game waits behind it; one tap or Space skips. Passing moments open
  at most every 20 s, each word at most twice a session; clicked moments always open.
- **AC-09 Car drives smoothly.** The car accelerates to full speed in about a second and only
  bounces when it hits something upright (a house, the fence, the river bank), never the ground.

## 8. Open questions

- Is touch easier than the mouse for him? Tried at the Gate 1 playtest (roadmap D5).
