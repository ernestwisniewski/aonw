# Shared Logical Content

This directory contains versioned logical content consumed by Rust and client
presentation adapters. It is the source of truth for map topology, terrain,
resources, elevation, and objectives. Renderer meshes, textures, materials,
audio, and localization remain client-owned assets.

Map schema version 1 uses a complete odd-q, flat-top grid. Tiles are stored in
row-major order by the canonical serializer. The ordered `terrainTags` list is
the logical terrain source of truth. Its first value is the authored visual
identity, and its first non-river value owns the base economic yield. Movement
is normalized from the same profile.

For compatibility with the frozen client, schema v1 also carries derived
terrain projections on every tile:

- `terrains` is the normalized movement profile: exactly one primary terrain
  followed only by movement features;
- `displayTerrain` equals the first `terrainTags` value;
- `yieldTerrain` equals the first non-river `terrainTags` value and is never
  `river`.

Strict v1 loaders require all four values and reject inconsistent projections.
Runtime domain code owns one terrain profile and exposes named movement,
display, and yield views; consumers do not interpret list order themselves.
Only `terrainTags` participates in logical `contentHash`; the redundant v1
projections do not. Resource and objective order is normalized by
`aonw_content`, so content hashes remain deterministic. `defaultZoom` is kept
in the versioned document but excluded from logical identity.

Maps under `content/maps/` are the only logical maps consumed by Rust, Flutter,
the server, and Godot. Final client-owned artwork is generated separately under
`assets/runtime/maps/`; private source artwork and unversioned map JSON are not
runtime inputs. All shared maps must use the schema in
`schemas/map-v1.schema.json`.

Every map directory also owns a required `terrain_authoring.v1.json`. Its
`maxTerrainHeightMeters` maps logical height `5` to a map-specific metric
ceiling without changing gameplay rules or the logical map content hash.
Logical tile authoring is performed through Rust workbench commands. Each edit
replaces the canonical map/profile pair from validated Rust output, changes
`contentHash`, and refreshes the authoring profile identity; clients do not
construct these documents themselves.

`content/scenarios/` contains strict starting placements bound to one map ID
and one immutable ruleset ID. Rust validates both content identities before it
bootstraps revision-zero `GameState`. Scenario v1 uses
`schemas/scenario-v1.schema.json`; `aonw2_starter` supplies the first Godot
local session.
