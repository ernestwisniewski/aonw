# AoNW Rust Engine

This directory is the Cargo workspace for the future authoritative Age of New
Worlds rules engine. The production domain, content, contracts, mapping, and
engine graph is independent of Flutter, Godot, Serverpod, filesystem, network,
wall-clock time, and presentation code. `aonw_testkit` is outer test tooling
and owns bounded filesystem access to committed fixtures.

The current code is a foundation, not a production backend. Dart
`packages/aonw_core` remains authoritative until the parity, compatibility,
platform, shadow, canary, and rollback gates in the
[migration plan](../docs/rust-engine-migration.md) pass.

## Current crates

| Crate | Responsibility |
| --- | --- |
| `aonw_domain` | Validated identifiers, odd-q topology, fixed-point movement values, and the immutable movement-state projection. |
| `aonw_content` | Strict versioned map documents, an explicit legacy adapter, domain validation, normalization, lookup, and deterministic logical-content hashing. |
| `aonw_contracts` | Versioned, domain-independent boundary DTOs. It deliberately does not choose a wire codec yet. |
| `aonw_contract_mapping` | Validated conversion between boundary DTOs and domain types. |
| `aonw_engine` | Fog-safe movement planning, reachable-hex queries, and the revision-bound authoritative `MoveUnit` transition. |
| `aonw_godot` | Thin GDExtension exposing Rust map validation and an in-process movement session to Godot. |
| `aonw_testkit` | Bounded fixture/corpus loader, duplicate-key rejection, structural state/event/execution diff, and engine-neutral runner for the shared reducer-parity corpus. |

The split enforces an inward dependency direction: contracts and domain do not
depend on one another, content depends only on domain coordinates, mapping
depends on contracts and domain, and the engine depends on domain plus validated
content. The testkit remains independent of every concrete engine backend.
Recipient state has no conversion into canonical domain state.

## Quality gates

Run the complete standalone Rust gate from the repository root:

```sh
make rust-check
```

The component targets are `rust-format-check`, `rust-clippy`, `rust-test`, and
`rust-doc`. They are intentionally independent of the existing Dart/Flutter
`make ci` target during this migration phase.

The toolchain is pinned in `rust-toolchain.toml`. Production rules and all
non-FFI crates forbid `unsafe`; the single required `unsafe impl` is confined to
the godot-rust extension entry point. Canonical entities preserve contract
order in contiguous storage and use private sorted secondary indices for
deterministic lookup. Boundary mappings validate all external input before
domain construction. Release builds retain integer overflow checks.

Reducer fixture version 2 requires ordered authoritative `movementExecutions`.
Three reviewed movement fixtures now execute through `GameEngine` and compare
complete state, rejection, events, and exact movement evidence. The remaining
legacy corpus stays readable as version 1 without inventing absent evidence.

## Map content contract

`MapDocument` represents the editable versioned document and carries the
presentation-only `defaultZoom` hint. `MapDefinition` is the validated logical
map. Its compact `canonical_bytes()` output is exactly what `content_hash()`
hashes; presentation hints are excluded. Resource order uses an explicit stable
wire rank, so enum source order cannot change canonical bytes.

Versioned documents fail closed on missing, unknown, duplicated, or invalid
fields. Defaults exist only in the explicit legacy Flutter map adapter.
Authored `MapDocument` values retain the schema's 5×5 minimum, while logical
`MapDefinition` values accept smaller positive grids for deterministic engine
fixtures such as the existing 3×3 movement oracle. The explicit logical
legacy decoder bypasses only authored camera and minimum-size constraints; it
retains strict JSON decoding and all logical-map invariants. Map bounds expose
canonical odd-q neighbors and row-major indices without allocation.

The actor is command/query context, not persisted state. `MovementStateDto` is
explicitly a partial projection containing revision, turn, and movement unit
data. Adapters must apply returned changes without dropping unrelated canonical
fields. `EngineContext` supplies actor, permission, validated map, and the
actor-visible occupancy projection.

## Movement foundation

The current unit projection carries all data needed by the first movement
slice: stable type, owner, odd-q position, fixed-point movement balance,
posture, availability, queued route, and carried artifact. Boundary mapping
round-trips these values and validates queued coordinates and cumulative costs.

`GameEngine::plan_terrain_route` and `reachable_movement` use row-major map
indices, bounded heap searches, actor-visible occupancy, exact odd-q order, and
fixed-point terrain costs. Occupied targets use deterministic approach planning.
Hidden occupancy is resolved only by `apply_move_unit`, which returns an
accepted no-op rather than disclosing the blocker. Accepted movement returns a
new revision, `UnitMovedEvent`, and exact authoritative execution steps.

`aonw_godot` validates strict or explicit legacy maps in Rust and exposes
`AonwLocalSession` for movement projection load, reachable queries, and
revision-bound moves. Build it with `make rust-godot-build`. This is a narrow
vertical slice, not the complete save/local-runtime boundary.

## Deliberately deferred

- full canonical state/save codecs and the remaining movement inputs such as
  roads, cities, diplomacy, complete fog state, and rulesets;
- Flutter/native C ABI and production packaging beyond the Godot debug adapter;
- local runtime, AI, recipient projection, and remote replica crates;
- any integration that could change the active Flutter or Serverpod runtime.
