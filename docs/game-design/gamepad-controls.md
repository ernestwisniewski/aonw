# Gamepad Controls

## Research Notes

- Use normalized gamepad events rather than platform-specific raw keys. The
  `gamepads` package exposes Xbox-style buttons, D-pad, triggers, and stick
  axes across Android, iOS, desktop, and web.
- Keep directional navigation predictable. TV/controller guidance treats the
  D-pad as the primary four-way navigation surface and emphasizes clear,
  reachable targets plus predictable Back behavior.
- Strategy games are menu-heavy, so map control should avoid forcing players
  into dense pointer emulation. The first gamepad layer should therefore move a
  tactical map cursor, confirm/cancel domain actions, and reserve continuous
  analog input for camera work.

## Control Model

| Input | Action |
| --- | --- |
| D-pad / left stick | Move the selected hex cursor |
| Right stick | Pan the camera |
| RT / LT triggers | Zoom in / zoom out |
| A | Confirm/tap the current cursor hex |
| B / Back | Cancel the active interaction mode |
| X | Toggle move targeting |
| Y | Inspect the current cursor hex |
| RB | Focus the next pending player action |
| LB | Focus the turn-start map target |
| Start | Run the primary turn action, matching Space |

Terminology note: zoom is on the analog triggers, `RT` and `LT`. The bumpers,
`RB` and `LB`, are separate shoulder buttons and are reserved for turn-flow
focus shortcuts. The sticks are also separate: the left stick/D-pad moves the
hex cursor, while the right stick pans the camera.

## Implementation Boundary

The gamepad layer translates controller input into existing game commands such
as `SelectTileCommand`, `TileTappedCommand`, `ToggleMoveTargetingCommand`, and
the relevant cancel commands. It does not introduce a parallel gameplay path or
mutate game state directly.

## Manual Contract

The in-game manual has a dedicated Gamepad controls section. Keep it aligned
with this mapping whenever controller behavior changes, especially for
confirm/cancel, cursor movement, camera controls, and turn-flow shortcuts.

Sources:
- https://pub.dev/packages/gamepads
- https://pub.dev/documentation/gamepads/latest/
- https://developer.android.com/design/ui/tv/guides/foundations/navigation-on-tv
