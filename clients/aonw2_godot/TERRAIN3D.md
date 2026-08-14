# Terrain3D backend for AoNW2

The AoNW map remains a logical odd-q hex map owned by the shared Rust/content
layer. Terrain3D is an optional Godot presentation backend. It never decides
movement legality, path costs, visibility, resources, or multiplayer state.

## What is implemented

The Map Workbench can generate either:

- `Legacy mesh` — the existing deterministic `ArrayMesh` surface;
- `Terrain3D` — height, control, and color maps imported into Terrain3D regions.

The legacy meshes are still generated and persisted when Terrain3D is selected.
They provide a deterministic fallback and retain the original map editing
context. The visible Terrain3D surface is generated from the same center and
shared-corner heights as the legacy mesh.

Generated data is stored inside the immutable map generation:

```text
assets/generated_maps/<map_id>/generations/generation-NNNNNN/
├── map.json
├── render_settings.tres
├── terrain_mesh.res
├── reference_mesh.res
├── grid_mesh.res
└── terrain3d/
    └── terrain3d_*.res
```

The manifest records the selected backend, actual Terrain3D version, region
size, sample density, image dimensions, import origin, vertex spacing, and data
directory.

## Install Terrain3D

The addon is intentionally not vendored. The project and legacy tests continue
to load when Terrain3D is absent.

Install the pinned release from the repository root:

```sh
python3 clients/aonw2_godot/tools/install_terrain3d.py
```

The installer downloads Terrain3D 1.0.2-stable, verifies its pinned SHA-256
checksum, and atomically installs only `addons/terrain_3d/`. For an offline
installation, download the official release archive separately and run:

```sh
python3 clients/aonw2_godot/tools/install_terrain3d.py \
  --archive /path/to/Terrain3D_v1.0.2-stable.zip
```

Then:

1. Open `clients/aonw2_godot/project.godot` in Godot.
2. Enable the Terrain3D editor plugin in **Project Settings → Plugins**.
3. Restart Godot and confirm the editor console contains no GDExtension load
   error.
4. Open **AoNW Map** in the editor dock. Its status line must say that
   Terrain3D is available.

Installation through AssetLib is also possible, but production and CI work
should use the pinned installer so all developers use the same addon build.

The `Godot Terrain3D` GitHub Actions workflow downloads the same pinned Godot
4.7.1 and Terrain3D 1.0.2 archives, verifies both checksums, and runs the full
headless map/editor suite for every relevant pull request.

The initial integration targets Terrain3D 1.0.2. The AoNW2 project currently
uses Godot 4.7, while the published Terrain3D 1.0.2 binaries explicitly target
Godot 4.4–4.6+. Verify the GDExtension on the exact Godot build used for AoNW2.
If the packaged library does not load, build Terrain3D against the matching
Godot/godot-cpp version before enabling this backend.

## Generate a map

1. Run `make godot-editor` from the repository root.
2. In the **AoNW Map** dock, select a map.
3. Set **Rendering backend** to **Terrain3D**.
4. Start with:
   - Samples per hex radius: `8`;
   - Region size: `256`;
   - Hex height: `0.16`.
5. Select **Generate / update 3D**.
6. Save authored models with **Save current scene**.

Generation fails before publishing a scene when Terrain3D is missing, its API
is incompatible, no regions are imported, or no region files are written. The
previous active generation remains valid.

## Rendering behavior

- Height maps use `Image.FORMAT_RF`.
- Control maps use `Image.FORMAT_RF` with Terrain3D's packed 32-bit layout.
- Color maps use `Image.FORMAT_RGBA8`.
- Pixels outside the union of logical hexes are Terrain3D holes.
- Original stitched JPG artwork is blended into the Terrain3D color map.
- The separate reference mesh is hidden while Terrain3D is active.
- Hex grid, selection, reachable overlays, units, and movement animations sample
  the active Terrain3D height where possible.
- Mouse picking uses `Terrain3D.get_intersection()` while this backend is active
  and falls back to the deterministic legacy triangle picker on adapter errors.
- Physics collision is disabled because AoNW does not need collision to pick or
  query terrain height.

## Stable texture IDs

Control-map texture identifiers are defined in
`presentation/map/terrain/terrain_visual_catalog.gd`. They are persisted data;
do not reorder or reuse them without a migration.

The first catalog is:

```text
0 ocean
1 coast / lake / river
2 grassland
3 plains
4 forest / jungle
5 hills
6 mountain
7 desert
8 tundra / snow
9 wetlands
```

The current implementation uses the color map as the production-safe visual
fallback. Terrain3D texture assets can be added later as long as these IDs stay
stable.

## Verification

The pinned installer has a dependency-free Python test suite:

```sh
python3 -m unittest discover \
  -s clients/aonw2_godot/tools \
  -p 'test_*.py'
```

Without Terrain3D installed, the standard Godot test run validates
rasterization, control bits, settings compatibility, fallback generation, and
the clean error path:

```sh
make godot-test
make godot-check
```

When Terrain3D is installed, the same suite also generates and verifies region
resources. Before publishing builds, test the actual GDExtension on every target
platform and renderer used by AoNW2.
