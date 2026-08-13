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
        └── grid_mesh.res
```

The authored scene contains the generated surface plus models and other nodes
added in Godot. Regeneration refreshes `AonwMap3D` while preserving authored
sibling nodes and custom children attached to the surface. The generated
surface contains three independent layers:

- `BaseTerrain` is an elevated hex surface colored from logical terrain data;
- `ReferenceTexture` projects the original stitched `NxM.jpg` artwork and has
  configurable visibility and opacity;
- `HexGrid` is a separately configurable grid overlay.

In the **AoNW Map** dock, use **Show hex outlines** to toggle the overlay.
**Outline opacity** controls its opacity, while **Texture opacity** controls the
original reference artwork. These controls update the open generated scene and
are synchronized when another map scene is opened. **Outline width** changes
the geometry width so the grid remains readable over detailed artwork.

`Hex height` controls how logical tile heights shape the mesh. Geometry changes
are debounced, participate in editor undo/redo, and are persisted by **Save
current scene**. The Workbench writes settings and meshes to a new immutable
generation, saves the authored scene, and only then publishes that generation
in the manifest. A failed save therefore cannot leave a scene referring to a
partially overwritten mesh set. Generated textures and meshes are Godot resources, so
reopening the scene does not load the original JPG slices again. The reference
atlas preserves native tile dimensions up to the preview cap rather than
upsampling smaller artwork. Regenerate the scene after changing the source map
or its tile artwork. The manifest records the source identity, content hash,
source tile size, active generation, and render settings.

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
reachable overlay layers. The preview seeds one developer unit: click it to
query reachable hexes from Rust, then click a highlighted hex to execute and
animate the authoritative `UnitMoved` event. These layers contain no movement
legality rules.

## Boundaries

- `domain/map/` owns the immutable renderer read model and odd-q geometry;
- `application/map/` orchestrates loading and Godot scene generation;
- `infrastructure/map/` discovers files, decodes JSON, assembles textures, and
  persists Godot resources;
- `infrastructure/engine/` adapts JSON at the GDExtension boundary;
- `presentation/` owns meshes, camera, runtime UI, and editor controls;
- `addons/aonw_map_workbench/` is the editor composition root.

`engine/crates/aonw_content` remains the authoritative logical validator and
hash owner. A generated Godot scene is a presentation artifact and never a
second source of gameplay rules.

The `aonw_godot` GDExtension is connected to map loading. Strict versioned maps
are validated by `aonw_content` before the immutable Godot render view is
created. `AonwNativeLocalSession` exposes reachable queries and
revision-bound movement from Rust; unit/entity presentation can consume its
results without calculating legality or paths in GDScript.

The native adapter rejects oversized movement-state and visibility documents
before JSON decoding, then applies the same unit, route, identifier, and balance
limits as the framework-neutral Rust mapping boundary. These are safety limits,
not gameplay balance configured by Godot.

Build the native adapter before opening or running Godot:

```sh
make rust-godot-build
```

`make godot-editor`, `make godot-run`, and `make godot-test` build it
automatically. The Makefile also discovers Cargo in the default rustup location
when it is not present in the interactive shell `PATH`.

## Verification

```sh
make godot-test
make godot-check
```

The test covers strict Rust validation, native reachable/move calls,
asset discovery, immutable map views, projection/picking round trips, texture
assembly, mesh generation, regeneration safety, and preserving authored nodes.
`GODOT_BIN` can override the editor executable.
