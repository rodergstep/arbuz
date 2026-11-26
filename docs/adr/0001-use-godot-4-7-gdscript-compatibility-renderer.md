---
status: Accepted
owner: "roderg"
reviewers: []
updated_at: "2026-11-26"
feature_size: "foundation"
ticket: "Phase 0 — setup"
---

# 0001 — Use Godot 4.7 standard with typed GDScript and the Compatibility renderer

- **Status:** Accepted
- **Date:** 2026-11-26
- **Deciders:** roderg (development plan), confirmed in `/survey`

## Context

The game must be built on an M4 MacBook and play smoothly on an Intel MacBook with integrated graphics, for macOS and Windows, with free tools only. The engine and renderer decide everything after this, so they are fixed before the skeleton exists.

## Decision drivers

- ≥30 fps and load ≤10 s on the Intel MacBook (CLAUDE.md performance budget).
- Free and offline; no runtime licences, no network.
- Claude writes the code: a text-first, well-documented language and scene format.
- Export to macOS (universal) and Windows from one project.

## Considered options

1. **Godot 4.7 standard, GDScript, Compatibility renderer** — OpenGL 3.3 backend that runs on old iGPUs.
2. **Godot 4.7 standard, Forward+ / Mobile renderer** — Vulkan/Metal, nicer lighting, heavier on the Intel iGPU.
3. **Godot 4.7 .NET with C#** — stronger typing, larger build, slower iteration, fewer addons tested on it.

## Decision outcome

**Chosen:** Option 1. The Compatibility renderer is the one that reliably holds the frame budget on the floor machine, and the Miyazaki-inspired look is achievable with cheap custom shaders. Typed GDScript keeps the type safety we want without the .NET build.

## Consequences

**Positive**
- Runs on the weakest machine; small exports; every addon we use supports it.

**Negative**
- No SDFGI, volumetric fog, SSR or other Forward+ effects; the painted look must come from shaders and textures.
- Fewer post-processing options; glow and tonemapping are limited.

**Neutral**
- Moving to Forward+ later is a project setting plus a shader review, if the floor machine ever changes.
- Stay on 4.7.x; upgrade only between phases after the tests pass.

## Links

- Plan: [`../development-plan.md`](../development-plan.md) — Phase 0, Art direction, Risks
- Map: [`../architecture-map.md`](../architecture-map.md) — Stack, Performance budget
