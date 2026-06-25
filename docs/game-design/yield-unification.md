# Yield Unification

This document describes the current yield contract. The goal is for UI, city
economy, worker recommendations, and AI to stop relying on different value
tables.

## Source of Truth

| Area | Source |
| --- | --- |
| Base terrain yield | `CityRuleset.terrainYields` |
| River yield | `CityRuleset.riverYield` |
| Resource yield | `CityRuleset.resourceYields` |
| Improvement yield | `CityRuleset.improvements[*].tileYield` |
| City center | `CityRuleset.cityCenterYield` |
| Building science | `CityBuildingEffect.FlatCityScienceEffect` |

`TileYieldRules` no longer has a separate balance table. For the standard game
it uses `CityRulesets.standard`, and balance variants can inject another
`CityRuleset`.

Science is not part of `TileYield`. It is calculated by
`ScienceYieldCalculator` because research has a separate stream from food,
production, gold, and defense and must combine city base, technologies,
specializations, projects, and buildings without muddying city economy.

## Domain Contracts

| API | Role |
| --- | --- |
| `TileYieldRules.forTile(tile, ruleset)` | Base hex yield without improvement |
| `TileYieldRules.forInput(input, ruleset)` | Base yield for assessment systems |
| `CityTileYieldRules.forTile(tile, improvement, ruleset)` | Hex yield with optional improvement |
| `CityTileYieldRules.forCityHex(...)` | Hex yield in city context; the center has fixed city-center yield |
| `ScienceYieldCalculator.totalForPlayer(...)` | Player science/turn from city base, technology effects, specialization, and buildings |
| `WorkerImprovementScoring.scoreFor(...)` | Shared scoring for worker improvement recommendations |
| `WorkerImprovementChargeRules` | Number of improvements a worker can complete before disappearing |

Parity required by tests:

```text
TileYieldRules.forTile(tile, ruleset)
==
CityTileYieldRules.forTile(tile, ruleset: ruleset)
```

for a hex without an improvement.

## Current Standard Values

### Terrain

| Terrain | Food | Production | Gold | Defense |
| --- | ---: | ---: | ---: | ---: |
| grassland | 2 | 0 | 0 | 0 |
| plains | 1 | 1 | 0 | 0 |
| forest | 1 | 1 | 0 | 0 |
| hills | 0 | 2 | 0 | 0 |
| tundra | 1 | 0 | 0 | 0 |
| jungle | 1 | 0 | 0 | 0 |
| wetlands | 2 | 0 | 0 | 0 |
| coast | 1 | 0 | 0 | 0 |
| lake | 1 | 0 | 0 | 0 |
| desert/snow/mountain/ocean | 0 | 0 | 0 | 0 |

### Modifiers and Resources

| Element | Food | Production | Gold | Defense |
| --- | ---: | ---: | ---: | ---: |
| river | 1 | 0 | 0 | 0 |
| wheat/fish/rice/apple/banana/citrus | 2 | 0 | 0 | 0 |
| deer/cow/sheep | 1 | 1 | 0 | 0 |
| iron/marble | 0 | 2 | 0 | 0 |
| luxury strategic late resources | 0 | 0 | 0 | 0 |

Luxuries and later strategic resources can still have value through unlocks,
improvements, technologies, or future inventory/economy hooks. They do not
automatically grant base hex yield unless `CityRuleset.resourceYields` says so.

## Building Science

Only selected standard buildings from `CityBuildingCatalog.standard` provide
`FlatCityScienceEffect`. The effect is reserved for buildings tied to
knowledge, applied science, medicine, or information storage.

| Building | Science |
| --- | ---: |
| `archive` | +2 |
| `academy` | +3 |
| `university` | +3 |
| `observatory` | +3 |
| `laboratory` | +4 |
| `reactor` | +3 |
| `surveyorsOffice` | +2 |
| `apothecary` | +1 |
| `hospital` | +2 |
| `mapRoom` | +2 |
| `museum` | +2 |

City science/turn is built from:

```text
baseSciencePerCity
+ cityScienceBonus from technologies
+ science specialization
+ effective science from buildings
```

Building science has diminishing returns within a city. Effects are sorted from
largest to smallest, then multiplied by:

| Science-building slot | Multiplier |
| --- | ---: |
| Best building | 1.00 |
| Second building | 0.70 |
| Third and later | 0.35 |

This lets knowledge-related buildings help research without making a wide stack
of such buildings scale linearly. `maxSciencePerCity`, when enabled in the
ruleset, still caps total city science after buildings are included.

UI and AI must pass the active `CityRuleset` to
`ScienceYieldCalculator.totalForPlayer(...)` so balance variants and test
rulesets see the same building effects as gameplay. `research` projects remain
separate `bonusScience`/project output and are not covered by the city building
multiplier.

## Worker Improvement Scoring

`WorkerImprovementScoring` moves the improvement-recommendation heuristic into
core. The UI still shows `recommended` in the manual `Improve` panel, but no
longer auto-selects the best improvement from the worker menu.

| Parameter | Weight |
| --- | ---: |
| Food from improvement | 1000 |
| Production from improvement | 300 |
| Gold from improvement | 180 |
| Defense from improvement | 80 |
| Resource specialist bonus | 700 |
| Food from base hex | 20 |
| Production from base hex | 5 |

This is still a heuristic, not hard economic balance. The important change is
that its `baseYield` comes from `CityTileYieldRules.forTile`, which is the same
model used by city economy. Changing these weights affects recommendations in
the manual worker panel.

## Worker Improvement Charges

The worker is no longer a permanent unit that can improve the map forever. It
has a `workerBuildCharges` counter that determines how many completed
improvements it can still build.

| Parameter | Current value | Balance meaning |
| --- | ---: | --- |
| `WorkerImprovementChargeRules.defaultWorkerCharges` | 1 | Default worker disappears after completing the first improvement |
| `GameUnit.workerBuildCharges` | per unit | Allows future workers with 2-3 improvements without changing HUD flow |
| `remainingAfterImprovement(...)` | `charges - 1` | Charge consumption after actual construction completion |

Worker removal happens only after `workerJob` completes, not when an option is
selected. Canceling construction or receiving an illegal job should not consume
a charge.

## What We Are Not Doing Yet

| Out of scope | Reason |
| --- | --- |
| Multi-turn auto-improve | Requires saved unit mode, pathfinding, and cancellation rules |
| City role suggestion | Will use unified yield, but needs a separate city-role model |
| Resource-value-card tuning | The card exists as an explanatory layer; separate luxury/strategic tuning needs a balance decision |
| Balance-value changes | Yield unification removes model divergence, but does not tune a new economy |

## Risks To Watch

| Risk | Signal | Possible response |
| --- | --- | --- |
| Hex assessment feels less "rich" | Many hexes have lower gold/defense preview than old `TileYieldRules` | Add a separate strategic assessment score instead of pretending it is city yield |
| AI likes certain starts more or less | Basic strategy site-yield evaluation shifts | Tune `CitySiteScorer`, do not return to a second yield table |
| Worker recommends too much food | Food weight 1000 dominates | Change weights in `WorkerImprovementScoreBalance` |
