# AoNW2 Godot Client

This directory contains the Godot 4.7 presentation client and the AoNW Map
Workbench. It converts an existing AoNW map into a self-contained Godot 3D
scene without Terrain3D or Tree3D.

## Map Workbench

Open the editor from the repository root:

```sh
make godot-editor
```

The **AoNW Map** dock appears on the right. Its map list discovers:

- Flutter legacy maps in `assets/maps/`;
- strict shared maps in `content/maps/`;
- bundled Godot maps in `clients/aonw2_godot/assets/maps/`.

Choose a map and select **Generuj / aktualizuj 3D**. The Workbench writes:

```text
clients/aonw2_godot/
├── scenes/maps/<map_id>.tscn
└── assets/generated_maps/<map_id>/
    ├── map.json
    ├── manifest.json
    ├── terrain_texture.res
    ├── reference_texture.res
    ├── terrain_mesh.res
    ├── reference_mesh.res
    └── grid_mesh.res
```

Each generated scene contains three independent layers:

- `BaseTerrain` is an elevated hex surface colored from logical terrain data;
- `ReferenceTexture` projects the original stitched `NxM.jpg` artwork and has
  configurable visibility and opacity;
- `HexGrid` is a separately configurable grid overlay.

`height_step` controls how logical tile heights shape the mesh. Generated
textures and meshes are Godot resources, so reopening the scene does not load
the original JPG slices again. Regenerate the scene after changing the source
map, its tile artwork, or the height scale. The manifest records the source
path and SHA-256 of the source document.

## Runtime preview

Run the standalone preview:

```sh
make godot-run
```

The bundled `aonw2_starter` map is the default and does not depend on files
outside the Godot project. Maps without painted JPG tiles use deterministic
terrain colors. The file picker treats a selected map as strict v1 unless
**Format legacy** is enabled explicitly.

Controls:

- right mouse button: orbit;
- middle mouse button or arrow keys: pan;
- mouse wheel: zoom;
- `G`: toggle the hex grid.

## Boundaries

- `domain/map/` owns the immutable renderer read model and odd-q geometry;
- `application/map/` orchestrates loading and Godot scene generation;
- `infrastructure/map/` discovers files, decodes JSON, assembles textures, and
  persists Godot resources;
- `presentation/` owns meshes, camera, runtime UI, and editor controls;
- `addons/aonw_map_workbench/` is the editor composition root.

`engine/crates/aonw_content` remains the authoritative logical validator and
hash owner. The Workbench distinguishes strict v1 content from the explicit
legacy adapter. A generated Godot scene is a presentation artifact and never a
second source of gameplay rules.

The Rust engine now exposes a deterministic terrain-only route query, but the
Godot client is not connected to it yet. The next native vertical slice will
map picked hexes to revision-bound Rust queries and render returned route and
reachable overlays. GDScript must not calculate movement legality or paths.

## Verification

```sh
make godot-test
make godot-check
```

The test covers strict/legacy boundaries, asset discovery, immutable map views,
hex-to-world round trips, texture assembly, mesh generation, and saving/loading
a self-contained Godot scene. `GODOT_BIN` can override the editor executable.
