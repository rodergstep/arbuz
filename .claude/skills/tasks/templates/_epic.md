# Epic — <slug>

> **Spec:** [spec.md](../spec.md) · **Design:** [sad.md](../sad.md) · **UX flows:** [ux-flows.md](../ux-flows.md) · **Contracts:** [contracts/](../contracts/) · **ADRs:** [adr/](../adr/)

## Goal

<!-- instruction: 2–3 sentences — what shipping this epic delivers, tied to spec §2 Goals. -->

## Scope

- **In:** <the layers/modules this epic touches>.
- **Out:** <explicit non-scope, from spec §3>.

## Task map

<!-- instruction: the dependency graph as a Mermaid flowchart. This is the same DAG as tasks.json. -->

```mermaid
flowchart LR
    T1[T1 save] --> T3
    T2[T2 core] --> T3[T3 scene]
    T3 --> T4[T4 ui] --> T5[T5 tests]
    T5 --> T6[T6 tests]
```

## Tasks

See [tracker.md](./tracker.md) for status. Machine contract: [tasks.json](../tasks.json).

| # | Task | Layer | Blocked by | DoD (short) |
|---|---|---|---|---|
| T1 | <title> | save | — | <one line> |
| T2 | <title> | core | — | <one line> |

## Risks / Hard rules

<!-- instruction: any spec §6 NFR / sad §11 constraint a task must not violate. -->
