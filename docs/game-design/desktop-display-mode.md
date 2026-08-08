# Desktop Display Mode

The Linux, macOS, and Windows clients start in native full-screen mode. A
player can opt into windowed mode in **Main menu > Settings > Graphics**. The
choice is persisted locally and applied before the desktop window is shown on
the next launch.

## Ownership

Display mode belongs to the application shell rather than the game domain:

- `DisplaySettings` represents the persisted player choice;
- `DisplaySettingsController` coordinates UI state, persistence, and the
  window port;
- `GameWindow` is the platform boundary;
- `PlatformGameWindow` adapts the Linux, macOS, and Windows window manager;
- `DisplayBootstrap` applies the stored choice before `HexApp` is mounted.

Mobile and web clients do not expose the setting. A failed runtime transition
restores the prior UI and window state and leaves the stored preference
unchanged.

## Layout Contract

Changing display mode changes the logical Flutter viewport. Flutter and Flame
continue to handle device-pixel ratio and resize notifications. The map keeps
its current camera zoom, so a larger viewport shows more world; display mode
does not introduce a virtual resolution or global UI transform.

Responsive widgets must continue to base layout decisions on their available
constraints. Full-screen behavior should be checked on standard, short, and
ultrawide desktop viewports when changing menu or HUD layouts.
