# Tygrytsa's Journey — Development Plan

Nov 25, 2026 · roderg

> Exported to Markdown on 2026-11-26 from the living doc at https://claude.ai/artifact/T1jCJU2rnErz2JChm7d1Ze. The doc is the place to discuss and edit; refresh this copy when it changes. Some suggestions in the doc are still pending review, so open decisions below are not final. The roadmap and architecture diagrams are embedded in the doc and not reproduced here.

## Summary

> **Education first** (2026-11-26, after the first greybox playtest): every phase now includes learning moments. Whenever he passes or clicks something, the game shows its picture, says the word in Ukrainian and English, and uses it in short English sentences. Each new place or object comes with its word-database rows and example sentences.

We build the game in seven phases. Each phase ends with a gate: something playable that our son or we test before the next phase starts. The first gate is a greybox prototype that proves driving, walking and the password door are fun before any real art is made. The last gate is the complete England arc, built for Mac and Windows.

- **What we build:** the game described in [game-spec.md](game-spec.md). Godot 4.7, GDScript, Compatibility renderer, free tools only.
- **How we build it:** Claude writes the code, scenes and scripts in the `arbuz` folder on the M4. We run every build there and test on the Intel MacBook.
- **Sizing:** each phase is sized in work sessions, not calendar dates. A session is one sitting of Claude building plus our test run. Dates depend on how often we play-test.
- **How to review:** check the phase order, the gate criteria and the decisions in the last section. Comment on anything to change.

## Art direction

An original look inspired by the feeling of Hayao Miyazaki's films: painted skies with big clouds, soft warm light, lush countryside, wind moving through the grass, and cozy, detailed houses. Nothing is copied: no characters, designs, scenes or artwork from any film.

- **Shading:** toon shading with soft, colored shadows (warm light, cool blue-violet shade) instead of black ones, and a gentle rim light on characters.
- **Textures:** hand-painted gradient textures in place of flat colors. The CC0 packs are repainted to match, so every model shares one painted look.
- **Sky and nature:** painted skies with large layered clouds that drift slowly, plus grass, sunflowers and trees that sway in the wind (a vertex shader on instanced grass, density kept low).
- **Light and color:** warm color grading for each time of day (golden morning, bright midday, amber evening, soft blue night), set per lighting preset.
- **Houses and props:** cozy and lived-in, with small details such as flower boxes, laundry lines and chimneys, while things he can click stay clearly readable.
- **Performance:** all of this has to hold 30 fps on the Intel MacBook with the Compatibility renderer, so effects are shader-based and cheap, with no heavy post-processing.
- **When it's tested:** the look is built and judged in Phase 3 on the prologue village, and it becomes the reference for every later scene.

## Roadmap

*(Roadmap diagram: 7 phases, 7 gates. See the doc.)*

Each phase starts only after the previous gate passes. Spain, France and Steam come after Gate 6.

## Phase 0 — Setup (about 1 session)

The goal is an empty, correctly configured Godot project that opens on the M4 and exports a build that runs on the Intel MacBook.

- [ ] Install on the M4: Godot 4.7.x (standard build, not .NET), Git + Git LFS, Blender, OBS Studio
- [ ] Initialize the repo in `arbuz`: `.gitignore`, `.gitattributes` with LFS rules (glb, png, ogg, wav, blend)
- [ ] Project settings: Compatibility renderer, 1280×720 base window that scales, 60 fps target with 30 fps minimum
- [ ] Input map: mouse, keyboard and gamepad actions (`move`, `use`, `horn`, `pause`) defined once
- [ ] Install free plugins: Dialogic 2, Phantom Camera, Beehave, GUT
- [ ] Copy the spec and this plan into `docs/`
- [ ] Gamepad check scene: shows every button and stick press, and tests rumble. Run it with the Machenike G5 Pro over USB, the 2.4G dongle and Bluetooth on macOS
- [ ] Export presets: macOS universal and Windows x86\_64

**Gate 0:** a test build opens on the Intel MacBook, and the gamepad check scene registers every button.

## Phase 1 — Greybox prototype (about 3–4 sessions)

The goal is to prove the core feel with plain shapes and placeholder voices, before any art.

- [ ] Village blocked out with simple shapes: road loop, a few houses, river, one building with a door
- [ ] Hero (a capsule): click to walk with pathfinding, hold-to-follow cursor, arrow keys, gamepad stick
- [ ] Car (a box): get in and out, arcade driving that's forgiving, soft funny bounce on collision, horn
- [ ] High three-quarter follow camera with Phantom Camera; it switches smoothly between walking and driving
- [ ] Tygrytsa placeholder that follows the hero and points the way
- [ ] Glowing marker plus an idle nudge after about 15 seconds
- [ ] One password door with three cards that speak when he points at or clicks them, and the fallback after 2 wrong picks
- [ ] Clickable objects that say their name, with the written word appearing briefly
- [ ] Placeholder voices from the operating system's built-in text-to-speech, which Godot can call directly
- [x] Learning moments (education first): passing the bridge, river, road or fence, clicking an object, or getting into the car opens a card with a live picture, the word in Ukrainian and English, and two English example sentences; skippable, paced
- [ ] Playtest event log: every click, idle pause and card pick written with a timestamp, to review next to the OBS recording
- [ ] Fail-free feedback: a wrong pick never plays a failure sound or loses progress; Tygrytsa cheerfully shows the right answer and he tries again

**Gate 1:** our son plays about 10 minutes, recorded with OBS. He can drive to the marker and open the door with little or no help. We list what confused him and tune controls, camera and speeds. We also try a touchscreen (tablet or touch laptop), since touch is usually the easiest input at age 3, and decide the primary input here.

## Phase 2 — Core systems and content pipeline (about 4–6 sessions)

The goal is for the systems every chapter relies on to be data-driven and tested, so new content is mostly data and art.

- [ ] **Word database:** each word has an id, Ukrainian, English, Spanish and French text, a picture or model, audio files and a topic
- [ ] **Voice generation script:** runs locally on the M4. Piper produces the Ukrainian lines and Kokoro the English, Spanish and French words. Output is `.ogg` files named by line id, regenerated whenever the word list changes
- [ ] **Audio manager:** plays voice lines by id, ducks the music under speech, queues lines without overlap
- [ ] **Learning tracker:** records every time a word is heard and every right or wrong pick, and decides which struggling words come back (smart repetition, box-based like flashcards)
- [ ] **Quest and chapter system:** chapters, tasks and door passwords are described as data files, not code
- [ ] **Dialogue:** Tygrytsa's and the townspeople's lines in Dialogic 2, each tied to a voice file
- [ ] **Interaction system:** clickable objects, the three-card door, pick-the-picture, find-the-object, the say-it-back button
- [ ] **Input and prompts:** automatic switching between mouse/keyboard and gamepad, Xbox or Nintendo button prompts, gentle rumble
- [ ] **Saving:** constant autosave to a JSON file per profile, versioned so a future update can migrate old saves
- [ ] **Parent area:** parent lock, settings (name, languages, volume), session timer with the gentle goodbye (15 minutes by default, changeable by the parent, with Tygrytsa warning two minutes before the goodbye)
- [ ] **Pacing rules:** every task fits in 3–5 minutes, sessions end on a win, and new words are introduced 3–5 at a time, matching a 3-year-old's attention span

**Gate 2:** every system has automated tests that pass. The greybox runs on the new systems, and the prologue's voice lines are generated by the script.

## Phase 3 — Prologue vertical slice (about 6–8 sessions)

The goal is the Ukrainian prologue finished with real art, sound and story. It sets the look and the performance budget for everything after it.

- [ ] **Art setup:** the toon shader with soft colored shadows, hand-painted gradient textures, CC0 packs imported and repainted to match, a painted sky with drifting clouds, wind-swayed grass and trees, and a lighting preset with warm color grading per time of day (see Art direction)
- [ ] **Hero model:** made in Blender from your photo or drawing, with Mixamo animations (walk, run, wave, jump, celebrate)
- [ ] **Tygrytsa model:** an original low-poly tigress in a vyshyvanka, rigged and animated (walk, point, cheer, yawn)
- [ ] **Cars:** three low-poly cars (round hatchback, small jeep, tiny van), and the car choice scene
- [ ] **Cozy village:** sunflowers and grass moving in the wind, the river, a detailed hata with a garden, the road loop, under a big painted sky
- [ ] **Story:** meet Tygrytsa, the driving and walking tutorial, the English postman with "hello" and "bye", then the ferry cutscene in-engine
- [ ] **Audio:** village music, sound effects, all voice lines generated

**Gate 3:** the prologue plays start to finish on the Intel MacBook at 30 fps or more. Our son plays it, recorded. We sign off on the art direction here: the village has the painted, warm look we want, and it still holds 30 fps.

## Phase 4 — Chapter 1: the bakery (about 5–7 sessions)

The goal is the English town base plus the first full chapter, which together form the first real test of the learning loop.

- [ ] English town layout, with all landmarks placed in greybox first: bakery + café, toy shop + park, farm, harbor, clock tower, bus stop
- [ ] Full art for the town center and the bakery interior; the other places stay simple until their chapter
- [ ] The baker character and the chapter story: the cake ingredients are lost
- [ ] 5–6 food words (flour, eggs, milk, apples, cake, bread) with counting tasks
- [ ] Password doors on the bakery and café, using word, counting and polite-phrase passwords
- [ ] Rewards: the map unlocks, the first souvenir, the baker joins the friends gallery
- [ ] Parent progress view: which words he heard, recognized, and struggles with
- [ ] Baseline check before he plays: note which of the chapter's words he already knows, so Gate 4 measures real learning

**Gate 4:** our son finishes chapter 1 on his own over one or two sessions. After a few days, he recognizes at least some of the food words when he hears them.

## Phase 5 — England chapters 2–4 and the finale (about 10–14 sessions)

The goal is the complete England arc, with town life and customization.

- [ ] (parent) Before Chapter 2 (colors), a quick color-vision check with a simple picture test: about 1 in 12 boys has some color-vision deficiency, and the chapter's tasks would need shapes or patterns too
- [x] Chapter 2, the toy maker's balloons: colors, the park and harbor
- [x] Chapter 3, the escaped farm animals: animals and their sounds, the farm
- [x] Chapter 4, the stopped clock tower: numbers 1–10
- [x] Finale: the festival, with every friend he helped
- [x] Town life: walking people and animals, slow traffic that always stops, weather (rain in England, butterflies in Ukraine); day/night left for later
- [x] Customization: paint shop for car colors and hats (stickers and horn sounds left for later)
- [x] Hidden collectibles, the car's word teaching (stop, go, left, right), the friends gallery
- [ ] (parent) A short recorded playtest after each chapter, not only at the end of the arc, so problems surface while the chapter is fresh

**Gate 5:** the whole England arc plays through from the prologue to the festival with no blocking bugs.
*2026-11-27: scripted runs pass for the prologue, Chapters 1–4 and the festival (each chapter run hands over to the next). The real check is the parent playing it with the child.*

## Phase 6 — Polish and release builds (about 3–5 sessions)

- [ ] Performance pass on the Intel MacBook: draw calls, shadows, model detail, load times
- [ ] Bug bash, with replays of recorded sessions
- [ ] Final macOS universal and Windows builds, built by an automated script
- [ ] Install instructions for family computers (for an unsigned app, right-click, then Open)

**Gate 6:** stable builds on both Macs and one Windows PC. Next steps after that: the Spain arc, the France arc, and Steam if we decide to publish.

Session counts are rough estimates for planning, not commitments.

## Architecture

*(Architecture diagram: content, systems, player-facing layers. See the doc.)*

The systems run as Godot autoloads (always-loaded singletons). Every click and card pick goes through the interaction system to the learning tracker, which decides what comes back for review and gets saved constantly.

## Project structure and data

Code, content data and generated audio live in separate folders, so adding a chapter or a language never means touching engine code.

```
arbuz/
  project.godot
  docs/                 spec, this plan, playtest notes
  addons/               dialogic, phantom_camera, beehave, gut
  game/
    core/               autoloads: audio, save, learning tracker, input, settings
    player/             hero, car, camera rigs
    companion/          Tygrytsa behavior and hints
    interaction/        clickable, password door, pick-picture, find-object
    ui/                 parent area, word labels, prompts, map, gallery
    world/
      ukraine_village/  prologue scenes
      england_town/     town, interiors, chapters
  content/
    words/words.csv     the word database
    chapters/           chapter and task data files
    dialogue/           Dialogic timelines
  assets/               models (glb), textures, music, sfx (Git LFS)
  audio_gen/            voice generation script + line lists (Piper, Kokoro)
  audio/voice/          generated .ogg voice files (Git LFS)
  tests/                GUT tests
  tools/                export and build scripts
```

**Word database:** one row per word, and the voice script reads it to generate every audio file.

```csv
id,topic,uk,en,es,fr,model
apple,food,яблуко,apple,manzana,pomme,props/apple.glb
milk,food,молоко,milk,leche,lait,props/milk.glb
lion,animals,лев,lion,león,lion,animals/lion.glb
```

**Save file:** one JSON file per profile in Godot's user data folder, with a `version` field so future updates can migrate it. It holds the profile name, settings, chapter progress, unlocked map places, souvenirs, friends, customization, and per-word learning stats (times heard, right, wrong, repetition box, last seen).

## Testing and playtesting

Three kinds of testing run throughout: automated tests for logic, performance checks on the weakest machine, and recorded sessions with our son for fun and learning.

| Kind | What | When |
| --- | --- | --- |
| Automated (GUT) | Learning tracker, save and load, quest progress, password logic, word database loading | Every session, before handing over a build |
| Performance | 30 fps or more and load under about 10 s on the Intel MacBook (8 GB, integrated graphics) | Every gate from Gate 1 |
| Controls | Mouse, keyboard, Machenike G5 Pro over USB, 2.4G and Bluetooth | Gate 0, then every gate |
| Playtest with our son | 10–15 minutes, recorded with OBS, no coaching unless he asks | Gates 1, 3, 4, 5 |
| Learning check | Does he recognize the words a few days later, in or outside the game? | After Gates 4 and 5 |

**What we watch for in playtests:** where he stops or looks to us for help, wrong clicks on the same thing, whether he wants to keep playing, and which words he repeats on his own. Notes go in `docs/playtests/` and feed the next phase.

## Risks and mitigations

The biggest risk is that free movement is too hard for a 3-year-old. That is why the greybox gate comes before any art.

| Risk | Mitigation |
| --- | --- |
| Steering is too hard for him | Click-to-go and hold-to-follow as the main controls, forgiving car physics, auto-help after idling, decided at Gate 1 |
| Too slow on the Intel MacBook | Compatibility renderer, cheap toon and wind shaders, shared painted textures, low-poly models, low grass density, few real-time shadows, no heavy post-processing, measured at every gate |
| Free voices sound unnatural, especially Ukrainian | Test Piper's Ukrainian voices in Phase 1, using a few prologue lines; a familiar parent voice often works better for toddlers anyway. Fallback: you record the Ukrainian narration yourself |
| Gamepad behaves differently over Bluetooth on macOS | Tested in Phase 0 across all three connection modes; USB as the guaranteed fallback |
| CC0 models don't match each other in style | Repaint them all with the hand-painted gradient textures and the shared toon shader; custom-model the key pieces |
| Scope grows (Spain, France, more features) | Each phase ends at a gate; new ideas go to a backlog until England is done |
| Hero model from a photo looks uncanny | Stylized, toy-like proportions; resemblance through hair, clothes and colors, not the face |
| Godot 4.8 arrives mid-project | Stay on 4.7.x; upgrade between phases only, after the tests pass |

## Who does what, and decisions to confirm

Claude builds; we test, supply personal content, and decide at each gate.

| Who | Responsibilities |
| --- | --- |
| Claude | Code, scenes, data files, tests, the voice-generation script, Blender modeling scripts, build scripts, playtest summaries |
| Us | Install tools, run builds on the M4 and the Intel MacBook, run playtests and recordings, supply the hero reference and personal details, approve each gate |
| Our son | Chief tester |

**Decisions to confirm in this review:**

- [ ] Phase order: greybox first, then systems, then the prologue with real art
- [ ] The first playable target is Gate 1 (greybox), not the finished prologue
- [ ] Performance target: 30 fps or more on the Intel MacBook
- [ ] Fallback if Piper's Ukrainian sounds wrong: record the Ukrainian narration ourselves
- [ ] The `arbuz` folder is the project home and can be initialized as a Git repo
- [ ] Where the Git remote lives: self-hosted Forgejo, GitHub private, or local only for now
- [x] Default session length: 15 minutes, with the parent able to change it
- [x] Co-play is optional: every task works when he plays alone, and the together moments are a bonus when a parent is around

**Still needed from us:** the hero photo or drawing (by Phase 3), our son's name and its pronunciation (by Phase 2), names for the English friends (by Phase 4), and the parent-lock method (by Phase 2).
