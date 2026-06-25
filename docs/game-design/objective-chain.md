# Objective Chain

This document describes the current staged-objective contract. The objective
chain should give the player direction after the early game without building a
full quest book yet.

## UX Goal

The objective panel should always answer "what should I do next?". After the
second city it must not go empty, because the player would lose direction
before pace, domination, and long-form strategy take over.

## Phases

| Phase | Role | Example goals |
| --- | --- | --- |
| `foundation` | First decisions and inline onboarding | research, capital, exploration, worker, first improvement, second city |
| `expansion` | Turns the start into a working economy | first building, three improvements, third city |
| `pressure` | Moves from development into strategic contact | reveal region, build defensive force |
| `endgame` | Urgent victory and defense goals near finish countdown | hold/break domination hold, hold or overtake score before cap |

## Objective Track

Objective definitions have `track`:

| Track | Meaning |
| --- | --- |
| `guidance` | Goals shown in the objective panel as player guidance steps |
| `strategic` | Urgent victory goals or threats that can appear above normal guidance |

The HUD still guides mainly through `guidance`, but when domination hold is
active or score cap is close, it prepends one `strategic` goal. The victory HUD
/ status remains the source of detailed numbers; the strategic objective
translates the nearest intent: hold, break, overtake, or protect the lead.

## Text and Micro-Tooltips

Core objectives store only mechanical data:

| Field | Balance meaning |
| --- | --- |
| `id` | Stable objective key used by tracker and presentation |
| `phase` | Game stage that helps sort goals and label them in UI |
| `track` | Distinguishes guidance goals from future strategic/victory goals |
| `targetValue` | Threshold for pace and difficulty balance |
| `tone` | Goal category for HUD color/iconography |
| `targetScaling` | Whether the target can be scaled by pace profile |

Player-facing text stays outside the domain. `GameObjectiveLabels` maps
`GameObjectiveId` to localized title/hint/reward/micro-tooltip from ARB. This
lets balance change in core without touching copy, and lets copy iterate
without mixing with domain logic.

A micro-tooltip is a short explanation of "why this matters", shown in the
panel near the info icon. It is not a full tutorial or quest book; it should
help the player understand the nearest objective on first contact.

## Active Objectives

`GameObjectiveTracker.activeObjectivesForPlayer(...)` calculates progress for
the whole guidance list, drops completed items, and returns the first 1-3 active
goals. If domination hold is active, the tracker first adds one strategic goal:

- `holdDomination` when the active player has their own hold countdown,
- `breakDominationHold` when a rival has the countdown.

When score cap is inside the critical final 5-turn window, the tracker can add
a score goal:

- `holdScoreLead` when the active player is the sole score leader,
- `overtakeScoreLeader` when the active player trails the leader or is tied for
  first and must break the tie.

Strategic objectives have priority because they are the most urgent end
condition. Domination hold has priority over score-cap pressure only when the
remaining hold can finish before or exactly at cap. If fewer turns remain to
score cap than to hold completion, the tracker shows the score goal because
that condition will actually decide the match. Own hold has priority over rival
hold when both entries exist in runtime state. Remaining panel slots are filled
with the next guidance goals.

## Score-Pressure Advice

Score objectives can have optional `GameObjectiveAdvice`. This is not an
automatic action or quest book, only a short hint in the objective panel naming
the score component where the player has the largest gap to the leader.

`ScorePressureAdvisor` compares the active player's `EmpireScoreBreakdown` with
the score leader and chooses the largest positive difference:

| Advice | Gap source | Meaning for the player |
| --- | --- | --- |
| `foundCity` | `cityScore` | Found or capture a city |
| `growPopulation` | `populationScore` | Accelerate city growth |
| `claimTerritory` | `territoryScore` | Increase controlled tiles |
| `constructBuilding` | `buildingScore` | Finish a building |
| `trainUnit` | `unitScore` | Train a quick unit or defend the lead |
| `unlockTechnology` | `technologyScore` | Finish a technology |
| `improveField` | `improvementScore` | Improve a tile |
| `collectGold` | `goldScore` | Close missing gold-to-score |
| `protectLead` | Active player is the sole leader | Do not give up cities and secure the nearest score gain |

When tied without a clear gap, the fallback is `trainUnit` because it is the
most direct small score gain without rebuilding the economy. Advice is passed
as an enum to UI; text remains in l10n.

The turn hint near `Action` uses the same advice only as text context. If the
nearest manual decision matches the advice, the hint becomes a short
`Goal: ...` message, for example score research, city building, worker field
improvement, or protecting the lead with a unit. This does not change the
`FocusNextPendingActionCommand` queue and does not choose production or movement
for the player.

The `Objectives` panel is the main location for score-pressure guidance. When
`holdScoreLead` or `overtakeScoreLeader` is active, the overlay shows a compact
breakdown below advice:

- `overtakeScoreLeader`: total score gap to the leader and up to three largest
  categories where the player is missing points,
- `holdScoreLead`: total margin over the highest-scoring rival and up to three
  categories that preserve the lead most.

The top of the `Objectives` panel shows a short active-state overview:

- pressure type: active goal, score pressure, lead defense, domination, or
  domination threat,
- title of the most important objective,
- quick numeric state: goal progress or score gap/margin.

The `Objectives` button in the left menu signals the same state before opening
the panel: normal guidance shows the number of active goals, score pressure
uses the `PTS` badge, and domination pressure uses the `DOM` badge. The tooltip
shows pressure type, most important title, progress, and goal count. Badge color
is static: the normal counter remains gold, `PTS` uses a cool score accent, and
`DOM` uses a warning red accent without animation.

This breakdown is calculated from the same `EmpireScoreBreakdown` that feeds
objectives, victory HUD, and outcome detection. The left menu uses shared
`HudScorePressureContext`, so there is no separate logic or drift between top
HUD, objective summary, and menu panel.

The `Objectives` panel has no separate execution button. The bottom `Action`
button remains the only place that leads to the next manual decision: unit
movement, research, production, field improvement, or city founding. The player
therefore has one stable place for executing steps, while `Objectives` explains
why the step matters for score pressure. When the hint starts with `Goal:`, the
`Action` button receives a small goal marker and a tooltip with the full nearest
step description.

When the `Action` hint is associated with score objective advice, the HUD passes
optional `preferredObjectiveAdvice` to `FocusNextPendingActionCommand`. The
reducer still does not execute actions for the player or choose production
automatically, but the first focus looks for a decision matching the advice:
worker for `improveField`, settler for `foundCity`/`claimTerritory`, combat
unit for `trainUnit` and `protectLead`, city without production for
production/economy advice, or research selection for `unlockTechnology`. If the
currently selected action already matches advice, the next `Action` click keeps
normal cycling through available turn decisions.

Order is intentionally linear:

1. Foundation first, because it teaches the basic loop.
2. Expansion next, because the player now has a capital and second city.
3. Pressure next, because the player should start thinking about map, borders,
   and rivals.

The compatibility wrapper `activeEarlyGameObjectivesForPlayer(...)` remains for
tests and places that only need the old foundation subset.

## Pace Scaling

The objective tracker accepts `PaceBalance`. By default it uses
`PaceBalance.unlimited`, so old call sites and tests keep current targets. The
HUD passes pace from `GameSave.matchRules.paceBalance`, so a 60-minute match
changes not only costs but also distance to flexible goals.

Target scaling is deterministic:

```text
scaledTarget = max(1, ceil(baseTarget * objectiveTargetMultiplier))
```

Only objectives marked `targetScaling = pace` are scaled. Goals with numbers in
copy or in the ID semantics remain `fixed` so the UI does not say "third city"
when target is `2/2`, or "three tiles" when target is `2/2`.

| Profile | Objective target multiplier | Example |
| --- | ---: | --- |
| `unlimited` | x1.00 | `exploreNearby` 28 |
| `standard60` | x0.85 | `exploreNearby` 24 |
| `normal90` | x0.92 | `exploreNearby` 26 |
| `long120` | x1.00 | `exploreNearby` 28 |

## Target Scaling Policy

| ID | Scaling | Reason |
| --- | --- | --- |
| `chooseResearch` | fixed | Binary decision |
| `foundCapital` | fixed | Binary milestone |
| `exploreNearby` | pace | Text is flexible and 60-minute maps should not require the same reach |
| `queueWorker` | fixed | Binary production/ownership check |
| `improveFirstHex` | fixed | Binary first improvement |
| `foundSecondCity` | fixed | Copy and mechanics mean a specific second city |
| `buildFirstBuilding` | fixed | Binary first building |
| `improveThreeHexes` | fixed | Copy contains the number "three" |
| `foundThirdCity` | fixed | Copy and mechanics mean a specific third city |
| `exploreRegion` | pace | Text is flexible and should fit shorter matches |
| `buildCombatForce` | pace | Text talks about defensive strength, not a fixed unit count |
| `holdDomination` | fixed by `VictoryRules.dominationHoldTurns` | Target comes from match victory rules |
| `breakDominationHold` | fixed by `VictoryRules.dominationHoldTurns` | Shows the rival countdown pace without changing victory threshold |
| `holdScoreLead` | fixed by pressure window | Target is the final 5 turns to score cap; progress shows sustained pressure countdown |
| `overtakeScoreLeader` | fixed by current score leader | Target is score leader + 1 so the player sees what is missing for a sole lead |

## Current Objectives

| ID | Phase | Base target | Standard60 target | Scaling | Metric |
| --- | --- | ---: | ---: | --- | --- |
| `chooseResearch` | foundation | 1 | 1 | fixed | Active or unlocked research |
| `foundCapital` | foundation | 1 | 1 | fixed | Player city count |
| `exploreNearby` | foundation | 28 | 24 | pace | Discovered fog-of-war hexes |
| `queueWorker` | foundation | 1 | 1 | fixed | Worker exists or is in production queue |
| `improveFirstHex` | foundation | 1 | 1 | fixed | Improvements built by player cities |
| `foundSecondCity` | foundation | 2 | 2 | fixed | Player city count |
| `buildFirstBuilding` | expansion | 1 | 1 | fixed | Buildings built in player cities |
| `improveThreeHexes` | expansion | 3 | 3 | fixed | Improvements built by player cities |
| `foundThirdCity` | expansion | 3 | 3 | fixed | Player city count |
| `exploreRegion` | pressure | 70 | 60 | pace | Discovered fog-of-war hexes |
| `buildCombatForce` | pressure | 3 | 3 | pace | Player non-civilian units |
| `holdDomination` | endgame | victory hold turns | profile-specific | rules | Own consecutive turns above domination threshold |
| `breakDominationHold` | endgame | victory hold turns | profile-specific | rules | Rival consecutive turns above domination threshold |
| `holdScoreLead` | endgame | 5 | 5 | pressure window | Turns of sustained score pressure in the final window |
| `overtakeScoreLeader` | endgame | leader score + 1 | leader score + 1 | dynamic | Active player's score toward overtaking the leader |

## UI Copy v1

| ID | Title | Micro-tooltip |
| --- | --- | --- |
| `chooseResearch` | Choose research | Research turns each next turn into a concrete development direction. |
| `foundCapital` | Found the first city | The capital starts production, growth, and territorial reach. |
| `exploreNearby` | Explore nearby | Early scouting helps choose city sites and avoid blind movement. |
| `queueWorker` | Queue a worker | A worker turns good tiles into lasting resource growth. |
| `improveFirstHex` | Improve the first tile | The first improvement shows which city economy should grow fastest. |
| `foundSecondCity` | Found a second city | The second city increases production tempo without waiting on one capital. |
| `buildFirstBuilding` | Build the first building | Buildings stay in the city and scale over many turns. |
| `improveThreeHexes` | Improve three tiles | Three improvements form a stable base for military, research, or expansion. |
| `foundThirdCity` | Found a third city | A third city creates another development front and more decisions each turn. |
| `exploreRegion` | Explore the region | A wider map reveals rivals, strategic resources, and safer borders. |
| `buildCombatForce` | Build a defensive force | Constant cover protects settlers, workers, and developed cities. |
| `holdDomination` | Hold domination | Domination ends the game before or at score cap if you hold enough map control long enough. |
| `breakDominationHold` | Break rival domination | If the rival falls below the control threshold, their hold turns reset to zero. |
| `holdScoreLead` | Hold the lead | Score cap decides the match when the turn limit expires, so the point lead must survive to the end. |
| `overtakeScoreLeader` | Overtake the score leader | Build cities, population, technologies, units, and improvements; tied score cap ends in a draw. |

## What This System Does Not Do

- It does not grant mechanical rewards for completing objectives yet.
- It does not replace the victory HUD; a strategic objective is only a short,
  prioritized translation of the active hold countdown.
- It does not fully parameterize copy by numeric targets yet. Goals such as
  `improveThreeHexes` remain fixed until dynamic copy or new flexible objective
  IDs exist.
