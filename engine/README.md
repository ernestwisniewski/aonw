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
| `aonw_domain` | `GameState`, complete unit entities, validated identifiers, odd-q topology, and fixed-point values. |
| `aonw_content` | Strict maps, immutable rulesets and scenarios, catalogs, validation, and separate deterministic content hashes. |
| `aonw_contracts` | Versioned boundary DTOs and a strict bounded canonical-state JSON codec. |
| `aonw_contract_mapping` | Validated conversion between boundary DTOs and domain types. |
| `aonw_engine` | Fog-safe movement planning, reachable-hex queries, and the revision-bound authoritative `MoveUnit` transition. |
| `aonw_local_runtime` | Transactional local-session lifecycle, player snapshots, query/command dispatch, and recipient-safe patches. |
| `aonw_godot` | Thin GDExtension translating Godot calls into the framework-neutral local runtime. |
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

Run the diagnostic release baseline separately:

```sh
make rust-benchmark
```

It reports map open/hash plus raw and prepared reachable/route, occupied-target
approach, and apply workloads for 100, 600, and 1200 tiles. Movement cases cover
1, 10, 64, and 512 units. The native boundary opens a strict 1200-tile scenario
with 512 units. Wall-clock values are diagnostic; stable result signatures and
search-work counters are test gates.

The toolchain is pinned in `rust-toolchain.toml`. Production rules and all
non-FFI crates forbid `unsafe`; the single required `unsafe impl` is confined to
the godot-rust extension entry point. Canonical entities preserve contract
order in contiguous storage and use private sorted secondary indices for
deterministic lookup. Boundary mappings validate all external input before
domain construction. Release builds retain integer overflow checks.

Reducer fixture version 2 requires ordered authoritative `movementExecutions`.
The current static corpus contains 38 movement fixtures: three original cases
and the complete 35-case Dart characterization. Every fixture executes through
canonical `GameEngine::apply` and compares the complete Dart state envelope,
rejection, ordered events, and exact movement evidence. `aonw_testkit` accepts
only the current fixture contract. Rust and Godot boundaries use strict,
versioned codecs.

The characterization covers terrain bases and features, roads, partial and
queued movement, occupancy and hidden information, cities, fog, diplomatic
contact, posture, artifact capacity, rejection precedence, and exact movement
evidence. Both Dart reducers and Rust execute the same reviewed outcomes. Run
`make rust-movement-oracle` only to regenerate review candidates; generation
never blesses a changed oracle.

## Map content contract

`MapDocument` represents the editable versioned document and carries the
presentation-only `defaultZoom` hint. `MapDefinition` is the validated logical
map. Its compact `canonical_bytes()` output is exactly what `content_hash()`
hashes; presentation hints are excluded. Resource order uses an explicit stable
wire rank, so enum source order cannot change canonical bytes.

Versioned documents fail closed on missing, unknown, duplicated, or invalid
fields and apply no compatibility defaults. Authored `MapDocument` values
retain the schema's 5×5 minimum, while logical `MapDefinition` values accept
smaller positive grids constructed inside deterministic engine test adapters,
such as the existing 3×3 movement oracle. Map bounds expose canonical odd-q
neighbors and row-major indices without allocation.

The actor is command/query context, not persisted state. `GameStateDto` is the
strict current contract for all movement-authoritative state. `MovementStateDto`
remains a temporary adapter projection and is not a save format.
`EngineContext` supplies actor, permission, validated map, and immutable
ruleset; canonical fog and occupancy are derived from `GameState`.

## Movement foundation

`GameState` is the canonical aggregate root for the implemented simulation
slice. It uses the nominal `StateRevision`, preserves unit contract order in contiguous storage,
and maintains a private sorted ID index. Construction validates map bounds,
duplicate IDs, and the occupancy policy selected by the ruleset.

The complete `Unit` entity preserves identity, display name, HP, XP, army,
queued and merchant routes, worker charges, posture, artifacts, and concrete
worker/founding/assignment/excavation activity. Manual movement availability is
derived from that activity; it is not a client-supplied canonical boolean.

`RulesetDefinition` owns all 17 unit movement allowances, movement domains,
capabilities, artifact allowance, and occupancy policy. `ScenarioDefinition`
links exact map and ruleset hashes to validated starting placements and can
bootstrap a revision-zero `GameState`. Map, ruleset, and scenario identities
are separate SHA-256 hashes with golden vectors.

The earlier `MovementState` remains an internal compatibility projection used
inside movement planning. Godot does not load it and it is not a save format.

The current unit projection carries all data needed by the first movement
slice: stable type, owner, odd-q position, fixed-point movement balance,
posture, availability, queued route, and carried artifact. Boundary mapping
round-trips these values and validates queued coordinates and cumulative costs.

`GameEngine::query` and `apply` are the canonical full-state boundary.
Route/reachable planning uses row-major map
indices, bounded heap searches, actor-visible occupancy, exact odd-q order, and
fixed-point terrain costs. Occupied targets use deterministic approach planning.
Hidden occupancy is resolved only during apply, which returns an accepted no-op
rather than disclosing the blocker. Accepted movement returns a new revision,
recomputed fog and diplomatic contacts, an ordered `UnitMovedEvent`, exact
authoritative execution evidence, state digest, map hash, and ruleset hash.

`aonw_local_runtime::LocalRuntime` owns one validated local session. Opening is
transactional, closing is idempotent, and every snapshot, query, and dispatch
response carries contract and behavior versions, revision, state digest, map
hash, and ruleset hash. It exposes full recipient-safe snapshots, reachable and
route queries, revision-bound movement, ordered events, exact execution
evidence, and view patches.

The runtime prepares `CompiledMovementMap` once per map/ruleset, keeps
tile-indexed visibility, builds occupancy as a compact bitset, reuses reachable
search buffers, and caches the last query by revision, unit, state/visibility
digest, map hash, ruleset hash, and target. Occupied-target approach uses one
multi-target search. Batch queries reuse the same cache and buffers.

The hot dispatch path consumes owned `GameState`, reuses its entity allocation,
and consumes `DomainTransition::into_parts`; it does not clone the complete
state for a normal local apply. Borrowed `GameEngine::apply` remains available
for compatibility and tests. Prepared and raw paths have deterministic parity
tests. Rayon, ECS, SIMD, GPU pathfinding, custom allocators, and `unsafe` are not
used because the measured 1200-tile workload does not justify them.

`aonw_godot::AonwLocalSession` validates strict map and scenario documents,
then delegates lifecycle and simulation to `aonw_local_runtime`. Godot obtains
units from the runtime snapshot and never constructs a synthetic canonical
unit. Build it with `make rust-godot-build`.

## Deliberately deferred

- canonical save/replay envelopes and state upcasters;
- Flutter/native C ABI and production packaging beyond the Godot debug adapter;
- AI and remote replica crates;
- any integration that could change the active Flutter or Serverpod runtime.
