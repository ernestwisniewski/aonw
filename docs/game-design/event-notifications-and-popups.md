# Event Notifications and Popups

This document describes popups built from `gameEventNotificationsProvider`.

## Principle

A popup may use the same source as a toast and the activity log, but it does
not need the same shape or settings. Technologies still use their own popup
with a "Do not show again" option. Civilization contact also has a per-save,
per-player "Do not show again" setting, because repeated first-contact popups
are noisy in hotseat and long-running test saves.

## Civilization Contact

`CivilizationMetEvent` is the first-contact UI event. The notification provider
derives it by comparing `previousState` with the new `GameState` for the active
player:

| Contact | Condition |
| --- | --- |
| Visible rival unit | The unit hex enters the active player's `visibleHexes` |
| Known rival city | The city hex enters the active player's discovered hexes |

We do not add a separate "known civilizations" field to the save file. The
popup appears when a specific state transition reveals a new object owner in
vision or map memory. This keeps the logic close to fog of war and avoids
another migration-bearing state field.

The mute state is intentionally not part of the save payload. It is stored in
local `SharedPreferences` under
`game.<saveId>.player.<playerId>.civilization_met_popup.show`, so suppressing
the popup affects only that local device/user preference and not multiplayer
state.

In the HUD:

- the toast and activity log receive the `New civilization` title,
- the dedicated `CivilizationMetPopupOverlay` shows the nation, leader, and
  player,
- the popup has a `Do not show again` checkbox backed by the per-player local
  setting,
- tapping the toast focuses the first known city or unit of the encountered
  player.

## Multiplayer

Network snapshots after live events pass events to
`gameEventNotificationsProvider` after the renderer has applied them. That
keeps the same mechanism working for local commands, single-player AI, and
opponent moves in multiplayer.
