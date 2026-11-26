# Blast-radius heuristic — when an architectural decision becomes ADR-worthy

The skill makes 15–30 decisions per pass. Without a gate you'd either spawn one ADR per decision (noise — kills the genre) or zero (loses the *why* of the important ones). The blast-radius heuristic picks the few that matter. It is design's per-skill Socratic gate, run on every **Approved** decision (see [`./socratic.md`](./socratic.md)).

## The three criteria

A decision crosses the threshold if it scores **2 of 3** (a single criterion = borderline, ask explicitly).

### 1. Irreversible

> If we picked a different option three months from now, would the rework take ≥3 days?

**Fires** for, e.g.:

- **Save-file shape** — moving a field later means a migration step, fixtures, and risk to the child's saves.
- **Which autoload owns a piece of state** — moving it later touches every scene that reads or writes it.
- **Signals vs direct calls between scenes and systems** — changes the coupling and the test setup of every caller.
- **Content format** — `Resource` (`.tres`) vs JSON/CSV for words or chapters; switching means converting every data file and the tools that write them.
- **Scene composition** — inheritance vs composition for a family of activity scenes.

**Does not fire** for, e.g.:

- **A tuning value** (hint delay 8 s vs 10 s, car speed) — one line.
- **Naming** — the editor renames it.
- **Which built-in node to use** inside one scene (a `Tween` vs an `AnimationPlayer`) — local, cheap to swap.

### 2. Multi-system impact

> Does this decision change something seen by ≥2 systems or scenes?

**Fires** for: an autoload's public method or signal; a save field read by two systems; a word DB column read by the voice script and the tracker; a shared UI component's API.

**Does not fire** for: a private function inside one script; a node path inside one scene; a debug log line.

### 3. Has legitimate alternatives

> Will a reader six months from now ask «why not X?» where X is a real, non-strawman alternative?

**Excludes:** decisions where the alternative is obviously worse (no strawman ADRs); decisions where the alternative is ruled out by an existing constraint (no ADR for «we used the language the repo is already written in»).

**Catches:** choices that look arbitrary from the code (why *this* cache TTL? why *this* circuit-breaker threshold?); trade-offs where two reasonable engineers would pick differently; anything where the option set was 2–3 serious options, not 1.

## Using the heuristic during the Socratic pass

After each `AskUserQuestion` choice:

1. **Score it** — how many of the three fire?
2. **Decide:** 0 → inline, no ADR. 1 → borderline (default inline, except §4 Solution Strategy where the bar is lower because strategy is broad by definition). 2+ → ADR.
3. **On a borderline,** ask explicitly: «This is borderline ADR-worthy because of <criterion>. Lock as ADR or keep inline?» with `Lock as ADR` (Recommended if irreversible) / `Inline only`.

## How many ADRs

- SAD-lite (standard): 1–3 is healthy.
- Full: 3–8 is healthy; more than 10 usually means tactical detail was ADR-ified.

## Closing self-review

1. Does §9 reference every file in `adr/`? No orphans.
2. Does every ADR have a Status (`Accepted`) and a Decision outcome (not just a Context)?
3. For each ADR — would the heuristic still gate it if you ran it again? (Did you ADR-ify a trivial config value?)
4. For inline decisions — does any feel like it should have been an ADR? Promote it.

## Anti-patterns

- **ADR-ifying the alternative you rejected.** The ADR is about the chosen path; alternatives go in `## Considered options`, not their own file.
- **An ADR with `Status: Proposed` from this skill.** Synchronous decisions with the user → `Accepted`. Use `decide-adr` for asynchronous Proposed → Accepted flows.
- **One ADR per quality goal.** Quality goals live in §10; ADRs document the specific *decisions* taken because of them.
- **A title that names the problem, not the decision.** `0003-word-stats.md` (bad) vs `0003-store-word-stats-in-learning-tracker.md` (good).
