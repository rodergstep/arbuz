# Review dimensions and dispatch

One [`reviewer`](../../../agents/reviewer.md) pass covers all dimensions for a small diff. For a large one, fan out one reviewer per stage and merge.

## Stage 1: does it do what the spec says (blocks ship)

- **AC compliance.** For every claimed AC: does the game actually produce the observable outcome (what the child sees and hears, what the parent sees, what is saved)?
- **End-to-end trace (the backstop).** Take the **whole** §4 story set and §5 AC set, not only the trailers. Every story has at least one AC and a `sad.md` §6 flow (or a `ux-flows.md` flow). Every AC reaches: a flow or branch → the contract that supports it (if any) → a task in `tasks.json` → code. ACs tagged `<!-- added-by-fix -->` are traced like the rest. For a `ui` or `scene` area, a UI AC must reach a `ui`/`scene` task. Every state declared in the `ux-flows.md` manifest is built.
- **Contract fidelity.** The code matches `docs/contracts/` plus this feature's deltas: autoload method signatures and signal names, Resource fields, word-DB schema, tool CLI flags. `contract-checker` findings land here.
- **Save compatibility.** A change to save data bumps `save_version`, adds a `migrate_vN_to_vN+1`, never deletes a field in the same version, and has a fixture save from the previous version that loads (a small GUT test, the one test this project insists on). A missing fixture is stage 1.
- **Child safety and privacy.** No network calls, no analytics leaving the device, no external links or purchases reachable without the ParentGate, no recording or storing of the child's voice or image unless the spec says so explicitly, nothing frightening (sudden loud sounds, flashing faster than 3 Hz), no dark patterns (no streak guilt, no "come back" pressure). The session timer and pause still work.

A story or AC that dropped out of the chain is a stage-1 finding even if no line of the diff mentions it.

## Stage 2: is it good (usually non-blocking)

- **Conventions and patterns.** Typed GDScript, signal naming, scene/script layout and the pattern few-shots from `docs/architecture-map.md`. Autoloads only for cross-scene state. No new autoload without an ADR.
- **Toddler UX.** Every instruction is voiced; no reading needed; no fail state (a wrong answer gives a soft response and another try); touch and click targets ≥ the design-system minimum; colour is always paired with a shape or pattern; the hint ladder runs (repeat → glow → HintHand → auto-help) on the documented timings; UI uses design-system components and tokens, and any NEW component is registered and approved in `docs/design-system.md`.
- **Performance.** Nothing that obviously threatens 30 fps on the Intel MacBook: per-frame allocations in `_process`, unbounded particles, large textures without import limits, synchronous loads of big resources on the main thread during play, audio streams not preloaded for instant feedback. Load time stays within the budget.
- **Content.** Ukrainian and English word entries are correct and age-appropriate; audio exists for every word the code can pick; no placeholder text or sounds reachable in a release build.
- **Error and edge handling.** Missing audio file, corrupt or newer-version save, empty word set, rapid repeated taps, window focus lost mid-animation, quitting mid-save.

## Dispatch shape

Per [`../../_shared/critic.md`](../../_shared/critic.md): read-only tools, the reviewer re-reads the artifacts itself, and emits cited findings only:

```
- **[stage-N] <headline>** (file:line; AC: <id|n/a>; source: claude|codex|both): problem: <what>; suggested: <fix>.
```

A clean review returns `REVIEW_CLEAN: <scope>`. Drop findings without `file:line` and a concrete reason. Prioritise stage 1 over style, and judge against the artifacts, not taste.
