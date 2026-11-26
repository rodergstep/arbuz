# Draft generation — per-section contract for specify step 6

The authoritative format for each section is the `<!-- instruction -->` comment in [`../templates/spec.md`](../templates/spec.md). This file is the operational glue: where content comes from and what is forbidden.

## Inputs in priority order

1. **`CONTEXT.md` `## Glossary`** — canonical for role names + domain terms. If anything contradicts it, the glossary wins.
2. **The interview** — accepted decisions and relevant evidence from `docs/features/<slug>/idea.md`, plus current owner corrections and step-2 specification gaps, per [`brief-reuse.md`](./brief-reuse.md). Reuse the problem, trigger, outcome and constraints; preserve provenance and blockers.
3. **Ideation output** — reused brief evidence/accepted direction or new step-3 gap work → §1 ¶3. Never require absent matrix cells or invent scores to satisfy the fresh-suite format.
4. **Channel outputs** (step 5) — reference-module patterns, doc/MCP/KB quotes → §1 ¶4 traceability only.

## §5 acceptance-criteria contract

AC describes a **business-observable outcome from the actor's perspective**, in Given/When/Then. **No upper cap** — propose as many as needed so **every §4 user story has ≥1 AC** and all five coverage types appear. If a `Drop` / `Save as Open Question` during Socratic leaves a coverage type empty **or a retained §4 user story with no AC**, regenerate a replacement AC and run a mini-batch on it (the two coverage floors, see [`socratic.md`](./socratic.md)). The «every US has ≥1 AC» rule is a **re-checked floor**, not only a draft-time target — it's verified after every §5 resolution, so `sequences` and `review` downstream can rely on each use-case having a testable criterion.

Five coverage types, ≥1 each:

1. **happy** — the child does the main thing → the game responds and celebrates.
2. **toddler-error** — wrong pick, idle, mashing or walking away → gentle redirect, hint, or auto-pause; never a fail state.
3. **parent-only** — the child reaches a parent-only area → the parent gate holds and the child is never stuck. (A feature with no parent-only area writes one AC that confirms the child cannot reach any.)
4. **learning invariant** — a rule of the learning loop holds (review order, repetition, no word lost).
5. **cross-system** — the outcome depends on another system's state (save, progress, unlocks).

## Forbidden tokens in §5 AC (zero tolerance)

Checked by the critic's F6 and a regex scan over `spec.md`:

- GDScript keywords and calls: `func`, `signal`, `var`, `extends`, `snake_case(` identifiers with parentheses.
- Node and resource paths: `$Something`, `res://`, `user://`, `%UniqueName`.
- Autoload or class names in PascalCase that are system names (`InteractionSystem`, `SaveSystem`, …).
- File names and extensions: `.tscn`, `.gd`, `.tres`, `.res`, `.json`, `.csv`, `.ogg`.
- Engine constants: frame counts, physics layers, raw pixel sizes.

The mapping lives in `design` and `contracts`. The AC describes what the child or parent sees,
hears, and what the game remembers.

## Hygiene for §1–§3

§1–§3 describe the player's experience, not the implementation. Godot itself and the agreed addons may be named as constraints; naming a specific node type, addon feature or file format as a choice belongs to `design`.

## Pre-write hygiene (before Socratic)

- §4 US roles use CONTEXT glossary terms verbatim.
- §3 Non-goals each carry a reason (no inventing).
- §1 ¶3 states the committed approach without losing the vector.
- §5 has ≥1 of each coverage type and 0 forbidden tokens (self-scan; the critic + regex are the backstop).
