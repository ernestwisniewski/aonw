# Balance Telemetry

This document describes the balance-telemetry contract. The goal is not a
dashboard or external analytics yet. The goal is a lightweight, deterministic
report that can run in tests, development simulations, and playtests to show
whether the first 20-40 turns have healthy pace.

## Main Questions

| Question | Metric |
| --- | --- |
| Does the player get the first technology plan quickly? | `firstTechnologyTurn` |
| Does the city stop being passive? | `firstBuildingTurn` |
| Does expansion happen at a reasonable time? | `secondCityTurn` |
| Does the map create contact and tension? | `firstContactTurn` |
| Does combat appear as a real session moment? | `firstCombatTurn` |
| Does the player skip turns without meaningful change? | `deadTurnRuns`, `longestDeadTurnStreak` |
| Does the match end in the intended rhythm? | `victoryTurn`, `victoryCondition` |
| Does score-pressure `Action` lead to a readable decision type? | `objectiveActionAdviceCounts`, `objectiveActionTargetCounts` |

## Model

Telemetry works on a sequence of `BalanceTelemetryTurnSample`.

| Field | Meaning |
| --- | --- |
| `turn` | Snapshot turn number |
| `state` | `PersistentGameState` after that turn or simulation step |
| `events` | Optional domain events from that turn |
| `meaningfulCommandsByPlayerId` | Count of player commands that were real decisions, excluding submit/end turn alone |
| `objectiveActionByPlayerId` | Optional objective-aware `Action` sample: active `GameObjectiveAdvice` and the manual decision type routing would lead to |
| `outcome` | Optional game outcome for detecting `victoryTurn` |

This contract intentionally sits outside the save file. Snapshots can come from
tests, AI simulations, or a future playtest tool.

## Milestones

| Metric | When recorded |
| --- | --- |
| `firstTechnologyTurn` | First snapshot where the player has at least one unlocked technology |
| `firstBuildingTurn` | First snapshot where any player city has a building |
| `secondCityTurn` | First snapshot where the player has at least two cities |
| `firstContactTurn` | First snapshot where the player's visible fog-of-war state includes an enemy unit or city |
| `firstCombatTurn` | First turn with a combat event involving the player |
| `victoryTurn` | First snapshot with a completed `GameOutcome` |

## End-Pace Metrics

Telemetry also has a final pace snapshot calculated from the last
development-simulation turn, even when outcome appeared earlier. This allows
comparing "how much game happened by the cap" rather than only "who won".

| Player report field | Meaning |
| --- | --- |
| `finalTechnologyCount` | Number of unlocked technologies in the last snapshot |
| `finalSciencePerTurn` | Science/turn in the last snapshot, including research project output |
| `finalCityCount` | Number of cities in the last snapshot |
| `finalUnitCount` | Number of units in the last snapshot |
| `finalGold` | Gold reserve in the last snapshot |
| `finalNetGoldPerTurn` | Final net gold per turn |

`BalanceTelemetryTurnSample.endPaceByPlayerId` is optional. Without it, the
analyzer still calculates technologies, cities, and units from game state, but
turn-economy metrics such as science/turn and net gold/turn remain empty.

## Dead-Turn Metric

A dead turn is a player turn with no visible meaningful decision or progress.
The first snapshot is not counted as dead because there is no previous point of
comparison.

A turn is not dead if any condition is true:

| Condition | Examples |
| --- | --- |
| `meaningfulCommandsByPlayerId[playerId] > 0` | Movement, research choice, production, attack |
| Domain event assigned to the player | Building built, technology unlocked, combat, worker job completed |
| Snapshot shows new progress | More discovered hexes, new unit, new city, new building, population growth, new improvement, unit movement |

Passive science income alone does not count as meaningful change. This catches
cases where the player only advances turns while research slowly increments.

## Objective-Action Diagnostics

Telemetry can count where objective-aware `Action` routes during the
score-pressure window. This is diagnostics, not a new mechanic: it does not
execute decisions for the player and is not written to the save.

| Player report field | Meaning |
| --- | --- |
| `objectiveActionAdviceCounts` | How often a given `GameObjectiveAdvice` was active, for example `trainUnit`, `collectGold`, `unlockTechnology` |
| `objectiveActionTargetCounts` | How often routing pointed to a manual decision type: `unit`, `cityProduction`, `research`, or `none` |

The CSV generator adds per-turn columns `objective_action_advice` and
`objective_action_target`. Empty values mean the turn was not in the
score-pressure window. In the markdown report, the `Objective Action` column
shows the aggregate for the simulation's main player.

The shared diagnostic contract is
`BalanceTelemetryObjectiveActionDiagnostics.scorePressureSamplesFor(...)`. The
helper calculates score through `EmpireScoreCalculator`, chooses advice through
`ScorePressureAdvisor`, and only then classifies the manual-action target. The
test fixture covers a player chasing the leader through production, research,
and economy gaps so the report is not validated only for `protectLead -> unit`.

The report generator adds a `Score Chaser Objective Action` section and
`score-chaser-objective-actions.csv`. This is a controlled fixture, not a full
AI run: states are built manually, but the result uses the same production code
paths as the game (`EmpireScoreCalculator`, `ScorePressureAdvisor`, and the
diagnostic helper). The section should always confirm that a player chasing the
leader sees:

| Scenario | Expected advice | Expected target |
| --- | --- | --- |
| Production gap | `constructBuilding` | `cityProduction` |
| Research gap | `unlockTechnology` | `research` |
| Economy gap | `collectGold` | `cityProduction` |

The generator also has a `Score Comeback Telemetry` section and
`score-comeback-telemetry.csv`. This controlled six-snapshot fixture covers the
final `standard60` window from T55 to T60. It passes through
`BalanceTelemetryAnalyzer`, has `victoryTurn = T60`, `victoryCondition =
score`, and aggregates per-turn `Objective Action` in the same way as the main
preset report.

| Fixture range | Expected result |
| --- | --- |
| T55-T56 | Active player chases through `constructBuilding -> cityProduction` |
| T57-T58 | Active player chases through `unlockTechnology -> research` |
| T59-T60 | Active player chases through `collectGold -> cityProduction` |

## Tuning Targets

Default `BalanceTelemetryTuningTargets.standard` thresholds are warnings for
unlimited mode or tests without a profile. Timed pace profiles have their own
targets.

| Parameter | Default | Interpretation |
| --- | ---: | --- |
| `firstTechnologyMaxTurn` | 10 | First technology later than T10 is suspicious |
| `firstBuildingMaxTurn` | 18 | First building later than T18 means city pacing is slow |
| `secondCityMaxTurn` | 24 | Second city later than T24 can hurt expansion |
| `firstContactMaxTurn` | 28 | No contact by T28 means the map is too empty or too large |
| `firstCombatMaxTurn` | 40 | No combat by T40 means contact is not becoming real pressure |
| `dominationThresholdMaxTurn` | 0 | Optional target; `0` means no warning for unlimited mode |
| `maxDeadTurnStreak` | 2 | Three empty turns in a row is a warning |
| `finalTechnologyMinCount` / `finalTechnologyMaxCount` | 0 / 0 | Optional final technology-count range |
| `finalScienceMinPerTurn` / `finalScienceMaxPerTurn` | 0 / 0 | Optional final science/turn range |
| `finalCityMinCount` / `finalCityMaxCount` | 0 / 0 | Optional final city-count range |

| Preset | First tech | First building | Second city | First contact | First combat | Dom threshold | Notes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `standard60` | T5 | T20 | T16 | T24 | T36 | - | Short game has fast research/production but still guards first contact |
| `normal90` | T6 | T21 | T20 | T28 | T48 | - | Default single player; windows between 60 and 120 minutes |
| `long120` | T6 | T23 | T24 | T32 | T60 | - | Longer match has more room for infrastructure; conquest/domination can still close before score cap |

| Preset | Final techs | Final science/turn | Final cities | Notes |
| --- | ---: | ---: | ---: | --- |
| `standard60` | 15-42 | 6-70 | 3-6 | Guardrail for fast score cap |
| `normal90` | 18-48 | 8-70 | 3-6 | Guardrail for the intermediate profile |
| `long120` | 22-52 | 10-70 | 3-5 | Longer profile has higher tech/science minimums |

## AI Difficulty

Single player passes the selected difficulty to each `AiPlayer`. Profiles are
centralized in `AiDifficultyProfile`:

| Level | Strategic behavior | MCTS |
| --- | --- | --- |
| `easy` | Lowest aggression, highest opportunistic-war threshold, most cautious attacks | Lowest time, search-step, depth, and candidate budgets |
| `normal` | Default single player; still more cautious than the old AI | Intermediate budgets between `easy` and `hard` |
| `hard` | More aggression and lower war thresholds than `normal`, but still below old AI | Budgets below `veryHard` |
| `veryHard` | Current AI without reductions: identity weights, current risk tolerance, and old war behavior | Current standard MCTS budgets |

In practice, lower levels reduce `aggression`, increase thresholds for military
mode and opportunistic war, require a larger army reserve before opening war,
and lower tolerance for risky attacks.

## Findings

The analyzer returns `BalanceTelemetryFinding` with codes stable for tests:

| Code | Meaning |
| --- | --- |
| `late_first_technology` | First tech is late or missing after the target window |
| `late_first_building` | First building is late or missing after the target window |
| `late_second_city` | Second city is late or missing after the target window |
| `late_first_contact` | First contact is late or missing after the target window |
| `late_first_combat` | First combat is late or missing after the target window |
| `late_domination_threshold` | Player did not cross the domination threshold inside the capped preset target window |
| `dead_turn_streak` | Longest dead-turn run exceeded the target |
| `low_final_technology_count` / `high_final_technology_count` | Final technology count is outside guardrails |
| `low_final_science_per_turn` / `high_final_science_per_turn` | Final science/turn is outside guardrails |
| `low_final_city_count` / `high_final_city_count` | Final city count is outside guardrails |

When a match ends by `conquest` or `domination`, final city-count guardrails are
suppressed because conquered cities are part of the victory condition. Low
final technology and science floors are also suppressed for that completed
military outcome; high technology and science ceilings still report runaway.

## Out of Scope

| Out of scope | Reason |
| --- | --- |
| UI dashboard | A stable data contract comes first |
| Persisting telemetry in saves | Debug data should not pollute save files |
| External analytics | Later, if a real playtest pipeline exists |
| Automatic rebalance | Telemetry should point at problems, not change rules itself |
| Exact UI command classification | The sample currently accepts a prepared meaningful-command count |

## Development Simulation Generator

Telemetry is connected to `EconomySimulation.run()` and
`packages/aonw_core/tool/economy_simulation.dart`.

The generator runs the current simulation code for presets and shows current
targets, final pace, findings, `firstCombatTurn`, domination progress, and
outcome:

| Preset | Game length |
| --- | --- |
| `standard60` | `GameLengthConfig.standard60` |
| `normal90` | `GameLengthConfig.normal90` |
| `long120` | `GameLengthConfig.long120` |

Do not maintain "current output" by hand in this document. The generated
markdown report is the source for current turn numbers, findings, final pace,
and outcomes. Balance changes can move those values significantly even when the
telemetry contract is unchanged.

The headline preset row uses `player_1` for score-cap outcomes and the winner
for non-score completed outcomes so domination columns describe the same player
that ended the match. The `Preset Player Findings` section always lists each
player separately.

When a release note or design review needs concrete numbers, regenerate the
report and cite the generated file path and date:

```bash
cd packages/aonw_core
dart run tool/economy_simulation.dart --out ../../build/reports/ai-telemetry
```

Generated runs can produce different outcomes as AI, costs, map fixtures, and
victory thresholds change. Treat those numbers as output artifacts for that run
only; do not edit them into this contract as stable expectations.

The generator also runs an active AI rival. Both sides get movement reset,
strategy planning, economy, and fog of war. The fixture map is intentionally
tighter than a normal map. It measures first-contact and pressure rhythm in
development simulation, not a full playtest of a large map.

Default output goes to:

```text
build/reports/ai-telemetry/
```

This is intentionally a generated directory, not documentation with manually
maintained CSV or copied tables. The source of truth is generator code and
tests, and the report can be reproduced after every balance change:

```bash
cd packages/aonw_core
dart run tool/economy_simulation.dart
```

Optionally pass another directory:

```bash
dart run tool/economy_simulation.dart --out ../../build/reports/custom-ai-telemetry
```

The generator has smoke test `test/ai/economy_simulation_tool_test.dart`. The
test runs the CLI into a temporary directory and checks that the report still
contains presets `standard60`, `normal90`, `long120`, `Final pace` / `End
targets`, the `Score Chaser Objective Action` section, the `Score Comeback
Telemetry` section, and the required CSV files. The test is explicitly part of
the README core dev-check:
`(cd packages/aonw_core && dart analyze --fatal-infos && dart test)`.

## Ad Hoc Balance Smokes

After adding `FlatCityScienceEffect` to selected standard buildings related to
knowledge, medicine, mapping, and information storage, a small `balance_pass`
smoke run checked whether new infrastructure science breaks science/turn
guardrails:

```bash
cd packages/aonw_core
dart run tool/balance_pass.dart --games=2 --turns=60 --difficulty=normal --seed=7310 --primary-civ=poland --civs=germany,netherlands,japan --out=/tmp/flame_4x_selected_building_science_smoke
```

Result:

| Run | Crashes | Rejected commands | Highest average science/turn | Notes |
| --- | ---: | ---: | ---: | --- |
| 2 games, seed 7310 | 0 | 10 | 6.0 | Highest player: Japan, 3 cities, 12 techs; rejected commands are repeated `attack_not_resolved`, not research/production |

This does not replace official preset targets, but it locally confirms that the
selective science-building list and per-city diminishing returns do not create
an immediate science runaway in a 60-turn smoke.

## Next Steps

Most natural next steps:

1. Tune `PaceBalance`, early tech/building costs, and map warnings based on
   reports.
2. If reports remain consistently useful, connect the generator smoke test to a
   selected CI workflow.
3. Expand the comeback fixture with city/population/territory pressure if
   playtests show those categories are often the largest score gap.
