# Turn Flow and Action Focus

This document describes the current start-of-turn focus rule and the difference
between automatic turn start and the manual "next action" button.

## UX Goal

At the start of a turn, the player should not begin on an empty map or stale
selection. If the active player has a unit that can move or act, the camera and
selection move to that unit and movement targeting becomes active.

This shortens the path to the first decision of the turn:

| Situation | Behavior |
| --- | --- |
| Player has a unit with movement | Select the unit, enable move targeting, focus the camera on the unit |
| No unit with movement, but a city has no production | Select the city as the next decision |
| No units or cities need decisions and no research is active | Fall back to the player's starting object: first unit or city |
| Stale selection from previous turn exists | Turn start ignores it when choosing the first target |

## Two Focus Commands

| Command | Use | Behavior |
| --- | --- | --- |
| `FocusTurnStartActionCommand` | Automatic turn start and handoff | Picks the first target by ranking, without cycling |
| `FocusNextPendingActionCommand` | Manual "next action" button | Cycles from the current selection to the next decision |

This split is intentional. Turn start should be predictable and always lead to
the most important decision, while the manual button should let the player walk
through the full list of remaining tasks.

## `Action` Button and End Turn

The bottom toolbar combines the end-turn CTA with the pending-decision list. If
the active player still has something to do, the end-turn button does not end
the turn immediately; it changes into `Action`.

| Turn state | Label | Click |
| --- | --- | --- |
| `readyToEndTurn == false` | `Action` | Focuses the next decision through `focusNextAction` |
| `readyToEndTurn == true` | `End turn` | Ends or submits the turn |

This gate covers units with movement, cities without production, and missing
active research. The smart end-turn CTA is therefore implemented through
`Action`, without a separate confirmation modal.

In `Action` mode, the button shows a thumbnail of the next item from the same
list exposed in the expanded menu: units use `UnitSpriteIcon`, cities use
`CitySpriteIcon`, and research uses the recommended technology if known. When
the right segment of the action list is visible with a `1/2` counter, the
thumbnail is anchored to the right side of that segment; without the segment it
returns to the right edge of the main button. A soft mask keeps high
transparency on the left and ramps toward 85% final visibility on the right,
creating the effect of the icon emerging from the background.

Inside the right segment, the asset renders at about 140% of base size and is
shifted slightly beyond the top and right edge so it reads as a layer emerging
behind the button corner. City thumbnails still use frames and corrections from
`CitySpriteCatalog`, but in this segment they render with `BoxFit.cover`, fill
100% of button height, anchor right, and use a less transparent mask so the
asset edge is not visible. Their opacity ramps more slowly than research
thumbnails, and all toolbar thumbnails end at 85% mask visibility. Units use a
separate slower fade curve so the silhouette does not appear too abruptly. The
action counter in the segment has a subtle glow to stay readable over the
asset. After an action completes, the pending-decision list rebuilds and the
thumbnail moves to the next action in the same order.

The detailed asset-icon rendering contract lives in
`docs/game-design/asset-icon-rendering.md`.

If the current selection already matches the current queue item, the thumbnail
on `Action` shows the next item because that is where clicking will go. With a
single action, the thumbnail is hidden only when the selection already matches
that action; if the object is not selected, the thumbnail still shows the click
target. Unit thumbnails have a light per-type scale correction, with the worker
as reference, so slimmer sprites do not look optically smaller in the same
button location.

When a selected unit has exactly 1 movement point and can still act, the `Skip`
command in the bottom toolbar pulses its border. This reminds the player that
the remaining movement can be intentionally closed instead of looking for a
forced action.

## Explicit Automatic Actions

Automatic actions do not change the turn-start flow. They are treated like
normal commands available after selecting a unit.

| Action | When visible | Result |
| --- | --- | --- |
| `Explore` | Active scout with movement or scout in `autoExploring` | Enables or cancels automatic exploration |

`Explore` stores the explicit `UnitPosture.autoExploring` posture. A scout with
that posture does not block next-action selection for the turn; at the start of
the next turn it receives another legal exploration move. Manual movement or
canceling the action clears posture back to `active`.

## Turn Target Ranking

The ranking is shared by turn start and the "next action" button. Only the list
start point differs.

| Priority | Target | Condition |
| --- | --- | --- |
| 1 | Combat unit | Has movement points, is not working, has no queued path, is not fortified |
| 2 | Worker/settler | Has movement points, is not working, has no queued path, is not fortified |
| 3 | Other unit | Has movement points and requires a decision |
| 4 | City without production queue | Active player must choose production |
| 5 | Research | Active player has no active technology and has an available technology |

Combat units with visible enemies rank above combat units without contact.
Within the same category, keep the stable order from the unit list.

## State After Unit Selection

When turn start selects a unit:

| Field | Required state |
| --- | --- |
| `GameState.selection` | `GameSelection.unit(...)` for the selected unit |
| `GameState.selectedUnitId` | Selected unit id |
| `GameState.moveCommandActive` | `true` if the unit is controllable and has movement |
| `GameState.movePreview` | `null` until the player points at a movement target |
| Camera | `SmoothCameraEffect` to the unit position |

`movePreview` is not created automatically because it requires a movement
target. Entering movement targeting only means the UI is ready for the player
to choose a destination hex.

## Simultaneous-Movement Animations

In simultaneous turns, opponent movement must pass through the renderer as an
animation even if it is the opponent's first action in a new turn and the local
player is not issuing a command at that moment.

Contract:

| Movement source | Animation source |
| --- | --- |
| Local `MoveUnitCommand` | `MovementReducer` returns `AnimateUnitMoveEffect` |
| Accepted network command | `UnitMovedEvent` maps to `AnimateUnitMoveEffect` |
| Live multiplayer event from another player | Snapshot is applied by `GameRenderer.applyTransition(...)`, and `UnitMovedEvent` provides animation |
| Queued-path movement at turn start | `QueuedMovementEffectBuilder.fromUnitDelta(...)` replays queued steps |

`GameEventRendererEffectMapper` skips `UnitMovedEvent` for units that already
have animation from command effects. That prevents local movement and
single-player AI from receiving duplicate animation, while external multiplayer
movement does not teleport units between snapshots.

The live multiplayer subscription starts from the last known `eventLogOffset +
1` so old events are not replayed after bootstrap. New network snapshots are
queued and ignored when their offset is not newer than the locally applied one.

## Fallback

If ranking does not produce a map target, the HUD tries to focus the camera on
the first known object owned by the player:

1. first unit of the active player,
2. first city of the active player.

The fallback must not create an artificial decision. It only avoids a turn
start that shows no meaningful map location to the player.
