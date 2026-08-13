# Shared Logical Content

This directory contains versioned logical content consumed by Rust and client
presentation adapters. It is the source of truth for map topology, terrain,
resources, elevation, and objectives. Renderer meshes, textures, materials,
audio, and localization remain client-owned assets.

Map schema version 1 uses a complete odd-q, flat-top grid. Tiles are stored in
row-major order by the canonical serializer. Every terrain list contains
exactly one primary terrain as its first entry, followed only by feature
terrains. Resource and objective order is normalized by `aonw_content`, so
content hashes remain stable across semantically equivalent input ordering.

The existing maps under `assets/maps/` remain unchanged for Flutter AoNW1.
Their versioned counterparts under `content/maps/` are the only logical maps
consumed by Rust and Godot. Existing JPG slices remain reference artwork for
Godot, but the unversioned JSON files are not part of the new runtime boundary.
All shared maps must use the schema in `schemas/map-v1.schema.json`.

`content/scenarios/` contains strict starting placements bound to one map ID
and one immutable ruleset ID. Rust validates both content identities before it
bootstraps revision-zero `GameState`. Scenario v1 uses
`schemas/scenario-v1.schema.json`; `aonw2_starter` supplies the first Godot
local session.
