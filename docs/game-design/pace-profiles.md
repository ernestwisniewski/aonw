# Pace Profiles

This document describes the shared game-pace contract. The goal is for
game-length selection to affect research cost, production, city growth,
flexible objective targets, and domination pressure, rather than only the turn
limit and lobby description.

Main code sources:

| Area | Files |
| --- | --- |
| Pace model | `packages/aonw_core/lib/game/domain/match_rules/pace_balance.dart` |
| Match rules | `packages/aonw_core/lib/game/domain/match_rules/*` |
| Research | `research_cost_calculator.dart`, `research_turn_processor.dart`, `research_overflow_rules.dart` |
| Production | `city_production_queue.dart`, `city_turn_processor.dart`, `persistent_city_production_resolver.dart` |
| Growth | `city_growth_rules.dart`, `city_economy_breakdown.dart` |
| Objectives | `objective/game_objective.dart` |
| Turn flow | `persistent_turn_economy_processor.dart`, local transport, server finalizer |
| UI/ETA | technology panel, city production panel, city yield breakdown |
| Domination warnings | `domination_progress_calculator.dart`, `hud_victory_status_summary.dart` |

## UI Presets

Single player shows four simple presets:

| UI | GameLengthConfig | Turn limit | Score fallback | Notes |
| --- | --- | ---: | --- | --- |
| `Short` | `standard60` | 120 | yes | Fast 60-minute match |
| `Normal` | `normal90` | 180 | yes | Default 90-minute single-player match |
| `Long` | `long120` | 240 | yes | Longer 120-minute match |
| `Very long` | `unlimited` | none | no | Existing unlimited mode preserved |

## Profiles

| Profile | Research cost | Unit cost | Building cost | Growth cost | Objective target | Improvement turns | Notes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `unlimited` | x1.00 | x1.30 | x1.45 | x1.15 | x1.00 | +1 | Existing no-limit balance; UI `Very long` |
| `standard60` | x0.80 | x0.80 | x0.85 | x0.85 | x0.85 | 0 | Faster 60-minute pace validated by telemetry |
| `normal90` | x0.95 | x0.90 | x0.92 | x0.92 | x0.92 | 0 | Intermediate default 90-minute profile |
| `long120` | x1.10 | x1.00 | x1.00 | x1.00 | x1.00 | 0 | Slower research for 120-minute matches |

After adding `normal90`, the available game modes are `standard60`,
`normal90`, `long120`, and `unlimited`. The 30-minute/45-minute presets and
manual turn limits remain outside the model and UI to keep game-length choice
simple and readable.

## Scaling Formula

All positive costs and scaled objective targets go through one deterministic
helper:

```text
scaledCost = max(1, ceil(baseCost * multiplier))
```

A cost of `0` remains `0`. This keeps continuous projects such as wealth and
research without a completion cost.

Objective targets use the same formula through `PaceBalance.objectiveTarget(...)`,
but only for goals whose definition marks them with `targetScaling = pace`.

## Research

Effective technology cost is calculated in this order:

```text
baseResearchCost =
  ceil(technology.baseCost * cityMultiplier * boostMultiplier * eraMultiplier)

finalResearchCost = PaceBalance.researchCost(baseResearchCost)
```

| Parameter | Meaning |
| --- | --- |
| `technology.baseCost` | Base technology cost |
| `cityScalingPerExtraCity` | Penalty for each city after the first |
| `boostDiscount` | Best active technology boost |
| `specializationEraCostMultiplier` | Multiplier for specialization-era technologies |
| `industryEraCostMultiplier` | Multiplier for industry-era technologies |
| `strategyEraCostMultiplier` | Multiplier for strategy-era technologies |
| `researchCostMultiplier` | Pace-profile multiplier |

The same cost is used for normal research progress and for the science-overflow
limit after choosing the next technology.

The standard technology ruleset uses x1.30 for specialization-era costs, x1.75
for industry-era costs, and x3.50 for strategy-era costs. Foundation,
settlement, and expansion technologies use x1.00 before the pace multiplier.

## City Production

| Target | Base cost | Pace multiplier | Notes |
| --- | ---: | ---: | --- |
| Unit | `UnitProductionDefinition.productionCost` | `unitProductionCostMultiplier` | Scales queue completion, rollover, and rush |
| Building | `CityBuildingDefinition.productionCost` | `buildingProductionCostMultiplier` | Scales queue completion, rollover, and rush |
| Project | 0 | none | Projects are continuous and convert production into output |

`productionPerTurn` is not scaled by pace. Pace shortens or lengthens the
distance to the target; it does not change city yield.

Continuous project output is intentionally lossy:

| Project | Output |
| --- | --- |
| Wealth | `ceil(productionPerTurn / 2)` gold |
| Research | `ceil(productionPerTurn / 12)` science |

After the production rebalance, the base catalog intentionally separates unit
and building roles:

| Group | Example costs | Intent |
| --- | --- | --- |
| Early buildings | granary 6, workshop 15, marketplace 20 | Granary is the cheap opening infrastructure; other buildings remain real infrastructure investments |
| Mid/late production buildings | forge 22, factory 30, powerPlant 62, assemblyPlant 70 | Stronger production cities close infrastructure faster, but cannot build the whole catalog without choices |
| Early units | warrior 22, archer 26, worker 18, settler 30 | Units take clearly longer to produce to limit army and settler spam |
| Mid/late units | cavalry 44, fieldCannon 68, tank 96, warship 82 | Later armies are strategic decisions, not the default filler for every queue |

The change lives in `CityBuildingCatalog.standard` and
`UnitProductionCatalog.standard`. After it, AI production scoring received a
separate pass: it is less eager to spend the final unit-supply slot on
non-urgent queues, gives stronger weight to production buildings, and permits
projects as a relief valve when units are no longer the best choice.

## City Growth

First calculate the standard growth threshold:

```text
baseGrowthCost =
  growthBaseCost
  + growthCostPerPopulation * population
  + growthCostPerControlledHex * territoryHexCount

finalGrowthCost = PaceBalance.growthCost(baseGrowthCost)
```

Food upkeep, net food, and food deposit are not scaled. Pace changes the growth
threshold, but does not hide the city's real economy.

## Domination

Domination has two pace levels:

| Profile | Required control | Required hold | Warning cadence |
| --- | ---: | ---: | --- |
| `standard60` | 45% | 10 | Warn only when a rival has at most 1 hold turn remaining |
| `normal90` | 47% | 12 | Warn only when a rival has at most 1 hold turn remaining |
| `long120` | 50% | 14 | Warn only when a rival has at most 1 hold turn remaining |
| `unlimited` | 60% | 5 | Warn only when a rival has at most 1 hold turn remaining |

Warning cadence follows `requiredHoldTurns`, not a hardcoded profile name.
Capped presets require less map control than unlimited but longer holds. This
keeps domination visible in timed games without letting a short territorial
spike end the match. The `Objectives` panel shows score pressure instead of
domination hold when an active hold can no longer finish before the cap, or
when no active hold exists.

## Where Pace Is Active

| Layer | Status |
| --- | --- |
| Local single-command reducers | `GameCommandContext.paceBalance` from the save |
| Local simultaneous-turn finalizer | `save.matchRules.paceBalance` |
| Server turn finalizer | `save.ruleset -> MatchRules.paceBalance` |
| Server city/research commands | Pace from the match's saved ruleset |
| Core AI planning/simulation | `GameRuleset.paceBalance` |
| Cost and ETA UI | Research panel, city production panel, city yield breakdown |
| Objective tracker/HUD | Flexible guidance targets scaled through `PaceBalance.objectiveTarget(...)` |
| Victory HUD | Domination thresholds and warning cadence depend on pace/hold window |

## What This Stage Does Not Scale Yet

| System | Decision |
| --- | --- |
| Domination tile ownership algorithm | No change; pace changes thresholds and warnings, not control geometry |
| Objective targets with numeric copy | Fixed until dynamic copy exists, so the UI does not promise a different number than the target |
| Combat stats | No change |
| Movement/vision | No change |
| Gold income and rush gold per production | No change |
| Wealth/research project output | Controlled by `CityProjectRules`, not by pace multipliers |

## Balance Notes

- `unlimited` must remain the reference point and keeps the current costs.
- `standard60` is not an alias for unlimited: it has faster costs and shorter
  flexible objective targets so a 60-minute match has its own rhythm.
- `normal90` is the default single-player preset: intermediate costs, a
  180-turn limit, score fallback enabled, and domination at 47% / 12 turns.
- `long120` keeps production/growth costs like unlimited, but has slower
  research at x1.10 and separate domination pacing at 50% / 14 turns so the
  longer cap has its own ending.
- `Very long` is exactly the previous `unlimited`: no turn limit, no score
  fallback, and preserved pacing.
- After map and AI tests, profiles can be tuned without touching the unit,
  building, and technology catalogs.
- After the cost rebalance, AI production scoring keeps a smaller unit buffer
  than before: a 36-turn test run accepts military at `cities - 1` while supply
  remains positive and production goes into infrastructure.
