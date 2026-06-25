# Per-System ETA

This document describes the shared ETA display contract for systems the player
plans in turns: research, city production, and city growth.

## UX Goal

The player should immediately see not only progress, but also the answer to
"when will this finish?". The most important panels therefore show two levels
of information:

| Information | Example | Use |
| --- | --- | --- |
| Remaining turns | `3 turns` | Fast scanning in lists and banners |
| Expected completion turn | `T12` or `turn 12` | Planning across the whole match |
| No-progress fallback | `no production`, `no progress`, `stagnant` | Clear signal that simply advancing a turn will not finish anything |
| Ready state | `ready` | Cost/threshold is already covered and the system is waiting for the next turn processing |

## Shared Model

The UI uses the shared `TurnEta` model:

| Field | Meaning |
| --- | --- |
| `turnsRemaining` | Number of turns needed at the current pace |
| `completionTurn` | Turn number when the system should finish |
| `blockedLabel` | Label used when pace is 0 or ETA cannot be calculated |

Base formula:

```text
remaining = target - currentProgress
turnsRemaining = ceil(remaining / progressPerTurn)
completionTurn = currentTurn + turnsRemaining
```

If `remaining <= 0`, the UI shows `ready`. If `progressPerTurn <= 0`, the UI
shows a fallback instead of a fake ETA.

## Research

Research ETA is calculated from the active or potential technology:

| Parameter | Source |
| --- | --- |
| `target` | Effective technology cost after city-count and boosts |
| `currentProgress` | Player progress for the technology |
| `progressPerTurn` | Current player science per turn |
| `completionTurn` | `gameSave.turn + turnsRemaining` |

Visibility locations:

| UI | ETA visibility |
| --- | --- |
| Active research banner | `N turns • TX` |
| Technology cards/tree nodes | `N turns • turn X` |
| Technology details | Progress with appended ETA |
| Science breakdown popup | Active research + `N turns • turn X` |
| Global research button tooltip | Active research + ETA |

Fallback:

| Situation | Label |
| --- | --- |
| No active research | `No technology selected` |
| No science/turn | `no progress` |

## City Production

Production ETA is calculated for buildings and units. Continuous projects such
as wealth or research do not have completion dates.

| Parameter | Source |
| --- | --- |
| `target` | Building or unit production cost |
| `currentProgress` | `investedProduction` |
| `progressPerTurn` | Effective city production for the target |
| `completionTurn` | `gameSave.turn + turnsRemaining` |

Visibility locations:

| UI | ETA visibility |
| --- | --- |
| Active production banner | `N turns • TX` |
| Production list tile | Separate `N turns` and `TX` pills |
| Building/unit details | Progress with appended `N turns • turn X` |

Fallback:

| Situation | Label |
| --- | --- |
| Production/turn is 0 | `no production` |
| Continuous project | `continuous` |
| Cost already covered | `ready` |

## City Growth

Growth ETA is calculated from food deposit, not from the net food label alone,
because buildings can change the real amount of food stored for growth.

| Parameter | Source |
| --- | --- |
| `target` | `growthCost` |
| `currentProgress` | `storedFood` |
| `progressPerTurn` | `foodDeposit` |
| `completionTurn` | `gameSave.turn + turnsRemaining` |

Visibility locations:

| UI | ETA visibility |
| --- | --- |
| City economy breakdown | `growth stored/growthCost • N turns • TX` |
| Selection details | Growth ETA flows through the same city-yield breakdown model |

Fallback:

| Situation | Label |
| --- | --- |
| `foodDeposit <= 0` | `stagnant` |
| Stored food already covers the cost | `ready` |

## What This System Does Not Do

ETA remains an informational layer and reads costs after `PaceBalance`. The
available modes are `standard60`, `normal90`, `long120`, and `unlimited`;
research, production, and growth show ETA that matches their real game pace.
