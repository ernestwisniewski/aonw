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

A unit with at least one movement point may enter its first adjacent tile even
when that tile costs more than its remaining balance, provided the entry cost
does not exceed the unit's per-turn movement capacity. The entry consumes all
remaining movement and ends movement for that turn. This prevents a unit with
a partially spent turn from becoming trapped next to legal rough terrain.

Consequently, an ordinary land unit showing `2/3` movement can move from coast
to an adjacent ordinary forest: the forest costs 2, the unit arrives with 0,
and no path remains queued. At 0 movement points, no untravelled step is
reachable until the next turn.

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
