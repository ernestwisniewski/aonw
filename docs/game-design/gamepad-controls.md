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
| D-pad / left stick | Move the selected hex cursor, main-menu focus, the selected row/card in open HUD panels, the focused HUD target while HUD focus is active, or scroll an open popup |
| Right stick | Pan the camera |
| RT / LT triggers | Zoom in / zoom out |
| A | Confirm/tap the current cursor hex, focused menu control, or selected panel choice |
| B / Back | Close menu popups, panel details, the active panel or HUD popup, or cancel the active interaction mode |
| X | Toggle move targeting; in the technology panel, switch recommendations/tree view |
| Y | Inspect the current cursor hex, or open details for the selected city/technology panel item |
| L3 / R3 | R3 jumps from the map to the bottom toolbar; while HUD focus is active, L3/R3 step left/right across HUD sections |
| RB | Focus the next pending player action |
| LB | Focus the turn-start map target |
| Start | Run the primary turn action, matching Space |

Terminology note: zoom is on the analog triggers, `RT` and `LT`. The bumpers,
`RB` and `LB`, are separate shoulder buttons and are reserved for turn-flow
focus shortcuts unless HUD focus is active, where they also switch HUD
sections. The sticks are also separate: the left stick/D-pad moves the hex
cursor, while the right stick pans the camera. Pressing `R3` from map input
starts HUD focus directly in the bottom toolbar so unit actions, city founding,
and attack confirmations are reachable without cycling across the full HUD.
Once HUD focus is active, `L3` moves one section left and `R3` moves one section
right.

## Implementation Boundary

The gamepad layer translates controller input into existing game commands such
as `SelectTileCommand`, `TileTappedCommand`, `ToggleMoveTargetingCommand`, and
the relevant cancel commands. HUD panels consume the same normalized input for
local row/card selection, then call the existing production, research, details,
and close callbacks. This keeps controller support out of save/wire state and
avoids a parallel gameplay path.

Map cursor selection is camera-stable: D-pad and left-stick cursor movement
selects a new hex without recentering the camera. Camera movement is reserved
for the right stick, zoom triggers, and explicit focus shortcuts such as the
turn-start target.

The active game screen owns one `GamepadInputRouterScope`. Routes register with
explicit priorities, and discrete actions such as confirm, cancel, inspect,
mode, HUD focus, turn focus, and primary turn action are dispatched to the first
eligible route. The renderer handles only analog camera and zoom deltas in its
per-frame path; cursor movement and buttons go through the same prioritized
dispatch as panels and HUD focus.

HUD focus is presentation-local. Pressing `R3` from the map activates the
bottom toolbar section, while an already active HUD focus uses `R3` and `L3` to
step through the left rail, menu, top resource pills, player rail, and bottom
toolbar. The D-pad moves within a section, `A` invokes the same callback as
tapping the highlighted widget, and `B` returns input to the map. Open HUD
popups capture the controller so the D-pad scrolls their content and `B` closes
the popup instead of moving the map behind it.

The first-turn tutorial also registers as a modal gamepad route. D-pad left/up,
`L3`, or `LB` move to the previous card; D-pad right/down, `R3`, `RB`, or `A`
advance; `B` minimizes the current card. The bubble includes a "Do not show
again" action that stores the dismissal for that save.

Main menu routes use the same normalized input, scoped to Flutter focus
traversal. The D-pad steps through menu actions and subpage controls such as New
Game, Load Game, Options, Manual, and Credits; `A` activates the focused control;
and `B` closes open popup routes such as dropdown menus before returning to the
previous menu route.

## Configuration

Gamepad input is configurable from Options. The defaults preserve the original
mapping: A/B/X/Y for confirm/cancel/mode/inspect, L3/R3 for HUD focus, LB/RB for
turn-flow focus shortcuts, Start for the primary turn action, the left stick and
D-pad for the cursor, the right stick for camera pan, and LT/RT for zoom.

Players can disable gamepad input, adjust deadzone and camera sensitivity,
invert camera Y, remap button actions, remap axis actions, or reset all bindings
to defaults. The mapper reads those settings before creating the normalized
`GamepadInputSnapshot`, so panels, HUD focus, tutorial cards, and renderer
routes all receive the same configured input contract.

## Manual Contract

The in-game manual has a dedicated Gamepad controls section. Keep it aligned
with this mapping whenever controller behavior changes, especially for
confirm/cancel, cursor movement, camera controls, and turn-flow shortcuts.

Sources:
- https://pub.dev/packages/gamepads
- https://pub.dev/documentation/gamepads/latest/
- https://developer.android.com/design/ui/tv/guides/foundations/navigation-on-tv
