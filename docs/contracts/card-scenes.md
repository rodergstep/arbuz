# Contract: card scenes (`content/words/scenes.csv`)

While a learning card speaks an example sentence, its picture acts the sentence out as a small
looping scene (`CardStage`, `game/ui/card_stage.gd`). A sentence without a row keeps the live
picture of the thing in the world.

| Column | Meaning |
|---|---|
| `sentence` | exactly as in `words.csv` `examples_en` (the first two of each word are spoken) |
| `ground` | `grass` · `river` (water along z, under a bridge along x) · `road` (along x) · `sea` · `town` · `farm` · `kitchen` · `night` |
| `actors` | `;`-separated, each `thing action x z [more]` |
| `zoom` | camera distance factor (1 = default; bigger for big things) |

**Things** are names for `Props.make()` (`game/art/props.gd`): a model in `assets/models/<name>.glb`
wins (aliases: car, house, shop, toymaker, clockmaker), otherwise a built shape: apple, egg,
milk, flour, cake, bread, cup, table, ball, toy, letter, door, clock, flower, bridge, boat, bus,
sun, cloud, moon, dog, cat, lion, hen, bird, balloon_<colour>, a number word.

**Actions:** `stand`; `move x2 z2 [speed]` (walkers bob; over a bridge they follow the deck);
`swim x2 z2 [speed]`; `kick x2 z2 [speed]` (bounces away); `arrive x2 z2 [speed]` (stops at the
end); `say Text…` (hops, speech bubble); `wave`; `grow`; `count n` (n copies pop in one by one);
`fly` (rises); `spin`; `float height`; `eat` (gets smaller bite by bite); `glow` (a lamp's light);
`open` (a door's `Leaf` swings); `tick` (a clock's `Hand` moves).
