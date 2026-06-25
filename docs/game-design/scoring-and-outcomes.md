# Scoring and Outcomes

This document describes the current game-ending model and the first score
fallback for presets with turn limits.

## Outcome Conditions

| Condition | When it occurs | Winner |
| --- | --- | --- |
| `ongoing` | Game has not met an end condition yet | none |
| `conquest` | Only one roster player still has units or cities on the map | Last surviving player |
| `domination` | A player controls the required percent of valid tiles and holds it for the required turns | Player with sustained map control |
| `cultural` | A player stores the required number of artifacts in cities and holds that state for the required turns | Player with sustained cultural progress |
| `score` | `VictoryRules.turnLimit` is reached and `scoreFallbackEnabled == true`; one player has the highest score | Player with highest score |
| `draw` | `VictoryRules.turnLimit` is reached, but multiple players share the highest score | none |

## Domination Victory

Domination measures real territorial control, not the number of remaining
enemies. The condition is evaluated at the end of a full turn, after combat,
economy, and movement reset.

| Parameter | Source | Meaning |
| --- | --- | --- |
| Valid domination tiles | `MapData.tiles` with passable movement cost | Percent denominator; ocean, lake, and mountain do not count |
| Controlled tiles | Unique `GameCity.territoryHexes` owned by the player | City center + controlled city hexes on valid tiles |
| Control percent | `controlledTiles / validTiles * 100` | Current percent of map controlled by the player |
| Required percent | `VictoryRules.dominationControlPercent` | Threshold required to start/keep the streak |
| Hold turns | `GameRuntimeState.dominationHoldTurnsByPlayerId` | Consecutive full turns where the player was at or above threshold |
| Required hold | `VictoryRules.dominationHoldTurns` | Turns required to hold the threshold, based on pace profile |

The streak grows only when a player ends a full turn at or above the threshold.
Dropping below the threshold resets the streak to zero. Maps without valid
domination tiles do not increase streaks and cannot end by domination.

Domination is checked after conquest and before score fallback. This keeps the
last surviving player winning by `conquest`, while a turn-limited game can end
through an active map-control goal before reaching the score cap.

| Pace | Domination percent | Hold turns |
| --- | ---: | ---: |
| Standard 60 | 45% | 10 |
| Normal 90 | 47% | 12 |
| Long 120 | 50% | 14 |
| Unlimited | 60% | 5 |

`standard60`, `normal90`, and `long120` are tuned for the current city-control
geometry: cities do not take the whole map, so capped games need a lower
threshold for domination to become an active pressure path before score cap.

Development simulation output changes often and is not a balance contract.
Re-run `dart run tool/economy_simulation.dart` from `packages/aonw_core/`
before quoting current turn numbers in release notes or design discussions.

Timed presets use longer hold windows than unlimited so domination is earned by
sustained control rather than one short border spike.

`Unlimited` stays more demanding because it has no turn-limit pressure.

## Domination Warning Cadence

The HUD warns only about rivals of the active player and only when the map has
valid domination tiles. The warning is pace-aware: shorter games require fewer
hold turns from a rival, so the alarm appears earlier than in unlimited.

| Pace | Warning before threshold | Warning after threshold | Imminent |
| --- | --- | --- | --- |
| Standard 60 | no pre-threshold warning | no early warning | at most 1 hold turn remains |
| Normal 90 | no pre-threshold warning | no early warning | at most 1 hold turn remains |
| Long 120 | no pre-threshold warning | no early warning | at most 1 hold turn remains |
| Unlimited | no pre-threshold warning | no early warning | at most 1 hold turn remains |

These thresholds are calculated from
`DominationProgressEntry.requiredHoldTurns`, not from the preset name. Custom
rules or future variants therefore keep a readable relationship: the shorter
the hold window, the sooner the HUD warns.

## Score Fallback

Score fallback is deterministic and resolves games with a timed preset or
manual turn limit. Unlimited does not use score fallback.

| Component | Weight | Balance note |
| --- | ---: | --- |
| City | 40 per city | Basic expansion measure |
| Population | 12 per population | Rewards city quality, not only settler spam |
| Territory | 3 per controlled city hex, including center | Light reward for border expansion |
| Building | 8 per building | Rewards economic investment |
| Technology | 18 per unlocked technology | Rewards long-term development |
| Field improvement | 5 per improvement assigned to a city | Rewards worker economy |
| Gold | `min(gold ~/ 50, 200)` | Small capped bonus, without stockpiling dominance |
| Map objectives | Objective victory points controlled by the player | Rewards strategic map control when a map defines objectives |
| Units | Depends on type | Reflects army strength and defense potential |

When score fallback is active and the turn limit is at most 5 turns away, the
objective panel can show a strategic score goal:

- `Hold score lead` when the active player is the sole score leader,
- `Overtake score leader` when the active player trails the leader or is tied
  for first and needs to break the tie.

The score objective does not change scoring formula or draw rules. It uses the
same points from `EmpireScoreCalculator` that are shown in the victory HUD and
used by `GameOutcomeDetector`. Domination hold has higher communication
priority only when it can decide the game before or exactly at score cap. If
the remaining hold is longer than the turns to cap, the objective panel shows
score pressure because score is the condition that will actually decide the
match.

In the final score-cap window, the objective panel can also show one advice
line. `ScorePressureAdvisor` compares the active player's breakdown with the
leader and points at the largest scoring gap: city, population, territory,
building, units, technologies, improvements, or gold. When the active player is
the sole leader, advice becomes `protectLead`, a reminder not to give up cities
and to secure the nearest score growth.

The `Objectives` panel expands the same state into a mini score breakdown. When
chasing the leader, it shows the total gap and up to three largest categories
where points are missing. When leading, it shows the margin over the highest
scoring rival and the categories that preserve it most. This remains a
communication layer: it does not change score weights, draws, outcomes, or
action selection.

## Unit Weights

| Unit | Score |
| --- | ---: |
| commander | 30 |
| warrior | 15 |
| archer | 17 |
| settler | 18 |
| worker | 12 |
| merchant | 14 |
| scout | 10 |
| spearman | 18 |
| cavalry | 24 |
| catapult | 25 |
| heavyInfantry | 30 |
| fieldCannon | 35 |
| rifleman | 38 |
| tank | 50 |
| scoutShip | 20 |
| warship | 40 |
| reconPlane | 36 |

Each unit also receives `experiencePoints ~/ 5`.

## Resolution Rules

- Conquest takes priority over domination, cultural victory, and score cap.
- Domination takes priority over cultural victory and score cap.
- Cultural victory takes priority over score cap.
- Score cap is checked only when `turn >= turnLimit`.
- If the highest score is tied, the outcome is `draw`.
- There is no tie-breaker yet because this stage avoids hidden rules and keeps
  balance easier to test.

## HUD Status

The top HUD strip shows a small game-goal status:

| View | Meaning |
| --- | --- |
| `CONQUEST · NO LIMIT` | Game has no turn limit; the main goal is eliminating rivals |
| `DOM X% · LEADER H/RT` | Map-control leader has `X%` and has held threshold for `H` of `R` required turns |
| `DOM X% · LEADER / P%` | Map-control leader has `X%`, but is still below threshold `P%` |
| `HERITAGE · N/R ARTIFACTS` | Cultural leader has stored `N` of `R` required artifacts |
| `HERITAGE · H/R TURNS` | Cultural leader is holding the Great Heritage Exhibition for `H` of `R` required turns |
| `SCORE XT · SCORE LEADER` | Turn-limited game; `X` is turns remaining to score fallback |
| `SCORE CAP · SCORE LEADER` | Turn limit has been reached; score decides the outcome |
| `DRAW N` | Multiple players share the highest score `N` |

The pill shows score first when a score cap is imminent. Cultural and
domination pressure are then ordered by the same practical finish race used by
the outcome rules: domination wins when it is already at threshold and cultural
progress does not have the full artifact set, and active cultural progress only
comes first when it can finish in fewer remaining hold turns. In portrait mode,
the pill condenses so it does not cover the rest of the menu. With 5 or fewer
turns to the limit, the HUD prioritizes score cap so the player sees the
immediate fallback. The domination pill becomes a warning according to
`DominationWarningPolicy`: current presets warn only at imminent hold.

Clicking the pill opens a game-goal popup that expands domination pressure into
explicit fields:

| Popup field | Meaning |
| --- | --- |
| Leader | Player with the highest current map-control percent |
| Control | `current% / required%`; accent color means the leader is already above threshold |
| Hold | Hold-turn streak; below threshold shows `below threshold`, above threshold shows `H/R turns` and remaining turns |
| You | Visible when the active player is not the leader; shows their own progress toward threshold |
| Pressure | Short interpretation from the active player's perspective: what to hold, finish, or break |
| Fallback | Score-cap status when the game has turn limit and score fallback |

The popup tooltip combines the same state into text: current leader, threshold,
hold turns, active player's goal, and any rival warning. This makes capped
presets show a readable reason for domination pressure several turns before the
end.

## Domination Threshold Event

The end of a full turn emits `DominationThresholdReachedEvent` when a player
moves from `0` hold turns to `1+` hold turns. This means the player is above the
required map-control threshold and the hold countdown has started.

| Event field | Meaning |
| --- | --- |
| `playerId` | Player who crossed the domination threshold |
| `controlPercent` | Current map-control percent at event time |
| `requiredControlPercent` | Required threshold from `VictoryRules` |
| `holdTurns` | New hold-streak value, usually `1` at countdown start |
| `requiredHoldTurns` | Turns required to hold the threshold for victory |

The event is public strategic pressure, like the victory HUD status. Locally
and on the server it is created after combat, economy, movement reset, and
recalculation of `dominationHoldTurnsByPlayerId`, but before `TurnEnded`
events. In the HUD:

- if the event concerns the active player, the toast is opportunity-oriented:
  `Domination started`,
- if it concerns a rival, the toast is threat-oriented: `Rival above
  threshold`,
- the event enters the activity log and has a longer critical hold so the
  player does not miss the countdown start,
- tapping the notification can focus the map on the first city or unit owned by
  the player who created the pressure,
- the objective panel then shows a strategic goal: `Hold domination` for the
  active player above threshold or `Break rival domination` when an opponent has
  the hold countdown.

## End-Game Feedback

After detecting a completed game, the HUD shows a blocking outcome overlay. The
goal is a clear match close: the player immediately knows whether they won,
lost, or drew, which condition decided the game, and what the main outcome
metric was.

The overlay is calculated from the same source as victory status:

| Data | Source | Usage |
| --- | --- | --- |
| `GameOutcome` | `GameOutcomeDetector.evaluate(...)` | Decides whether the game is complete and by which condition |
| Player perspective | Active player from save/runtime/player control | Title `Victory`, `Defeat`, `Draw`, or `Game over` |
| Winner label | `GameSave.players` roster | Winner name in summary |
| Score rows | `GameOutcome.scoreByPlayerId` | Breakdown for `score` and `draw` |
| Domination progress | `DominationProgressCalculator` | Map percent, hold turns, and threshold for `domination` |
| Cultural progress | `CulturalVictoryProgressCalculator` | Stored artifacts and exhibition hold for `cultural` |

| Condition | Winner-perspective title | Loser-perspective title | Overlay metrics |
| --- | --- | --- | --- |
| `conquest` | `Victory` | `Defeat` | Winner, elimination condition |
| `domination` | `Victory` | `Defeat` | Winner, map control, hold, threshold |
| `cultural` | `Victory` | `Defeat` | Winner, stored artifacts, hold turns |
| `score` | `Victory` | `Defeat` | Sorted player scores |
| `draw` | `Draw` | `Draw` | Sorted player scores |

When the overlay is visible:

- the game does not show hot-seat handoff as the next ongoing step,
- AI autopilot does not try to execute more turns,
- the only action in the current scope is `Back to menu`, which saves camera
  state and returns through the standard `onClose`.

A full post-match timeline, play-again with copied configuration, and detailed
statistics remain outside the current scope. The minimal overlay first closes
the loop that "the match has an outcome" and provides a stable contract for
future work.

## Open Balance Questions

- Should technologies give more points in longer games?
- Should settlers score lower after mid-game to prevent producing them only for
  score?
- Should score include control percent as a tie-breaker or scoring component?
- After larger-map tests, should capped preset thresholds depend on map size or
  player count?
