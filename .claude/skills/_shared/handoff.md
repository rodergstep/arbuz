# Stage handoff — what every skill prints when it finishes (the output contract)

> **Reference-only.** Not a skill. **Every** skill ends by emitting the handoff block defined here —
> as its **last output**, after its structural self-check and its per-document commits
> ([`write-and-commit.md`](./write-and-commit.md)). The format lives only in this file; each
> skill keeps a one-line pointer and supplies its own *What I did* / *Review* / *next command*. This
> exists because a bare «Next: …» line is hard to act on — the user can't tell what changed, which
> files to open, or what to run next without scrolling back.


## The block (sectioned format)

```md
## ✅ <skill> — <slug>

**What I did**
- <1–3 bullets: the artifact(s) produced/changed>
- committed `<sha>` <message>   ← one line per commit, or the reason it was skipped

**Review before continuing**
- `docs/features/<slug>/<file>` — <what to check here>
- `docs/features/<slug>/<file2>` — <…>

**Run next**
1. `/clear` — mandatory (fresh context; the next stage re-reads its inputs from disk)
2. then run:
   ```
   /<next> <slug>
   ```
   ↳ or `/<alt> <slug>` to <skip condition>   ← only when a real skip exists
```

Rules for filling it:

- **Always emit it** as the final output, once per run, after the commits. Never end a
  skill on a bare «Next: X».
- **What I did** — concrete and self-contained: name the files written and every commit made
  (short SHA + message), or why a commit was skipped (nothing changed, not a git repo, merge in
  progress, `auto_commit: off` → the ready-to-run commands), so the user doesn't scroll up to
  reconstruct it.
- **State the size + route used.** *What I did* names the `feature_size` AND the route the stage
  worked at — «size M + route standard (from `.size`/`.route`)»; if the stage had to **default**
  because a file was missing, say so loudly — «size M (default — no `.size`; run
  `/classify-size <slug>`)», «route standard (default — no `.route`)» — so a missing size/route
  surfaces at this gate, not three stages later. A missing `.route` always means `standard` (the
  pre-route behaviour — fully back-compatible). (`specify` establishes both at the start, so this
  should be rare.)
- **Review before continuing** — list **every artifact this stage wrote or changed**, each as a real
  `docs/features/<slug>/…` path (or repo-root path like `docs/architecture-map.md`) plus a one-liner
  on what to eyeball. This *is* the per-gate review checklist.
- **Run next** — the next command in **`/<name> <slug>`** form inside a fenced code block (so the
  user copies it in one click). `/clear` is step 1 and **mandatory** for a forward backbone handoff.
  Add a `↳ or …` skip-alternative **only** when one genuinely exists (see the table). The
  skip-alternatives come from the **fast-lane N/A conditions** in [`size-matrix.md`](./size-matrix.md);
  **how each resolves is route-dependent** — auto-skip on `quick`, offered on `standard`,
  suppressed on `full` (see the *Route-resolved forward handoff* variant below).
- Keep the `<slug>` substituted with the real slug — never leave the literal `<slug>` in the printed
  block.

## Variants

- **Backbone forward handoff** (`survey → … → review → ship`): `/clear` mandatory + the next stage.
- **Route-resolved forward handoff** (a backbone stage whose successor is an *optional* stage —
  `specify`, `clarify`, `ux-flows`, `design`, `tasks`): before printing *Run next*,
  resolve the next stage per `docs/features/<slug>/.route` and the Routes table in
  [`size-matrix.md`](./size-matrix.md):
  - **`quick`** — evaluate the next optional stage's N/A condition yourself. Holds → *Run next*
    names the post-skip stage, *What I did* states «auto-skipped `<stage>`: <reason>», and the
    `↳ or` line **inverts** — it offers the skipped stage («run the full path»). Doesn't hold →
    normal forward handoff (the stage is not skipped).
  - **`standard`** — normal forward handoff; add the `↳ or` skip-alternative when the N/A
    condition holds (the user picks).
  - **`full`** — normal forward handoff; **never** print an `↳ or` skip line.
  Missing `.route` → `standard`. The route steers handoffs only — a stage invoked directly always
  runs.
- **Loop-back** (`review → implement` on `CHANGES REQUESTED`): **no `/clear`** — you stay in context
  to iterate; *Run next* = `/implement <slug>` (fix), then re-review the changed surface.
- **Terminal** (`ship`): there is no pipeline successor. *Run next* becomes **Done** — the PR command/URL
  + «merging to main is your call»; still print *What I did* + *Review* (the changelog + PR).
- **Utility** (`interview`, `config`, `classify-size`, `glossary`, `decide-adr`, `roadmap`, `design-system`, `fix`, `playtest`): called ad-hoc, not a
  gate. `/clear` is **optional** (recommend it only if the context is large); *Run next* = «resume
  your backbone stage», naming the likely one (e.g. `/design <slug>`). Print *What I did* +
  *Review* (the one file it wrote). One exception: `fix` alone adds a **conditional** recommendation —
  when the fix touched >5 files or crossed a module boundary, *Run next* also offers
  `/review <slug>` (a recommendation, never a gate).

## Canonical sequence (stage → review-files → next)

| Stage | Review before continuing (files written) | Run next |
|---|---|---|
| `interview` | `docs/features/<slug>/idea.md` | `ready` → `/specify <slug>`; otherwise name the evidence action, reframe, or stop |
| `survey` | `docs/architecture-map.md` (+ scaffold `tasks.json` on greenfield) | greenfield → `/scaffold`; otherwise `/roadmap` or `/specify <slug>` |
| `scaffold` | the committed skeleton + green smoke test | `/specify <slug>` |
| `specify` | `docs/features/<slug>/spec.md`, `.size`, `.route` | `/clarify <slug>` ↳ or `/ux-flows <slug>` (zero §8 open questions; nothing child-facing → `/design <slug>`) |
| `clarify` | `spec.md` (tightened) | `/ux-flows <slug>` ↳ or `/design <slug>` (nothing child-facing changes) |
| `ux-flows` | `docs/features/<slug>/ux-flows.md` (flows + scene/state manifest) | `/design <slug>` ↳ or `/tasks <slug>` (`quick` only: no system/API change) |
| `design` | `sad.md` (+ `areas`, §6 sequences) + `adr/` | `/contracts <slug>` ↳ or `/tasks <slug>` (no contract change) |
| `contracts` | `contracts/*.md` (+ `contract-check.md`) | `/tasks <slug>` |
| `tasks` | `tasks/` + `tasks.json` | `/plan-tests <slug>` |
| `plan-tests` | `test-plan.md` (or `spec.md` `## Test plan`) | `/implement <slug>` |
| `implement` | the committed diff (code + tests) + `tasks/tracker.md` / `tasks.json` | `/review <slug>` |
| `review` | `_review/review-<date>.md` (+ `codex-<date>.md`) | `/ship <slug>` (PASS) · `/implement <slug>` (CHANGES REQUESTED, no `/clear`) |
| `ship` | `CHANGELOG.md`, `docs/roadmap.md`, promoted `docs/adr/` + `docs/contracts/`, the PR | **Done** — PR link; merge is your call. after merge → `/playtest <slug> before` |
| `playtest` | `docs/playtests/<date>-<slug>.md` | before: go play; after: `/fix <slug>` or `/specify <slug>` for the top finding |
| `config` | `.claude/sdd.local.md` (gitignored) | resume your stage |
| `classify-size` | `.size` + `.route` | resume — e.g. `/specify <slug>` |
| `design-system` | `docs/design-system.md` (+ `ui/theme/*.tres`) | resume — e.g. `/ux-flows <slug>` |
| `glossary` | `docs/CONTEXT.md` (or the feature's `CONTEXT.md`) | resume — e.g. `/design <slug>` |
| `decide-adr` | `adr/NNNN-<title>.md` | resume — `/tasks <slug>` |
| `roadmap` | `docs/roadmap.md` | resume your stage |
| `fix` | `_fixes/<date>-<short>.md` + the diff | resume, or `/review <slug>` when the fix was wide (>5 files / crossed a system) |

The `↳ or` cells show the `standard` rendering; on `quick` the stage auto-skips (and the `↳ or`
inverts), on `full` the `↳ or` line is dropped.

## Discipline

- **The block is the last thing printed — every run, no exceptions.** A skill that ends on prose
  without it has regressed.
- **Real paths, not descriptions.** «the SAD» is not reviewable; `docs/features/<slug>/sad.md` is.
- **The next command is copy-ready** — `/<name> <slug>` in a fenced block, slug substituted.
- **`/clear` only where it's correct** — mandatory on a forward backbone handoff, omitted on a
  loop-back (you're iterating), optional after a utility.
- **Format canonical here** — a skill that hand-rolls its own block shape has duplicated the contract.

## Where each skill calls this

Every skill's final protocol step ends with: «emit the **stage-handoff block** per
[`handoff.md`](./handoff.md)» + its own next command from the table above. The format + variants live
here; the skill supplies only the run-specific content.
