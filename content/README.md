# Shared Logical Content

This directory contains versioned logical content consumed by Rust and client
presentation adapters. It is the source of truth for map topology, terrain,
resources, elevation, and objectives. Renderer meshes, textures, materials,
audio, and localization remain client-owned assets.

Map schema version 1 uses a complete odd-q, flat-top grid. Tiles are stored in
row-major order by the canonical serializer. Terrain order is meaningful: the
first entry is primary terrain. Resource and objective order is normalized by
`aonw_content`, so content hashes remain stable across semantically equivalent
input ordering.

The existing maps under `assets/maps/` remain unchanged for Flutter AoNW1.
`aonw_content::MapDefinition::from_legacy_json` is their explicit migration
adapter. New shared maps must use the schema in `schemas/map-v1.schema.json`.
