# C4 Mermaid syntax — quick reference for sad.md §3 and §5

design emits C4 Level 1 (Context) in §3 and Level 2 (Container) in §5 as Mermaid blocks inline in `sad.md`. L3 Component and L4 Code are deliberately out of scope — request a separate diagramming pass if you need them. Mermaid renders natively in GitHub and in Obsidian.

## L1 — System Context (`C4Context`)

Use in §3. The system as one black box plus people and external systems. 5–10 elements max.

```mermaid
C4Context
    title <feature> — System Context

    Person(child, "Child", "plays, 3+, pre-reader")
    Person(parent, "Parent", "co-plays, opens settings")

    System(game, "Тигриця's Journey", "<the part this feature adds>")
    System_Ext(fs, "user:// storage", "saves, playtest logs")
    System_Ext(voice, "Voice tool (Piper)", "generates voice files offline")

    Rel(child, game, "Taps, drives, picks", "mouse / touch / gamepad")
    Rel(parent, game, "Changes settings", "behind the parent gate")
    Rel(game, fs, "Reads/writes", "JSON")
    Rel(voice, game, "Provides audio files", "build time")
```

**Element types:**
- `Person(id, "name", "description")` — internal actor.
- `Person_Ext(id, "name", "description")` — external actor.
- `System(id, "name", "description")` — internal system.
- `System_Ext(id, "name", "description")` — external system.
- `SystemDb(id, "name", "description")` — external database (rare at L1).
- `Rel(from, to, "label", "protocol")` — connection; protocol is optional but recommended.

**Rules of thumb:**
- Show *your* system as one box — decomposition lives in L2.
- An external system = different owner / process / lifecycle. Internal modules of the same deployable do **not** appear in L1.
- 5–10 elements total. More than that = you're showing too much.

## L2 — Container (`C4Container`)

Use in §5. The inside of your system: apps, services, datastores, queues. For a single deployable, treat each *module* as a logical container.

```mermaid
C4Container
    title <feature> — Containers

    Person(child, "Child")

    Container_Boundary(game, "Game process") {
        Container(scene, "<ActivityScene>", "Godot scene + GDScript", "<what the child does>")
        Container(ui, "<HUD>", "Control nodes + Theme", "cards, hints, stars")
        Container(is, "InteractionSystem", "autoload", "routes every pick")
        Container(lt, "LearningTracker", "autoload", "per-word stats")
        Container(ss, "SaveSystem", "autoload", "versioned saves")
        ContainerDb(data, "data/", "Resources + word DB", "content")
    }

    ContainerDb(saves, "user://saves", "JSON", "one file per profile")

    Rel(child, scene, "plays")
    Rel(scene, ui, "shows state")
    Rel(ui, is, "report_pick()")
    Rel(is, lt, "word_answered signal")
    Rel(lt, ss, "request_save()")
    Rel(ss, saves, "writes", "JSON")
    Rel(scene, data, "loads", "ResourceLoader")
```

**Element types:**
- `Container_Boundary(id, "label") { ... }` — groups containers inside one deployable unit.
- `Container(id, "name", "technology", "description")` — internal container (app, service, worker).
- `ContainerDb(id, "name", "technology", "description")` — internal datastore.
- `ContainerQueue(id, "name", "technology", "description")` — internal message queue.
- `System_Ext` and `Person` can be reused from L1.

**Rules of thumb (one Godot process):**
- Each autoload, and each scene or UI the feature adds or changes, is one `Container`; the boundary brackets the game process.
- `data/` (shipped content) sits inside the boundary; `user://` files sit outside (they outlive builds).
- Offline tools (voice script, Blender scripts) are `System_Ext` — they run at build time, not in the game.

## Common mistakes

- **Mixing levels.** Don't put a component (a single class/struct) inside a Container diagram — either zoom out (it's part of the Container) or move to L3.
- **Typos in `Container_Boundary`.** Common: `Container_Bondary`, `ContainerBoundary` (no underscore). Mermaid silently renders an empty block.
- **`Rel` to an undeclared element.** Declare every `Person`/`Container`/`System*` first, then the `Rel` lines.
- **L1 with internal modules.** L1 = business scope. If a module shows up in L1, you're already at L2.
- **No label or protocol on `Rel`.** «Connected» tells the reader nothing. Always: what it does + how.

## Validating before commit

```bash
# Optional pre-commit check — extracts the Mermaid block and runs the CLI parser.
npx -y @mermaid-js/mermaid-cli@latest -i <(awk '/^```mermaid$/,/^```$/' docs/features/<slug>/sad.md) -o /tmp/out.svg
```

In practice: open `sad.md` in Obsidian or push to GitHub and inspect the render — both fail loudly on syntax errors.

## When the diagram doesn't fit

- L2 over 10–12 elements → show only the blocks this feature adds or changes; list the rest in a note.
- L1 with 15+ external systems → you're documenting the *organization*, not the *feature*. Pull back to «the systems this feature directly talks to».
