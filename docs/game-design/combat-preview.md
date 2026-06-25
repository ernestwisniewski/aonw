# Combat Preview

This document describes the combat-preview contract. The goal is to reduce
guessing before an attack without changing commands or the event log.

## Mechanical Goal

| Goal | Meaning |
| --- | --- |
| Decision before click | The player sees the predicted result before confirming the attack. |
| Combat consistency | Preview uses the same `CombatResolver`, modifiers, and retreat rules as the real attack. |
| Lightweight HUD | Information appears in the attack-mode banner, with no modal and no map blocking. |
| No new state | Preview is not saved and creates no domain events. |
| Readable result | The player sees HP before/after, Attack vs Defense, and outcome: survival, retreat, or death. |

## When Preview Is Visible

| Condition | Requirement |
| --- | --- |
| Mode | Active `PendingAttackTargeting` |
| Attacker | Exists, belongs to the active player, has movement, and is not working |
| Target | Visible enemy unit in attacker range |
| Combat mode | `CombatResolutionMode.instant` |
| Fog of war | Target must be visible through `activePlayerVisibility.canSeeDynamicAt` |

If the conditions are not met, the attack banner stays in instruction mode
without a prediction.

## Preview Target Selection

The first version shows a prediction for the nearest visible enemy in range.
This is an informational target for the player in attack mode, not an automatic
command suggestion.

| Order | Tie-break |
| --- | --- |
| 1 | Lowest hex distance |
| 2 | Lower column |
| 3 | Lower row |
| 4 | Lexicographically lower `unit.id` |

This selection is deterministic. In the future it can be expanded with a
hover/tap target or a preferred map-inspection target.

## Calculation Model

Preview builds the same data needed by a real attack:

| Element | Source |
| --- | --- |
| Base stats | `UnitCombatStats.derive` |
| Attacker modifiers | `CombatModifierCollector.forAttacker` |
| Defender modifiers | `CombatModifierCollector.forDefender` |
| Current HP | `UnitCombatHealth.currentHp` |
| Possible retreat | `CombatRetreatResolver.destination` |
| Result | `CombatResolver.resolve` |
| Seed | `CombatRng.fromTurn(turn, attackerId, defenderId)` |

Preview does not execute `AttackHexCommand`, spend movement, or change
`GameState`.

## HUD Data

| Field | Meaning |
| --- | --- |
| Badge | Predicted defender damage, for example `-4 HP`, or `KO` |
| Outcome | `defender dies`, `defender retreats`, `defender survives`, or attacker death in retaliation |
| Target line | Defender HP before/after and `Attack X vs Defense Y` |
| Attacker line | Retaliation damage, HP before/after, and retaliation stats or `no retaliation` |

Example:

| HUD | Meaning |
| --- | --- |
| `Outcome: defender survives` | Attack will not kill the target |
| `Target: HP 10->6/10, Attack 6 vs Defense 2 (-4)` | Defender survives with 6 HP |
| `Retaliation: Attack 4 vs Defense 3 (-2), HP 10->8/10` | Attacker will take retaliation |
| `Retaliation: none (range 2/2)` | Ranged attack will not trigger melee retaliation |

## Balance Parameters That Affect Preview

Preview has no separate balance parameters. It reacts to the same values as
combat:

| Parameter | Where | Effect |
| --- | --- | --- |
| `unitBaseStats.attack` | `CombatRuleset` | Damage dealt by the unit |
| `unitBaseStats.defense` | `CombatRuleset` | Incoming damage reduction |
| `unitBaseStats.hp` | `CombatRuleset` | Max HP and survival threshold |
| `unitBaseStats.range` | `CombatRuleset` | Attack range and no melee retaliation for range > 1 |
| `varianceRange` | `CombatRuleset` | Random damage adjustment range |
| `retreatThresholdPercent` | `CombatRuleset` | Threshold below which the defender can retreat if it survives the hit |
| `defendedCityDefenseBonus` | `CombatRuleset` | Defense bonus in city garrison |
| Terrain modifiers | `CombatRuleset.terrainStatModifiers` | Local stat bonus/penalty |
| Technology effects | `TechnologyRuleset` | Global army and city-defense bonuses |
| Veterancy | `UnitVeterancyRules` | Experience bonuses |

## Out of Scope

| Out of scope | Reason |
| --- | --- |
| Full unit rebalance | Preview clarifies retreat and stat readability without rebuilding all unit stats. |
| Confirm modal | Attacking stays fast; preview only informs. |
| Damage numbers on the map | Separate combat-feel and animation stage. |
| New RNG | Preview uses the current `CombatRng` so the result matches the reducer. |
| Event-log preview | No events exist because no domain action has happened. |

## Further Improvement Direction

| Problem | Possible improvement |
| --- | --- |
| The player wants to compare several targets | Preview on hover/tap target or a target list in attack mode |
| The player does not understand modifiers | Expandable breakdown: terrain, technologies, veterancy |
| Combat feels too random | Show damage range instead of one prediction when `varianceRange` is high |
| Attacks are not satisfying enough | Damage numbers, hit flash, micro animation, and better event copy |
| The decision is still unclear | Add semantic risk labels such as `safe`, `risky`, `lethal` |
