---
contract: tools
feature: "<slug>"
status: Draft
---

# Tool CLI delta — <slug>

## `<tool>` (`tools/<path>`)

| Aspect | Value |
|---|---|
| Command | `<python3 tools/voice/generate.py --lang uk --only-missing>` |
| Inputs | <word DB path, voice model path> |
| Outputs | <audio/voice/<lang>/<word_id>.ogg> |
| Exit codes | 0 ok · 1 <...> · 2 <...> |
| Idempotent | yes/no — <re-running skips existing files> |
