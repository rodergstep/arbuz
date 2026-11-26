---
status: building
feature_size: L
route: quick
updated_at: "2026-11-26"
---

# Spec (lite) — Prologue: Ukraine (roadmap step 17)

> The story start in the cozy village, played once; afterwards the village's practice loop.
> Data: `content/chapters/prologue.tres` (built by `tools/build_chapters.gd`), run by QuestRunner.

## 5. Acceptance criteria

- **AC-01 Walk tutorial.** Tygrytsa greets him and says "Click the ground to walk. Walk to the
  light!"; he walks to a glowing marker near the start.
- **AC-02 The postman.** An English postman (blue uniform, red cap, satchel; his own English
  voice) waits by the path. When the hero reaches him he waves and says "Hello! Hello!";
  Tygrytsa: "He says hello! Now you! Say: hello!" and the game waits until he says something
  (microphone, never judged; re-asks gently), then praises. The postman gives "a letter from
  England" (a learning card for *letter*), then says "Bye! Bye bye! See you in England!" and
  waves; the child says bye back the same way.
- **AC-03 To the ferry.** Back in the car, Tygrytsa: "We are going to England! Drive to the
  ferry!"; a marker by the river.
- **AC-04 The ferry.** At the river the car rolls onto a little ferry, which sails up the river
  ("Onto the ferry! Here we go!", a horn, "Bye bye, village! Hello, England!"), then a soft fade.
  No learning card interrupts the cutscene.
- **AC-05 Once.** Finishing the prologue is remembered in the save (`chapter:prologue`); the game
  then continues with the practice loop, and later sessions start there.
- First meetings are Ukrainian then English (CLAUDE.md); everything else English.
