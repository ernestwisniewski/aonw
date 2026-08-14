# AoNW2 Godot Client

This directory contains the Godot 4.7 presentation client and the AoNW Map
Workbench. It converts an existing AoNW map into a self-contained Godot 3D
scene using either the deterministic legacy mesh or the optional Terrain3D
backend. Tree3D is not required.

## Map Workbench

Open the editor from the repository root:

```sh
make godot-editor
```

The **AoNW Map** dock appears on the right. Its map list discovers:

- strict shared maps in `content/maps/`;
- bundled Godot maps in `clients/aonw2_godot/assets/maps/`.

For migrated shared maps, the catalog associates the canonical JSON from
`content/maps/<map_id>/map.json` with matching JPG reference artwork from
`assets/maps/<map_id>/`. Rust and Godot never decode the unversioned Flutter
JSON.

Choose a map and select **Generate / update 3D**. The Workbench writes:

```text
clients/aonw2_godot/
├── scenes/maps/<map_id>.tscn                 # stable authored scene
├── scenes/generated/maps/<map_id>/
│   └── generation-NNNNNN_surface.tscn
└── assets/generated_maps/<map_id>/
    ├── manifest.json
    └── generations/generation-NNNNNN/
        ├── map.json                          # full generations
        ├── render_settings.tres
        ├── terrain_texture.res               # full generations
        ├── reference_texture.res             # full generations
        ├── terrain_mesh.res
        ├── reference_mesh.res
        ├── grid_mesh.res
        └── terrain3d/                        # Terrain3D generations only
            └── terrain3d_*.res
```

The authored scene contains the generated surface plus models and other nodes
added in Godot. Regeneration refreshes `AonwMap3D` while preserving authored
sibling nodes and custom children attached to the surface. The generated
surface contains these presentation layers:

- `BaseTerrain` is the deterministic elevated hex mesh and fallback;
- `Terrain3DGround` is generated only when the Terrain3D backend is selected;
- `ReferenceTexture` projects the original stitched `NxM.jpg` artwork for the
  legacy backend; Terrain3D blends the same artwork into its color map;
- `HexGrid` is a separately configurable grid overlay.

The **Rendering backend** selector switches between **Legacy mesh** and
**Terrain3D**. Terrain3D is discovered dynamically, so the project and legacy
maps still load when the addon is absent. Selecting an unavailable Terrain3D
backend produces a clear generation error and does not publish a partial scene.
Install the pinned addon with:

```sh
python3 clients/aonw2_godot/tools/install_terrain3d.py
```

See [TERRAIN3D.md](TERRAIN3D.md) for offline installation, compatibility,
texture-ID, and verification details.

In the **AoNW Map** dock, use **Show hex outlines** to toggle the overlay.
**Outline opacity** controls its opacity, while **Texture opacity** controls the
original reference artwork or its Terrain3D color-map contribution. These
controls update the open generated scene and are synchronized when another map
scene is opened. **Outline width** changes the geometry width so the grid
remains readable over detailed artwork.

`Hex height` controls how logical tile heights shape the surface. Terrain3D also
exposes sample density and region size. Geometry changes are debounced,
participate in editor undo/redo, and are persisted by **Save current scene**.
The Workbench writes settings, meshes, and optional Terrain3D regions to a new
immutable generation, saves the authored scene, and only then publishes that
generation in the manifest. A failed save therefore cannot leave a scene
referring to a partially overwritten generation.

Generated textures and meshes are Godot resources, so reopening the scene does
not load the original JPG slices again. The reference atlas preserves native
tile dimensions up to the preview cap rather than upsampling smaller artwork.
Regenerate the scene after changing the source map or its tile artwork. The
manifest records source identity, content hash, source tile size, active
generation, backend metadata, and render settings.

## Runtime preview

Run the standalone preview:

```sh
make godot-run
```

The bundled `aonw2_starter` map is the default and does not depend on files
outside the Godot project. Maps without painted JPG tiles use deterministic
terrain colors. The file picker accepts only strict map schema v1 documents.

Controls:

- left mouse button: select a hex;
- right mouse button: orbit;
- middle mouse button or arrow keys: pan;
- mouse wheel: zoom;
- `G`: toggle the hex grid.

Picking uses a shared hex projection and separate hover, selection, and
reachable overlay layers. When Terrain3D is active, picking uses its rendered
surface and units and overlays sample the Terrain3D height. The deterministic
legacy projection remains the fallback.

When `assets/scenarios/<map_id>.json` exists, the preview opens it through the
Rust local runtime and renders its player snapshot. Click a unit to query
reachable hexes, then click a highlighted hex to execute the command and
animate exact movement evidence. These presentation layers contain no movement
legality rules.

## Boundaries

- `application/map/read_model/` owns the immutable recipient renderer view;
- `application/map/` orchestrates loading and Godot scene generation;
- `application/session/` owns local-match lifecycle, revision tracking, and
  client command/query construction;
- `infrastructure/map/` discovers files, decodes JSON, assembles textures, and
  persists Godot resources; authored scenes, manifests, and atomic file writes
  are separate stores coordinated by the scene repository;
- `infrastructure/engine/` adapts JSON at the GDExtension boundary;
- `presentation/map/geometry/` owns odd-q render and texture projection math;
- `presentation/map/terrain/` owns stable visual terrain identifiers;
- `presentation/map/terrain3d/` rasterizes presentation data and adapts the
  optional Terrain3D GDExtension without importing gameplay rules;
- `presentation/` owns meshes, camera, runtime UI, and editor controls;
- `addons/aonw_map_workbench/` is the editor composition root.

The Workbench dock separates its control view from editor orchestration. This
keeps widget construction independent from generation, undo/redo, and scene
persistence behavior.

`engine/crates/aonw_content` remains the authoritative logical validator and
hash owner. A generated Godot scene is a presentation artifact and never a
second source of gameplay rules. Terrain3D control maps and regions are also
presentation artifacts; Rust still owns terrain costs, routes, visibility,
commands, persistence, and multiplayer compatibility.

The `aonw_godot` GDExtension exposes one strict `request_json` operation for
the shared `aonw_contracts::client` protocol. `AonwNativeLocalSession` is only
the JSON transport adapter. `AonwLocalMatchSessionController` owns the Godot
application lifecycle and current revision while sending the same tagged
requests and consuming the same recipient-safe responses planned for Flutter.
The Godot application owns its supported API constant independently from the
version reported by the loaded GDExtension. The transport and controller reject
an incompatible native library or response before reading its payload. Shared
request and response goldens are stored in `test/fixtures/client_protocol` and
are exercised by Rust, Dart, and Godot tests.
Strict maps and scenarios, snapshots, reachable and route queries, movement,
unit actions, saves, and replays all pass through this boundary.

Snapshots, reachable tiles, routes, command results, events, evidence, and view
patches are decoded into application-layer read models before they reach the
map screen or unit layer. Read-model definitions and strict decoding have
separate modules. Raw response dictionaries remain inside the session
controller and infrastructure boundary.

Selection is presentation-only; canonical state, visibility, paths, costs,
revisions, events, and persistence remain owned by Rust. The local runtime
prepares topology and terrain costs once, reuses search storage, and caches
revision-scoped queries; GDScript does not mirror these optimizations or rules.

Build the native adapter before opening or running Godot:

```sh
make rust-godot-build
```

`make godot-editor`, `make godot-run`, and `make godot-test` build it
automatically. The Makefile also discovers Cargo in the default rustup location
when it is not present in the interactive shell `PATH`. Headless tests first
run an editor scan so moved global classes are resolved from a clean checkout.

## Verification

```sh
python3 -m unittest discover -s clients/aonw2_godot/tools -p 'test_*.py'
make godot-test
make godot-check
```

The Python suite validates the pinned add-on installer without downloading the
release. The dedicated `Godot Terrain3D` pull-request workflow downloads and
checksum-verifies Godot 4.7.1 and Terrain3D 1.0.2 before running the same headless
suite. The runner delegates to focused authoring, geometry, native-session, and
Terrain3D-backend suites. They cover strict Rust validation, scenario bootstrap,
native snapshot/reachable/route/move and persistence calls, asset discovery,
immutable map views, projection/picking round trips, texture assembly, mesh and
Terrain3D raster generation, packed control bits, backend compatibility,
regeneration safety, and preserving authored nodes. When Terrain3D is not
installed, its suite verifies the clean rejection path; when installed, it also
verifies persisted region resources.

`GODOT_BIN` can override the editor executable.
