# AoNW2 Godot Client

This directory contains the first executable AoNW2 presentation slice for
Godot 4.3 or newer. It loads the shared versioned map from
`content/maps/aonw2_starter/map.json` and renders a flat-top odd-q hex grid with
terrain colors and elevation.

Open `project.godot` in Godot and run `scenes/map_preview.tscn`. The preview
reads the shared source file directly from the repository and reloads it after
file changes. Hex instances are grouped by primary terrain and elevation and
rendered with `MultiMesh`.

The GDScript loader validates only the presentation-facing map shape needed by
this slice. `engine/crates/aonw_content` remains the canonical validator and
content-hash owner. Gameplay rules do not belong in this client.

Current scope:

- shared map loading and validation;
- odd-q coordinate projection;
- placeholder 3D terrain and elevation preview;
- automatic editor reload when the JSON changes.

Map painting controls, native Rust integration, selection, and gameplay
queries follow in separate slices.
