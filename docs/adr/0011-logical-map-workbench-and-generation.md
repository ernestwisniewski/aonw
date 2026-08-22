# ADR 0011: Logical Map Workbench And Procedural Generation Boundary

- Status: Accepted
- Date: 2026-08-22

## Context

The first Godot Map Workbench slice authors Terrain3D for logical maps that
already exist in shared content. AoNW also needs a future `New Map` flow,
logical terrain/resource/height painting, deterministic procedural generation,
and generated visual details such as trees and rocks.

Implementing these rules in GDScript would create another map domain. Mixing
generated and manual Godot nodes would also make regeneration destructive.

## Decision

Rust remains the sole owner of logical map construction, editing, validation,
canonical JSON and `contentHash`. Logical map authoring uses a dedicated
framework-neutral workbench protocol rather than the gameplay session
protocol.

The first slice provides `blankV1`. A strict `MapGenerationSpec` contains the
map identifier, odd-q dimensions, default zoom, metric hex radius, seed,
generator identifier and generator version. Rust produces four documents:

```text
map.json
terrain_authoring.v1.json
map_generation.v1.json
generated_decorations.v1.json
```

`map_generation.v1.json` records the complete spec and hashes of the spec,
logical map, terrain profile and generated-decoration plan. The blank generator
emits an empty decoration plan; later generators may add versioned visual tree,
rock, water and detail placements without putting presentation instances into
the logical map.

Godot receives exact document strings from Rust. A future filesystem adapter
may persist them atomically, but GDScript may not construct canonical map
fields or decide whether a logical terrain/resource/height edit is legal.
Future commands such as `SetTileTerrain`, `SetTileResources` and
`SetTileHeight` extend this workbench boundary.

Authored scenes contain separate `GeneratedWorld` and `ManualWorld` nodes.
Regeneration may replace only `GeneratedWorld`. Manual nodes and the manual
Terrain3D final remain outside the generated artifact lifecycle.

Logical height `0..=5` remains gameplay content. Metric base/min/max and final
Terrain3D samples remain separate authoring concepts. The standard v1 profile
derives metric envelopes from logical height and the selected metric hex
radius.

## Consequences

The current UI still opens existing maps; a complete `New Map` dialog and
logical paint mode are later vertical slices. Their backend boundary is now
executable and tested instead of being a speculative UI abstraction.

A seed participates in generation provenance even when `blankV1` produces the
same empty logical map for different seeds. Procedural generator versions may
use it while retaining deterministic replayability and explicit migrations.

## Verification

- Two executions of the same spec are byte-for-byte identical.
- Generated map and terrain documents pass their authoritative Rust decoders.
- A 40x30 generated map respects the existing content limits.
- Godot obtains all documents through the native Rust workbench bridge.
- Dependency checks reject canonical map-field writers in GDScript authoring.
- Godot scene tests require distinct generated and manual world containers.

## Related Decisions And Documentation

- [ADR 0008: Rust engine ownership and strangler migration](0008-rust-engine-ownership-and-strangler-migration.md)
- [ADR 0010: Terrain backend for Godot authoring](0010-terrain-backend-for-godot-authoring.md)
- [Successor refactor plan](../../.codex/aonw-successor-refactor-plan.md)
- [Godot Map Workbench](../../clients/aonw_godot/README.md)
