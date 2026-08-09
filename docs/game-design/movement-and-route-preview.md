# Movement And Route Preview

This document defines the canonical unit-movement and route-preview contract.
Authoritative legality and costs belong to `aonw_core`; the Flutter/Flame
client only projects the resulting `UnitMovementPlan`.

## Movement Costs

Land-unit entry cost is derived from the destination tile's normalized terrain
profile. The tile occupied by the unit does not add an exit cost.

| Terrain | Entry cost or rule |
| --- | --- |
| Grassland, plains, coast | 1 |
| Desert, tundra | 2 |
| Snow | 3 |
| Forest, jungle, wetlands, hills feature | +1 to the base terrain |
| River modifier | No additional movement cost |
| Mountain | Blocked |
| Ocean, lake | Blocked for land units |
| Coast, ocean | Cost 1 for naval units; other terrain is blocked |

Feature-only forest, jungle, and wetlands normalize to grassland, while
feature-only hills normalize to plains; each therefore costs 2. Snow already
represents the full base cost of an ordinary snowy forest, so forest does not
increase that profile beyond 3 unless another rough feature is present.

## Partially Spent Turns

A movement command first pays every complete step along the selected route.
When the unit still has movement but the next legal step costs more than the
remaining balance, it enters exactly that step and exhausts the balance to 0.
The current-turn prefix ends there and never expands to another step. The entry
cost must still be traversable under the unit's per-turn capacity rules; the
existing artifact-carrier exception remains unchanged.

This rule applies to an adjacent target and to a distant queued route alike.
For example, a `3/3` warrior following two consecutive forest steps with costs
`2 + 2` reaches the second forest and ends at `0/3`; it does not stop after the
first forest with one unused point. If the selected target lies farther away,
the remaining suffix stays queued. At 0 movement points, no untravelled step
is reachable until the next turn.

`estimatedTurns`, bounded `movementCostsFrom(maxCost)` searches, direct moves,
queued moves, and merchant route advancement use the same terminal-step rule.
The bounded search includes the one exhausting boundary step but never its
successors. `movementCostsFrom` is a terrain-cost frontier; authoritative
command and queued-route feasibility still reject a non-carrier step beyond
the unit's per-turn capacity before any state change.

## Route Presentation

`UnitMovementPlan.canReachStepThisTurn` is the single reachability source for
route rendering. Presentation must not recalculate terrain costs.

| Route state | Presentation |
| --- | --- |
| Reachable this turn | Gold route and marker |
| Not reachable this turn | Danger route and marker |
| Already travelled queued-path prefix | Muted travelled history |
| Merchant trade route | Neutral trade-route palette |

The destination marker and the animated fallback marker inherit the semantic
color of their route point. They must not add a fixed gold accent to an
unreachable route. For a queued route at 0 movement, the current tile remains
the plan origin, while every future segment and marker is rendered as
unreachable.

## Ownership And Verification

- `UnitMovementCostRules`, `UnitMovementPathfinder`,
  `UnitMovementFeasibility`, and `MovementCommandResolver` own authoritative
  rules in `packages/aonw_core/`.
- Local, engine, and domain adapters execute the same resolver and are covered
  by adapter-parity tests.
- `UnitMovePreviewLayer` maps plan reachability to rendering, and render tests
  verify the final marker pixels as well as the step-level reachability list.
