# AoNW Godot Client

This directory contains the Godot 4.7 presentation client and the AoNW Map
Workbench. Terrain3D is the required terrain-authoring backend; gameplay rules
remain in Rust.

## Map Workbench

Open the editor from the repository root:

```sh
make bootstrap
make godot-editor
```

Bootstrap downloads the exact Godot build pinned by the repository and the
official pinned Terrain3D addon. Both remain ignored local dependencies. The
editor commands reject any other version or a disabled Terrain3D plugin.

The **AoNW Map** dock appears on the right. Its map list discovers:

- strict shared maps in `content/maps/`;
- bundled Godot maps in `clients/aonw_godot/assets/maps/`.

For migrated shared maps, the catalog associates the canonical JSON from
`content/maps/<map_id>/map.json` with the compiled reference atlas described by
`assets/runtime/maps/<map_id>/map_texture_manifest.json`. Godot assembles its
JPG pages directly and verifies the map content hash, dimensions, format, and
SHA-256 of every page. A missing or stale bundle is rejected; Godot never
depends on raw per-tile artwork or a procedural texture fallback.

Every Godot editor or test bootstrap compiles each
`content/maps/<map_id>/terrain_authoring.v1.json` profile through the pure Rust
terrain compiler. The reviewed inputs are separate `base`, `min`, and `max`
32-bit EXR rasters. Their manifest and SHA-256 checksums are placed in the
ignored `clients/aonw_godot/.godot/terrain_compiled/` cache.

Choose a map and select **Create / open Terrain3D**. Maps without a valid,
current authoring profile are rejected; there is no mesh terrain fallback. The
Workbench writes:

```text
clients/aonw_godot/
├── scenes/maps/<map_id>.tscn                 # stable authored scene
└── assets/generated_maps/<map_id>/
	└── terrain_authoring/
		├── reference_texture.res
		├── terrain_authoring_state.v1.json
		├── published_terrain.v1.json         # only after successful validation
		└── final/terrain3d_*.res             # manual Terrain3D regions
```

The authored scene contains one `Terrain3D` node plus reference, grid,
min/max-debug, and city-scale overlays. `ArrayMesh` is used only for those
overlays; it never represents editable terrain. Select the `Terrain3D` child to
use Terrain3D's sculpting and texture-painting tools.

The dock controls reference visibility and opacity, the terrain-sampled hex
grid, the min/max debug envelopes, and a city-core footprint marker whose
radius cannot exceed one authoring hex. Terrain3D's `maps_edited` signal is
translated to the affected raster rectangle and only that rectangle is
clamped. **Validate & publish** always performs a separate full-raster check
and refuses to publish any non-finite or out-of-envelope height.

**Save draft** persists manual Terrain3D regions and records
`mapContentHash`, `authoringProfileHash`, `generatedBaseHash`,
`generatorVersion`, and `terrainRevision`. **Reload compiled base /
constraints** updates generated inputs but never imports `base` over an
existing manual `final`. Closing and reopening the scene reloads the final
Terrain3D regions from disk.

## Runtime preview

Run the standalone preview:

```sh
make godot-run
```

The bundled `aonw2_starter` map is the default and does not depend on files
outside the Godot project. Regenerate it with `make godot-map-sync` and verify
byte-for-byte reproducibility with `make godot-map-bundle-check`. The file
picker accepts only strict map schema v1 documents whose matching asset bundle
and compiled Terrain3D profile are available. There is no runtime mesh-terrain
fallback: the compiled base raster is imported into Terrain3D, while the
reference texture and hex grid remain independent terrain-following overlays.

Controls:

- left mouse button: select a hex;
- right mouse button: orbit;
- middle mouse button or arrow keys: pan;
- mouse wheel: zoom;
- `G`: toggle the hex grid.

Picking uses a shared hex projection and separate hover, selection, and
reachable overlay layers. When `assets/scenarios/<map_id>.json` exists, the
preview opens it through the Rust local runtime and renders its player
snapshot. Click a unit to query reachable hexes, then click a highlighted hex
to execute the command and animate exact movement evidence. These layers
contain no movement legality rules.

## Boundaries

- `game/application/map/read_model/` owns the named, deeply immutable recipient
  `MapView`, tile views, and objective views;
- `game/application/map/` orchestrates runtime map loading;
- `game/application/terrain/` owns the compiled Terrain3D application value and
  its reader port;
- `game/application/session/` owns local-match lifecycle, revision tracking, and
  client command/query construction;
- `game/infrastructure/map/` is the only layer that maps raw `MapViewDto` data
  and verifies reference bundles;
- `game/infrastructure/terrain/` verifies and loads compiled Terrain3D artifacts;
- `game/infrastructure/engine/` adapts JSON at the GDExtension boundary;
- `game/presentation/map/geometry/` owns odd-q render and texture projection math,
  checked against the same neutral vectors as the successor Flutter client;
- `game/presentation/` owns Terrain3D presentation, overlay meshes, camera, and UI;
- `editor/map_authoring/` owns Workbench application, infrastructure, and UI;
- `addons/aonw_map_workbench/` is only the editor plugin composition root.

The Workbench dock separates its control view from editor orchestration. This
keeps widget construction independent from generation, undo/redo, and scene
persistence behavior.

`engine/crates/aonw_content` remains the authoritative logical validator and
hash owner. A generated Godot scene is a presentation artifact and never a
second source of gameplay rules.

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
make godot-test
make godot-check
```

The runner delegates to focused runtime-map, geometry, native-session,
Terrain3D-spike, and terrain-authoring suites. They cover strict Rust
validation, scenario bootstrap, native
snapshot/reachable/route/move and persistence calls, asset discovery, immutable
map views, projection/picking round trips, texture assembly, verified EXR
import, regional clamp, independent publish validation, metadata identities,
overlay alignment, undo/redo, base-regeneration safety, and final-terrain
save/reopen persistence. `GODOT_BIN` can override the editor executable.
