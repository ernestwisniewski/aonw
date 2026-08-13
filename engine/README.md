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
| `aonw_domain` | Validated identifiers, odd-q topology, fixed-point movement values, unit movement state, and deterministic world state. |
| `aonw_content` | Strict versioned map documents, an explicit legacy adapter, domain validation, normalization, lookup, and deterministic logical-content hashing. |
| `aonw_contracts` | Versioned, domain-independent boundary DTOs. It deliberately does not choose a wire codec yet. |
| `aonw_contract_mapping` | Validated conversion between boundary DTOs and domain types. |
| `aonw_engine` | Pure borrowed state inspection, terrain movement costs, and a revision-bound terrain route query behind an explicit actor/map `EngineContext`. |
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

The toolchain is pinned in `rust-toolchain.toml`, `unsafe` is forbidden across
the initial workspace, canonical entities preserve contract order in contiguous
storage and use private sorted secondary indices for deterministic lookup.
Boundary mappings validate all external input before domain construction.
Release builds retain integer overflow checks.

Reducer fixture version 2 requires ordered authoritative `movementExecutions`.
The testkit validates exact origin, non-empty steps, positive entry costs, and
checked cumulative costs. It reads legacy version 1 without treating absent
evidence as an explicit empty list; all new fixtures must use version 2.

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

The actor is command/query context, not canonical world state. `WorldStateDto`
therefore carries revision, turn, and entities only; `EngineContext` supplies
the actor and validated logical map explicitly at the rule boundary. This
breaking correction is represented by state contract version 2.

## Movement foundation

The current unit projection carries all data needed by the first movement
slice: stable type, owner, odd-q position, fixed-point movement balance,
posture, availability, queued route, and carried artifact. Boundary mapping
round-trips these values and validates queued coordinates and cumulative costs.

`GameEngine::plan_terrain_route` is a revision-bound, deterministic query for
Godot movement previews and later command parity. It uses row-major map indices,
a binary heap, known unit occupancy, exact odd-q order, fixed-point terrain
costs, and the current-turn boundary-step rule. It is deliberately named
terrain-only: fog, cities, diplomacy, roads, state mutation, events, and
authoritative movement evidence are not implemented by this query. Movement
balances above the ruleset maximum fail before allocation-heavy route search.

## Deliberately deferred

- gameplay command handlers, complete movement rules, and save codecs until the
  relevant reviewed Dart fixtures exist;
- FFI and GDExtension crates until the pure boundary is stable;
- local runtime, AI, recipient projection, and remote replica crates;
- any integration that could change the active Flutter or Serverpod runtime.
