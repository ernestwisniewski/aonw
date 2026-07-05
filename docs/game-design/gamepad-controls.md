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
| D-pad / left stick | Move the selected hex cursor, the selected row/card in open HUD panels, the focused HUD target while HUD focus is active, or scroll an open HUD popup |
| Right stick | Pan the camera |
| RT / LT triggers | Zoom in / zoom out |
| A | Confirm/tap the current cursor hex, or confirm the selected panel choice |
| B / Back | Close panel details, close the active panel or HUD popup, or cancel the active interaction mode |
| X | Toggle move targeting; in the technology panel, switch recommendations/tree view |
| Y | Inspect the current cursor hex, or open details for the selected city/technology panel item |
| L3 / R3 | Enter or leave HUD focus for the menu button, side actions, top resource pills, player rail, and bottom toolbar |
| RB | Focus the next pending player action |
| LB | Focus the turn-start map target |
| Start | Run the primary turn action, matching Space |

Terminology note: zoom is on the analog triggers, `RT` and `LT`. The bumpers,
`RB` and `LB`, are separate shoulder buttons and are reserved for turn-flow
focus shortcuts unless HUD focus is active, where they switch HUD sections. The
sticks are also separate: the left stick/D-pad moves the hex cursor, while the
right stick pans the camera. Pressing either stick enters or leaves HUD focus.

## Implementation Boundary

The gamepad layer translates controller input into existing game commands such
as `SelectTileCommand`, `TileTappedCommand`, `ToggleMoveTargetingCommand`, and
the relevant cancel commands. HUD panels consume the same normalized input for
local row/card selection, then call the existing production, research, details,
and close callbacks. This keeps controller support out of save/wire state and
avoids a parallel gameplay path.

HUD focus is similarly presentation-local. Pressing `L3` or `R3` activates a
focused HUD target, the D-pad moves within or between the menu, side rail, top
resource pills, player rail, and bottom toolbar, `A` invokes the same callback
as tapping the highlighted widget, and `B` returns input to the map. Open HUD
popups capture the controller so the D-pad scrolls their content and `B` closes
the popup instead of moving the map behind it. The renderer receives an idle
gamepad snapshot while HUD focus or popup capture is active so map cursor
movement and HUD navigation cannot both process the same frame.

## Manual Contract

The in-game manual has a dedicated Gamepad controls section. Keep it aligned
with this mapping whenever controller behavior changes, especially for
confirm/cancel, cursor movement, camera controls, and turn-flow shortcuts.

Sources:
- https://pub.dev/packages/gamepads
- https://pub.dev/documentation/gamepads/latest/
- https://developer.android.com/design/ui/tv/guides/foundations/navigation-on-tv
