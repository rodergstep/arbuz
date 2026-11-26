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
- **AC-04 Speaking objects.** Clicking a tree, flower, sunflower, ball, duck, dog or house opens
  its learning moment (AC-08); everything spoken there is English.
- **AC-05 Password door (teach before test).** The door only asks a word he has already seen
  on a learning card this session (a different one each visit when possible); if none, it first
  opens the learning card for a village word, then asks that word. A live picture of the thing
  appears over the door and Тигриця asks "What is this? Listen to the cards!" (all English);
  three blank cards rise and each says its word when pointed at or clicked (left/right + Space
  on the keyboard). A wrong pick wiggles, says its word and repeats the question, never a sad
  sound. After 2 wrong picks the right card glows and the door opens with praise. The loop
  restarts with a new word.
- **AC-06 Event log.** Every click, idle pause (≥5 s), hint, card pick, car enter/exit, bump and
  step is written with a timestamp to `user://logs/<session>.jsonl`.
- **AC-07 Pause.** Esc or P pauses with a dim screen and a big play button; any click resumes.

- **AC-08 Learning moments (education first).** Passing the bridge, the river, the road or the
  fence (walking or driving), clicking any object, or getting into the car for the first time
  opens a card in English only: a live picture of that thing and the English word, spoken
  ("This is a bridge.", "bridge", "bridge"), then two short English sentences, each shown while spoken. The game waits behind it; one tap or Space skips. Passing moments open
  at most every 20 s, each word at most twice a session; clicked moments always open.
- **AC-09 Car drives smoothly.** Top speed 7 m/s (30% slower after the second playtest); it
  accelerates to full speed in about a second and only
  bounces when it hits something upright (a house, the fence, the river bank), never the ground.

- **AC-10 English immersion, Ukrainian the first time.** Every spoken line is English
  (instructions, hints, praise, the door, the cards); short phrases, repeated. The intro and the
  first time he meets a line or a word are said in Ukrainian first (the card also shows the
  Ukrainian word that one time); after that, English only. First meetings persist in the save
  (`user://saves/default.json`), so a second session is English only for everything met.

## 8. Open questions

- Is touch easier than the mouse for him? Tried at the Gate 1 playtest (roadmap D5).
