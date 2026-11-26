---
status: building
feature_size: M
route: quick
updated_at: "2026-11-26"
---

# Spec (lite) — Richer world; Ukraine and England look like different countries

> From the playtest of 2026-11-26: "The graphics is very primitive… Ukraine and England look
> similar but it's different country."

## 5. Acceptance criteria

- **AC-01 Each country has its own light.** A town's `look` (sky colours and clouds, sun colour
  and strength, ambient, saturation, ground, grass and road colours, backdrop colours) sets the
  scene. Ukraine: warm golden summer, deep blue sky, yellow-green meadows, earth roads.
  England: softer, cooler light under a cloudier sky, deep green lawns, grey streets with pale
  pavements.
- **AC-02 Ukraine's own things.** Wheat fields, a blossoming cherry orchard, rows of poplars,
  willows by the river, haystacks, a stork on its nest, a well sweep (журавель), pumpkins, yard
  fences with clay pots and blue-and-yellow gates, poppies and cornflowers in the meadows.
- **AC-03 England's own things.** Oaks, rows of terrace houses, a red phone box and pillar post
  box, a red double-decker by the harbour, park benches, a pond with ducks, box hedges, iron
  railings, tulip beds.
- **AC-04 No bare horizon.** Fields and soft hills all round beyond the edge, in each country's
  colours.
- **AC-05 Never in the way.** Big new things have collision baked into navigation; small ones
  (flowers, bushes) keep clear of anything he clicks or walks to.
- **AC-06 Budget.** Repeated things are MultiMeshes (one draw call per colour); ≥30 fps on the
  Intel MacBook (check with F3).
