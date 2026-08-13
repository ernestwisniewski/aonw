# AoNW2 Godot Client

This directory contains the AoNW2 presentation client for Godot 4.7. The first
vertical slice opens an AoNW map, reconstructs its artwork from the sibling
`NxM.jpg` slices, and renders one continuous elevated surface with an
independently toggled hex-grid overlay.

Open `project.godot` and run `scenes/map_preview.tscn`. Myranth is loaded by
default. Use **Otwórz mapę** to select another `map.json`, and use **G** or the
toolbar switch to show or hide the hex grid.

Controls:

- right mouse button: orbit;
- middle mouse button or arrow keys: pan;
- mouse wheel: zoom.

The implementation follows an inward dependency direction:

- `domain/map/` owns map invariants and exact odd-q geometry;
- `application/map/` orchestrates opening a map through injected repositories;
- `infrastructure/map/` reads JSON and builds the texture atlas;
- `presentation/` owns the mesh, camera, UI, and composition root;
- `scenes/` contains declarative Godot scene wiring;
- `tests/` verifies map loading, atlas construction, shared hex vertices, and
  generated meshes.

`engine/crates/aonw_content` remains the canonical content validator and hash
owner. GDScript validates only the read model required to render a map. Game
rules do not belong in the Godot client.

Run the focused pipeline test from the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path clients/aonw2_godot \
  --script res://tests/test_map_pipeline.gd
```

Map editing, selection, native Rust integration, and gameplay queries remain
separate vertical slices.
