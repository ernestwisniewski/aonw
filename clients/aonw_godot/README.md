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
The desktop-only client uses Godot's Forward+ rendering method for maximum
desktop visual quality. On macOS this keeps Terrain3D on Metal and off the
OpenGL compatibility shader path that can crash inside Apple's shader compiler.

The **New map** section creates either a validated `blankV1` authoring canvas
or a deterministic `continentalV1` landscape directly from the Godot dock.
The form collects the generator, map ID, odd-q dimensions, default zoom,
metric hex radius, map-specific level-5 height, and deterministic seed. The
framework-neutral Rust `aonw_map_workbench` boundary returns canonical
`map.json`, `terrain_authoring.v1.json`, generation provenance, and a
generated-decoration plan. The filesystem adapter publishes the complete
directory without overwriting an existing map, compiles Terrain3D, and opens
the new authoring scene. `continentalV1` generates coherent logical elevation,
biomes, compatible resources, and batched tree, rock, water, and detail
placements. A newly generated map intentionally has no 2D reference atlas.

The **Logical Map** section edits the open map directly in the 3D viewport.
Choose a terrain, resource, or logical-height brush and click or drag over
hexes. One stroke is persisted and compiled once through Rust. Rust returns
complete canonical replacements and new map/profile hashes; the filesystem
adapter never assembles map fields. The manual Terrain3D final is migrated and
saved under the new logical identity.

Generated visual objects and manual objects have separate `GeneratedWorld` and
`ManualWorld` scene containers. The versioned plan is rendered as one
`MultiMesh` per decoration kind, and refreshing or invalidating it replaces
only the generated container. Gameplay-relevant terrain, resources and logical
height remain Rust content; concrete visual placements remain versioned
presentation artifacts. See [ADR 0011](../../docs/adr/0011-logical-map-workbench-and-generation.md).

The **AoNW Map** dock appears on the right. Its map list discovers:

- strict shared maps in `content/maps/`;
- bundled Godot maps in `clients/aonw_godot/assets/maps/`.

For migrated shared maps, the catalog associates the canonical JSON from
`content/maps/<map_id>/map.json` with the compiled reference atlas described by
`assets/runtime/maps/<map_id>/map_texture_manifest.json`. Godot assembles its
JPG pages directly and verifies the map content hash, dimensions, format, and
SHA-256 of every page. A missing or stale bundle is rejected by runtime.
Terrain authoring can still open without the optional reference overlay after
a logical edit; the stale reference is visibly disabled rather than rebound to
a false content hash. Godot never depends on raw per-tile artwork or a
procedural texture fallback.

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
├── scenes/terrain_authoring/<map_id>.tscn    # clean Terrain3D authoring scene
└── assets/generated_maps/<map_id>/
	└── terrain_authoring/
		├── current_draft.v1.json             # atomic pointer
		├── current_published.v1.json         # only after successful validation
		├── workspace/terrain3d_*.res         # mutable Terrain3D working data
		├── draft/<snapshot_hash>/            # immutable verified snapshots
		└── published/<snapshot_hash>/        # immutable published snapshots
```

The reference texture is rebuilt from the canonical, identity-checked map
bundle whenever the scene opens; it is not persisted as a second generated
artifact. The authored scene contains one `Terrain3D` node plus reference,
grid, lazy min/max-debug, and city-scale overlays. Hidden min/max overlays do
not exist as empty `MeshInstance3D` nodes. `ArrayMesh` is used only for those
overlays; it never represents editable terrain. Select the `Terrain3D` child
to use Terrain3D's sculpting and texture-painting tools.
Terrain3D world-background generation is forced off, so no procedural hills
are rendered beyond the imported map region.

The dock controls reference visibility and opacity, the terrain-sampled hex
grid, the min/max debug envelopes, and a city-core footprint marker whose
radius cannot exceed one authoring hex. Terrain3D's `maps_edited` signal is
translated to the affected raster rectangle and only that rectangle is
clamped. **Validate & publish** always performs a separate full-raster check
and refuses to publish any non-finite or out-of-envelope height.
`maxCitySlope` is loaded and preserved as reserved authoring metadata, but is
not advertised or enforced as a publication constraint yet: the domain has no
canonical city placement whose slope could be measured. Height envelopes are
the active constraints until that placement rule is defined in Rust.

**Save draft** persists manual Terrain3D regions and records
`mapContentHash`, `authoringProfileHash`, `generatedBaseHash`,
`generatorVersion`, raster dimensions, sample spacing, and `terrainRevision`.
Every region is hashed before an atomic pointer switch. **Validate & publish**
copies that verified snapshot into the separate immutable `published/`
collection, so a later draft cannot modify an earlier publication. **Reload
compiled base / constraints** updates generated inputs but never imports
`base` over existing manual terrain. Closing and reopening the scene verifies
the complete artifact identity and all region hashes before restoring the
working data.

If the stored identity differs, opening stops with an explicit compatibility
result: a constraint refresh for changed profile/base hashes, migration for a
changed raster grid or legacy layout, rejection for another logical map, or an
unsupported-generator result. Stored manual terrain is never combined with a
new compiled artifact silently.

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
Logical hex coordinates, compiled absolute world coordinates, raster pixels,
and Terrain3D-local coordinates are converted by one terrain-space value. A
reference translation, rotation, or scale is baked before sampling the final
Terrain3D height, so transformed artwork remains draped over the edited terrain.

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
- `editor/map_authoring/application/` owns the session and small catalog,
  persistence, scene-factory, scene-writer, and logical-workbench ports;
- `editor/map_authoring/infrastructure/` implements filesystem and snapshot
  adapters plus the native Rust workbench adapter without importing presentation;
- `editor/map_authoring/presentation/` owns the passive Terrain3D surface,
  scene factory, dock, and controls without constructing infrastructure;
- `editor/map_authoring/composition/` manually wires the ports and adapters;
- `addons/aonw_map_workbench/` only activates that composition root.

The Workbench dock separates its control view from editor orchestration. This
keeps widget construction independent from generation, undo/redo, and scene
persistence behavior. The application session still depends directly on
`Terrain3DData`; only filesystem persistence is behind a port.

`engine/crates/aonw_content` remains the authoritative logical validator and
hash owner. A generated Godot scene is a presentation artifact and never a
second source of gameplay rules.

`engine/crates/aonw_map_workbench` owns logical authoring/generation use cases
and a separate versioned protocol. `AonwMapWorkbenchBridge` exposes that
protocol to the editor without giving GDScript a canonical map writer.

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
make map-stage-1-check
```

`map-stage-1-check` exports normalized map semantics through the native Rust
adapter and compares them with Flutter. Visual goldens remain client-owned and
are not part of this gate.

The runner delegates to focused runtime-map, geometry, native-session,
Terrain3D-spike, and terrain-authoring suites. They cover strict Rust
validation, scenario bootstrap, native
snapshot/reachable/route/move and persistence calls, asset discovery, immutable
map views, projection/picking round trips, texture assembly, verified EXR
import, regional clamp, independent publish validation, metadata identities,
overlay alignment, undo/redo, base-regeneration safety, and final-terrain
save/reopen persistence. `GODOT_BIN` can override the editor executable.
