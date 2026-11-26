# Tygrytsa's Journey — Game Spec

Nov 25, 2026 · roderg

> Exported to Markdown on 2026-11-26 from the living doc at https://claude.ai/artifact/HKNpJHQyNn3yvNrKqA2qQP. The doc is the place to discuss and edit; refresh this copy when it changes.

## Overview

A 3D story game where a 3-year-old Ukrainian speaker drives and walks through small towns abroad. He helps local friends and learns English, Spanish and French words along the way. The narration is in Ukrainian, and characters speak the target words in their own language.

| Decision | Choice |
| --- | --- |
| Player | Our son, age 3, native Ukrainian, can't read yet |
| Languages | English, Spanish, French (one country per story arc) |
| Engine | Godot 4.7.x (upgrade to 4.8 when stable), GDScript |
| Renderer | Compatibility (OpenGL), for weak hardware |
| Platforms | macOS (universal build) + Windows desktop; Steam is an option later |
| Dev machine | MacBook M4, 24 GB |
| Minimum play machine | Intel MacBook, integrated graphics, 8 GB RAM |
| Distribution | Family only for now; keep every asset license clean |
| Unity | Rejected: Unity AI needs a subscription, is still in beta, and the editor is heavy |

## Story

The game follows a journey: it starts at home in Ukraine and goes abroad, one country per arc. Each local problem he solves teaches a set of words.

**Prologue: Ukraine (tutorial).** In a cozy Ukrainian village (sunflowers, a river, a hata with a garden) he meets Tygrytsa, picks one of three cars, and learns to walk, drive and click things. A friendly English postman brings the invitation to the English town's festival and teaches his first two words: "hello" and "bye". He drives onto a ferry, and a cutscene carries them to England.

**England arc: The Festival.** The whole town is preparing a festival, but things keep going wrong.

1. **The baker lost the cake ingredients.** He collects flour, eggs, milk and apples around town. Food words and counting.
2. **The toy maker's balloons flew away.** He finds balloons of each color around the park and harbor. Colors.
3. **The farm animals escaped.** He finds the cow, sheep, duck and pig, who make their sounds and say their names. Animals.
4. **The clock tower stopped.** He finds the gears and numbers so the festival can start on time. Numbers 1–10.
5. **Finale.** The festival happens, and every friend he helped is there.

**Later arcs.** Spain, then France, each reached by train or ferry with his own car. New local friends, and words from earlier countries come back for review.

**Tone:** always gentle. Problems are puzzles, never anything scary. Cutscenes are short in-engine 3D scenes.

## Gameplay

Each town is a small open world he explores freely on foot or by car. All controls are built for a toddler with a mouse.

| Area | Decision |
| --- | --- |
| Movement | Walk around town, and get into his car for longer trips |
| Controls | Keyboard + mouse or gamepad, switchable at any moment. Mouse: click to go there, or hold the button and the hero follows the cursor. Keyboard: arrow keys. Gamepad: stick to move and drive, one big button to act. Every task can be done with either |
| Camera | High three-quarter view that follows him, so he can see what's around |
| Bumping | The car bounces softly with a funny sound. Nothing breaks and nobody gets hurt |
| Session length | About 15 minutes per chapter |
| England town | Bakery + café, toy shop + park with playground, farm / petting zoo at the edge of town, harbor, clock tower, bus stop |
| Buildings | Many can be entered, each locked with a password door (see Learning design) |
| Town life | People and animals walk around, slow traffic always stops for him, day/night cycle and weather |
| Guidance | Tygrytsa says where to go, and a glowing marker shows the spot. He can wander first |
| Customizing | Car color from a paint shop, hero outfit and hat, car stickers, horn sound |
| Rewards | A map that unlocks, a souvenir collection (each one replays its word), a gallery of the friends he helped |
| Travel between countries | He drives his car onto a ferry or train, and a cutscene plays |

- **Gamepad:** tested with an Xbox-layout controller (Machenike G5 Pro, ABXY). Xbox-style button prompts by default, with a setting to swap the layout for Nintendo-style buttons. Gentle vibration on bumps and successes where the controller supports it. Test Bluetooth on macOS early.
- **Idle help:** after about 15 seconds without progress, Tygrytsa gives a hint and points the way, and the marker gets brighter.
- **Saving:** constant autosave of every word, door and item, so the game can be closed at any moment.

## Learning design

**Education first** (decided after the first greybox playtest, 2026-11-26): the main idea is not play but learning something new, and every situation is used for it. Passing a landmark (a bridge, the river, the road), clicking anything, or getting into the car opens a short **learning moment**: a picture of the real thing, the word in Ukrainian and English, and the English word used in two short sentences from different situations ("The car goes over the bridge." / "The duck swims under the bridge."). Moments are voiced in English only, skippable with one tap, and paced so play still flows.

**English immersion** (decided after the second greybox playtest, 2026-11-26): all speech is English, Tygrytsa's too ("Here is our car!", "This is a bridge.", "Look! This card is glowing!"). He sees what things are, so nothing is translated, with one exception: the introduction and the **first time** he meets any line or thing (the first click on the river, the first card, the first door question) are said in Ukrainian first, then English. From the second time on it is English only. First meetings are kept in the save. Phrases are short and repeated often. This replaces the earlier Ukrainian-narration approach below. **Teach before test:** a password door or quiz only asks words he has already met in a learning moment; if none fits, the moment teaches the word first and the door asks right after.

Everything works without reading or speaking. He learns by listening and clicking, in Ukrainian first and then the target language.

- **Language approach:** Tygrytsa and the narrator speak Ukrainian. Local characters say the new words in English, Spanish or French.
- **Task types:** hear a word and pick the right picture from 2–3; find and click an object in the scene; press a button to say a word back (praise only, no speech check).
- **Free exploration:** clicking anything says its name in Ukrainian, then in the local language. Collectibles are hidden around town, each with a word. The car teaches words too: stop, go, fast, slow, left, right, and the horn, lights and radio.
- **Mistakes:** a gentle "try again" that repeats the word. No penalty and no sad sounds.
- **Vocabulary:** animals and nature, colors, numbers 1–10, and food first, then body, clothes, feelings and greetings.

* **Pace:** 5–6 new foreign words per chapter, each repeated many times.
* **Review:** smart repetition. Words he struggles with come back more often in later tasks and doors.
* **Word labels:** when a word is spoken, its written form appears briefly on the object, for early exposure to letters. No other text in the child's view.

### Password doors

The door's word is always one he has already been taught (see Learning design). In the greybox the door shows a picture of the thing and Tygrytsa asks "What is this?" in English; the retry names the word ("Where is the car?").

Buildings are locked. When he walks up to a door, Tygrytsa asks in Ukrainian, for example, how to say "lion" in English. Three blank cards appear, and each one says its word aloud when he points at it or clicks it ("dog", "ox", "lion"). He picks the right card and the door opens.

- **Password types:** say a word, counting ("one, two, three"), name the picture on the door, polite phrases to the shopkeeper (hello, please, thank you).
- **Fallback:** after 2 wrong picks the right card glows and the door opens with praise. He never gets stuck.
- **Speech recognition:** optional, for later. If added, it's lenient and keeps the same fallback.

## Characters, art and audio

The look is stylized low-poly 3D with an original style inspired by the feeling of Miyazaki's films: painted skies with big clouds, soft warm light, lush countryside with wind in the grass, and cozy, detailed houses. No characters or art are copied. It uses toon shading with soft colored shadows, hand-painted gradient textures and warm color grading per time of day, kept light enough for 30 fps on the Intel MacBook.

| Element | Decision |
| --- | --- |
| Hero | Our son, called by name (set in settings). A low-poly model based on a photo or drawing we provide |
| Companion | Tygrytsa, an original Ukrainian tigress in a vyshyvanka. A brave adventurer, excited about everything, with "Let's go!" energy. Not based on any existing film character |
| Car | He picks one of three in the prologue: a round little hatchback, a small jeep, or a tiny van. All toy-like and custom-made |
| Town models | CC0 low-poly packs (Kenney / Quaternius style), safe for any use |
| Voices | AI-generated audio files from free, open-source text-to-speech models run locally on the M4 (no paid services): Ukrainian narration plus native-sounding English, Spanish and French words. Generated with a script and bundled with the game |
| Music | Calm and cheerful, with a hint of each country's folk style |
| Sound | Soft and friendly: funny bounces, a horn, animal sounds, praise jingles |

## Parent features and profiles

Parent features sit behind a parent lock (for example, holding a key combination), so a toddler can't open them by accident.

- **Settings:** child's name, active languages, volume.
- **Progress view:** which words he has heard and recognized, and which ones he struggles with.
- **Gentle session end:** after a chosen time, Tygrytsa yawns, says goodbye, and the game pauses.
- **Chapter select:** replay any unlocked chapter.
- **Profiles:** one player profile now. The save format supports adding more profiles later.

## Production pipeline and tools

The whole build uses free tools only, following the stages professional studios use: plan, block out, make art, add audio, test with our son, ship.

| Stage | Free tool | Use in this game |
| --- | --- | --- |
| Design and planning | This spec, Excalidraw or draw.io, Forgejo/GitHub issues | Town maps, chapter flows, task tracking |
| Prototyping (greyboxing) | Godot CSG shapes, Blender | Block out the town in plain shapes and prove driving is fun before any art |
| 3D modeling and animation | Blender + Rigify add-on | Hero, Tygrytsa, the three cars, buildings |
| Ready-made models | Kenney, Quaternius, KayKit, Poly Pizza (CC0 only) | Trees, houses, props, animals |
| Humanoid animation | Mixamo (free with an Adobe account) | Walk, run, wave, jump for the hero and townspeople |
| Textures and 2D art | Krita, Material Maker | Hand-painted gradient textures and painted skies; CC0 models repainted to match the art direction |
| Story, dialogue, cutscenes | Dialogic 2, Phantom Camera (Godot plugins) | Tygrytsa's lines, story beats, cinematic camera |
| Townspeople and animals | Beehave (Godot plugin) | Behavior trees for strolling, greeting, reacting |
| Word database and translations | Godot translation system + Poedit, or CSV | Each word with its picture, audio and translations |
| Voices | Piper (Ukrainian), Kokoro (EN/ES/FR) | Generated locally on the M4 |
| Sound effects | Audacity, jsfxr / ChipTone, Freesound (CC0) | Bounces, horn, praise sounds |
| Music | LMMS, Bosca Ceoil, MuseScore | Cheerful tunes with local flavor |
| Fonts | Google Fonts (OFL) with Cyrillic, e.g. Nunito | Word labels, parent menu |
| Version control | Git + Git LFS, self-hosted Forgejo | Code plus large model and audio files |
| Tests and builds | GUT or gdUnit4, Godot headless export, Forgejo/GitHub Actions | Automated tests, Mac and Windows builds |
| Playtesting | OBS Studio | Record screen and face while he plays, to spot confusion |
| Steam (later) | GodotSteam | Steam features if we publish |
| Speech recognition (later) | whisper.cpp or Vosk | Offline, optional |

**Studio practices we follow:**

- Test with our son early and often. Record sessions and watch where he hesitates.
- Audio carries every instruction, with a visual hint. No text instructions.
- No failure states. A wrong answer leads to a hint.
- One main action: "go" plus "use".
- Prototype in grey boxes first, then add art.

**Costs only if we go public:** Valve's one-time Steam Direct fee per game, and a paid Apple developer account to sign the Mac app. Neither is needed for family use. An unsigned app opens with right-click, then Open.

## First build and open items

The first build is the Ukraine prologue plus chapter 1 (the bakery), playable start to finish. We test it with our son, adjust, then build chapters 2–4 and the finale.

**Workflow:** Claude writes the code and scenes. We run the builds on the M4 and test them on the Intel MacBook.

**Needed from us:**

- [ ] A photo or drawing for the hero
- [ ] Run the local voice-generation script on the M4 (free, open-source TTS). Placeholder voices are used until then
- [ ] A CC0 model pack, attached, if Claude's workspace can't download it

**Open questions:**

- [ ] The child's name and how it should be pronounced, for the narrator audio
- [ ] The names of the local friends in England (the baker, toy maker, farmer, clockmaker)
- [ ] The parent-lock method
