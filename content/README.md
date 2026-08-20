# Shared Logical Content

This directory contains versioned logical content consumed by Rust and client
presentation adapters. It is the source of truth for map topology, terrain,
resources, elevation, and objectives. Renderer meshes, textures, materials,
audio, and localization remain client-owned assets.

Map schema version 1 uses a complete odd-q, flat-top grid. Tiles are stored in
row-major order by the canonical serializer. Terrain meaning is explicit and
split by bounded context on every tile:

- `terrains` is the normalized movement profile: exactly one primary terrain
  followed only by movement features;
- `displayTerrain` is the authored visual identity;
- `yieldTerrain` owns the base economic yield and is never `river`;
- `terrainTags` is the complete authored tag set used by combat, economy, AI,
  and presentation rules.

The strict loaders require all four values and validate their relationships;
runtime code never derives one meaning from list order. Resource and objective
order is normalized by `aonw_content`, so content hashes remain deterministic.

Maps under `content/maps/` are the only logical maps consumed by Rust, Flutter,
the server, and Godot. Final client-owned artwork is generated separately under
`assets/runtime/maps/`; private source artwork and unversioned map JSON are not
runtime inputs. All shared maps must use the schema in
`schemas/map-v1.schema.json`.

`content/scenarios/` contains strict starting placements bound to one map ID
and one immutable ruleset ID. Rust validates both content identities before it
bootstraps revision-zero `GameState`. Scenario v1 uses
`schemas/scenario-v1.schema.json`; `aonw2_starter` supplies the first Godot
local session.
