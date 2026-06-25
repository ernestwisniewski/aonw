# Map Display Preferences

This document describes lightweight map appearance preferences that are not
part of the save file or map data.

## Border and Wall

`Border` controls hex outline color, while `Wall` controls the height-wall tint
in the map renderer. Both colors flow through the shared
`HexDisplaySettings`, so the map editor and game map use the same rendering
fields:

| Setting | Effect |
| --- | --- |
| `hexBorderColor` | Hex-grid line color |
| `wallTintColor` | Base height-wall color |

The renderer respects the alpha channel of `hexBorderColor` directly. Setting
opacity to 0 in the picker disables the top-face outline, but it does not remove
the natural boundary between different terrain colors. The top-face outline is
also height-aware: the edge of a lower tile is not drawn when a higher neighbor
would cover it. For equal heights, the shared edge has a single rendering owner
to avoid stacking two translucent lines and to reduce flicker while panning.

## Editor Default

The map editor picker stores the global color default in `SharedPreferences`.
This is a user UI preference, not map metadata.

| Editor action | Storage key |
| --- | --- |
| Change `Border` | `hex_display.default.hex_border_color` |
| Change `Wall` | `hex_display.default.wall_tint_color` |

## Game Override

The in-game map options panel shows `Border` and `Wall` pickers. Changing a
color in game stores a per-map override keyed by `MapSelection.source` and
`MapSelection.name`.

Clicking `Default` in the game picker removes the override for the current map
and returns to the default set in the editor. This lets the player test contrast
on a specific map without losing the global favorite setting.
