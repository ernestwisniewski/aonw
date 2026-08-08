# Mobile QoL Automation

This document describes opt-in automatic action rules. Automation should reduce
mobile micromanagement without taking turn control away from the player.

## General Rules

| Rule | Meaning |
| --- | --- |
| Opt-in | The player always clicks an explicit action to enable automation. |
| Explicit cancellation | An active unit mode can be interrupted by using the active action again or issuing a manual movement command. |
| Legal commands | Automation ultimately produces normal movement effects and does not bypass pathfinding. |
| Save state | Persistent unit modes are stored explicitly in `GameUnit.posture`. |
| Current contracts | New actions use current domain commands and avoid compatibility branches. |
| Readable no-op | If no meaningful legal action exists, canonical state stays unchanged and the HUD shows light local feedback. |

## Scout Auto-Explore

Auto-explore applies only to scouts. After clicking `Explore`, the scout makes
the first legal exploration move and enters `UnitPosture.autoExploring`. At the
start of later turns it plans the next move by itself until the player cancels
or issues manual movement.

| Element | Decision |
| --- | --- |
| Unit | `GameUnitType.scout` |
| UI | `Explore` action when a scout is selected |
| Start command | `AutoExploreUnitCommand` |
| Unit state | `UnitPosture.autoExploring` |
| Range | Only hexes the scout can enter this turn |
| Goal | Reveal as many unknown hexes as possible |
| No target | No command, no state change, local HUD message |
| Cancellation | Active `Explore` sends `CancelUnitActionCommand`; manual movement resets posture to `active` |

### Start Conditions

| Condition | Requirement |
| --- | --- |
| Unit type | scout |
| Movement points | `movementPoints > 0` |
| Queued path | No active movement queue |
| Unit work | `isWorking == false` |
| Posture | Unit is not fortified |
| Target legality | Pathfinder must return a plan and `plan.canMoveNow == true` |

### Candidate Scoring

The resolver evaluates every legal destination hex and simulates scout vision
after movement. A candidate is considered only if it reveals at least one new
hex.

| Parameter | Current value | Balance role |
| --- | ---: | --- |
| `minimumNewlyDiscoveredHexes` | `1` | Blocks empty auto-moves over already discovered terrain |
| `newlyDiscoveredHexScore` | `1000` | Main priority: new hexes matter more than movement cost |
| `visibleHexScore` | `2` | Light tie-breaker for wider vision |
| `movementCostScore` | `10` | Prefers using movement this turn when reveal is similar |
| `distanceFromStartScore` | `1` | Lightly pushes the scout toward a farther exploration front |

Tie-break order:

1. higher score,
2. more newly discovered hexes,
3. higher movement cost this turn,
4. deterministic lower column and lower row.

## Auto-Explore Flow

```mermaid
flowchart TD
    A["Player selects a scout"] --> B["HUD shows Explore"]
    B --> C["Action click"]
    C --> D["ScoutAutoExplorePlanner evaluates legal targets"]
    D --> E{"Exploration target exists?"}
    E -- "yes" --> F["Dispatch AutoExploreUnitCommand"]
    E -- "no" --> G["No command"]
    F --> H["Reducer sets autoExploring and executes movement"]
    H --> I["Next turn start plans another move"]
    I --> J{"Player cancels or moves manually?"}
    J -- "yes" --> K["Posture returns to active"]
    J -- "no" --> I
```

## Worker Improvement

Workers expose two complementary actions. `Improve` keeps the manual picker for
the current tile. `Auto work` plans a legal task across every controlled hex of
the player's cities, moves through the canonical pathfinder, and starts the
shared recommended improvement. If no buildable hex exists anywhere, it falls
back to the nearest free completed improvement and creates a persistent worker
assignment.

| Element | Decision |
| --- | --- |
| Unit | `GameUnitType.worker` |
| UI | `Improve` opens the picker; `Auto work` starts automation |
| Start command | `AutomateWorkerCommand` |
| Unit state while travelling | `UnitPosture.autoWorking` with a canonical queued path |
| Legality | `WorkerImprovementRules.evaluate(...)` |
| Ranking | `WorkerImprovementRecommendation` backed by `WorkerImprovementScoring` |
| Charges | `WorkerImprovementChargeRules.defaultWorkerCharges = 1` |
| Result commands | `StartWorkerActionSelectionCommand`, `SelectWorkerImprovementCommand`, `ConfirmWorkerImprovementCommand` |
| Work completion | After finishing an improvement, worker loses 1 charge; at 0 it disappears |
| Assignment fallback | Existing improvement, free hex, city assignment capacity, +50% tile-yield bonus |
| Cancellation | `Cancel auto work` uses `CancelUnitActionCommand`; `End work` uses `CancelWorkerAssignmentCommand` |

### Start Conditions

| Condition | Requirement |
| --- | --- |
| Unit type | worker |
| Movement points | `movementPoints > 0` |
| Queued path | No active movement queue |
| Unit work | `workerJob == null` and `workerAssignment == null` |
| Posture | Unit is not fortified |
| Target legality | A reachable legal improvement or assignment exists in any owned city |
| Technology | Required technologies are unlocked for the worker owner |

### Planning and Scoring

Manual and automatic paths call the same recommendation policy. Automation
first considers every legal build candidate; an existing-improvement assignment
is considered only when that set is empty. This preserves the player's intent
that a worker with a charge should improve the empire before becoming a
permanent specialist.

| Priority | Rule |
| --- | --- |
| 1 | Build candidates: lowest reachable path cost |
| 2 | Higher shared recommendation score |
| 3 | Fewer construction turns |
| 4 | Stable city, coordinate, and improvement-type identity |

For assignment fallback, path cost wins first, then the higher effective
worker yield. Active jobs, assignments, and destinations reserved by another
automated worker are excluded. At each turn start the worker replans from
canonical state, so changed borders, occupancy, technology, or routes cannot
leave it following a stale private plan.

```mermaid
flowchart TD
    A["Player selects a worker"] --> B["HUD shows Improve and Auto work"]
    B --> C["Dispatch AutomateWorkerCommand"]
    C --> D{"Any reachable legal build target?"}
    D -- "yes" --> E["Choose nearest recommended improvement"]
    D -- "no" --> F{"Any reachable free completed improvement?"}
    F -- "yes" --> G["Choose nearest assignment"]
    F -- "no" --> H["Show No work available feedback"]
    E --> I["Move using canonical path and replan each turn"]
    G --> I
    I --> J{"Reached target with an action available?"}
    J -- "no" --> I
    J -- "build" --> K["Create workerJob"]
    J -- "assign" --> L["Create persistent workerAssignment"]
    K --> M["Completion consumes workerBuildCharges"]
    L --> N["Worker stays and contributes +50% tile yield"]
```

## City Founding

City founding has two different UI states. Before confirming controlled-hex
selection, the settler uses draft mode and `Cancel` sends
`CancelCityFoundingCommand`. After confirmation, when the unit already has an
active `cityFoundingJob`, the bottom toolbar shows the same single `Cancel`
button used by exploration, worker jobs, and other active unit actions. That
button sends standard `CancelUnitActionCommand`, which clears `cityFoundingJob`
without adding a separate cancellation path.

Draft mode exposes a dynamic connected selection frontier. Initially, only
legal neighbors of the city center are selectable. Each selected hex extends
that frontier with its legal neighbors, while non-adjacent hexes remain
inactive. Once the two required controlled hexes are selected, the frontier is
empty. Removing a bridge also removes any selected hex disconnected from the
center, so the draft stays valid after every interaction.

## What This Stage Does Not Do

| Out of scope | Reason |
| --- | --- |
| Auto-explore for ships | Requires separate water and map rules |
| Sentry mode | Different semantics: waiting and waking on threat |
| Fog-rule changes | Auto-explore should use existing visibility, not change it |
| Hidden worker route knowledge | Automation uses the same actor visibility and path constraints as manual movement |

## Worker Recommendation Contract

Worker recommendations use core `WorkerImprovementRecommendation` and
`WorkerImprovementScoring`, and scoring reads the base hex yield from
`CityTileYieldRules`. Tuning worker-improvement weights therefore affects both
the manual recommendation in the `Improve` panel and automated target choice.

## Fortify As Sentry

A separate `Sentry mode` is not needed in the first Slice 8 scope because the
existing `Fortify` action already has the intended waiting semantics.

| Element | State |
| --- | --- |
| UI | `Fortify` action on a unit |
| Command | `FortifyUnitCommand` |
| Entering mode | Movement points drop to 0, posture becomes `fortified`, queued path is cleared |
| No enemy | Unit stays without movement and heals 1 HP/turn |
| Visible enemy | Unit wakes, returns to `active`, and regains full movement |
| Cancellation | Using the active `Fortify` action again cancels posture through standard cancel action |

Future work should not add a second action with the same responsibility. Any
improvement should focus on copy/tooltip clarity or fortified-state visibility,
not a new domain mode.

## No-Op Feedback

Auto-explore and worker automation have local feedback when their planner finds
no legal action. Manual worker `Improve` still relies on the picker to show
legal and blocked options with reasons.

| Element | Rule |
| --- | --- |
| Layer | Presentation/HUD only |
| Save state | No change |
| Event log | No entry |
| Domain command | Auto-explore is not sent; worker automation is rejected without a canonical state change |
| Activity log | No entry |
| Lifetime | Short HUD toast, auto-dismissed |

Messages:

| Action | Title | Reason |
| --- | --- | --- |
| `Explore` | `No exploration route` | Scout has no movement that reveals new tiles this turn |
| `Auto work` | `No work available` | No reachable build target or free completed improvement exists in an owned city |

Successful auto-actions clear previous local feedback and continue through the
standard command path.

## Further Balance Direction

| Problem to watch | Possible adjustment |
| --- | --- |
| Scout moves too chaotically | Lower `movementCostScore`, add direction preference away from empire center |
| Scout ignores nearby ruins/POI after they are added | Add separate POI score before normal reveal |
| Auto-explore does nothing too often | Allow movement to frontier hexes with `newlyDiscoveredHexes == 0` when adjacent to hidden space |
| Worker recommendation points to farms too often | Lower food weight or add city/deficit context |
| Player still does not understand no-op auto-actions | Clarify blocker-specific reasons in the message without adding domain events |
