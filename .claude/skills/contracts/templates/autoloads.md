---
contract: autoloads
feature: "<slug>"
status: Draft
---

# Autoload API delta — <slug>

<!-- instruction: one block per touched autoload. Only PUBLIC items (no leading underscore).
A removed/renamed public item is breaking: list callers and link an ADR. -->

## `<AutoloadName>` (`autoload/<file>.gd`)

### Methods

| Signature | Change | Called by | Notes |
|---|---|---|---|
| `func <name>(<arg>: <Type>) -> <Type>` | added / changed / removed | <scenes/UI> | <side effects, e.g. "saves immediately"> |

### Signals

| Declaration | Change | Emitted when | Connected by |
|---|---|---|---|
| `signal <name>(<arg>: <Type>)` | added / changed / removed | <event> | <listeners> |

### Breaking changes

- <none> | <item> — callers: <file:line list> — ADR-NNNN
