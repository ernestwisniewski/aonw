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
| `aonw_contracts` | Current-only shared client API plus strict bounded canonical state, save, and replay codecs. |
| `aonw_contract_mapping` | Validated conversion between boundary DTOs and domain types. |
| `aonw_engine` | Authoritative movement queries/transitions and revision-bound cancel, skip, and fortify unit actions. |
| `aonw_local_runtime` | Transactional local-session lifecycle, player snapshots, query/command dispatch, and recipient-safe patches. |
| `aonw_godot` | Thin GDExtension translating Godot calls into the framework-neutral local runtime. |
| `aonw_flutter` | Panic-contained C ABI exposing the same client protocol to Flutter Native Assets. |
| `aonw_testkit` | Bounded fixture/corpus loader, duplicate-key rejection, structural state/event/execution diff, and engine-neutral runner for the shared reducer-parity corpus. |

The split enforces an inward dependency direction: contracts and domain do not
depend on one another, content depends only on domain coordinates, mapping
depends on contracts and domain, and the engine depends on domain plus validated
content. The testkit remains independent of every concrete engine backend.
Recipient state has no conversion into canonical domain state.

Large responsibilities are organized as modules instead of monolithic crate
roots: scenarios separate model, codec, bootstrap, canonicalization, and tests;
state mapping separates aggregate, unit, world, value, and error conversion;
local runtime sessions separate lifecycle, state, capabilities, and execution;
the engine separates application commands, queries, transitions, context, and
state-digest writing; the Godot adapter separates request parsing, response
mapping, and bindings. Reducer-parity support separates input decoding, JSON
helpers, and output projection from fixture execution.

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
approach, owned apply, direct local-runtime dispatch, and shared client JSON
workloads. Movement cases cover 1, 10, 64, and 512 units, including accepted,
rejected, and hidden no-op commands. Wall-clock values are diagnostic; stable
result signatures and search-work counters are test gates.

The 2026-08-14 reference run on the development Mac kept the 40×30, 512-unit
accepted runtime dispatch at about 1.46 ms p95, including state digest, replay
entry, recipient view patch, and JSON response at about 1.47 ms p95. Prepared
content hashes are reused by every command, and recipient views use a linear
merge over canonical ID order instead of temporary tree maps.

The toolchain is pinned in `rust-toolchain.toml`. Production rules and all
non-FFI crates forbid `unsafe`; the single required `unsafe impl` is confined to
the godot-rust extension entry point. Canonical entities preserve contract
order in contiguous storage and use private sorted secondary indices for
deterministic lookup. Boundary mappings validate all external input before
domain construction. Release builds retain integer overflow checks.

Reducer fixture version 2 requires ordered authoritative `movementExecutions`.
The current static corpus contains 44 fixtures: 38 movement cases and six
cancel/skip/fortify cases. Every fixture executes through canonical
`GameEngine::apply` and compares the complete Dart state envelope, rejection,
ordered events, and exact movement evidence. `aonw_testkit` accepts only the
current fixture contract. Rust and Godot boundaries use strict, current-only
codecs.

The characterization covers terrain bases and features, roads, partial and
queued movement, occupancy and hidden information, cities, fog, diplomatic
contact, posture, artifact capacity, rejection precedence, and exact movement
evidence. Both Dart reducers and Rust execute the same reviewed outcomes. Run
`make rust-engine-oracle` only to regenerate review candidates; generation
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

The actor is command/query context, not persisted state. `GameStateDto` version
3 is the strict current contract for all implemented authoritative state. It
persists artifacts and rule-relevant interaction state, including reversible
current-turn unit skips, without moving those rules into UI.
`EngineContext` supplies actor, permission, validated map, and immutable
ruleset; canonical fog and occupancy are derived from `GameState`.

## Movement foundation

`GameState` is the canonical aggregate root for the implemented simulation
slice. It uses the nominal `StateRevision`, preserves entity contract order in
contiguous storage, and maintains private sorted ID indices. Construction
validates map bounds, duplicate IDs, unit occupancy, artifact locations and
ownership, and rule-relevant interaction references.

The complete `Unit` entity preserves identity, display name, HP, XP, army,
queued and merchant routes, worker charges, posture, artifacts, and concrete
worker/founding/assignment/excavation activity. These independently persisted
activity slots may coexist in current game state. Manual movement availability
is derived from them; it is not a client-supplied canonical boolean.

`RulesetDefinition` owns all 17 unit movement allowances, movement domains,
capabilities, artifact allowance, and occupancy policy. `ScenarioDefinition`
links exact map and ruleset hashes to validated starting placements and can
bootstrap a revision-zero `GameState`. Map, ruleset, and scenario identities
are separate SHA-256 hashes with golden vectors.

Movement planning borrows `GameState` and canonical `Unit` entities directly.
There is no partial movement state contract or copied unit projection. The
canonical state codec validates queued coordinates and cumulative costs.

`GameEngine::query` and `apply` are the canonical full-state boundary.
Route/reachable planning uses row-major map
indices, bounded heap searches, actor-visible occupancy, exact odd-q order, and
fixed-point terrain costs. Occupied targets use deterministic approach planning.
Hidden occupancy is resolved only during apply, which returns an accepted no-op
rather than disclosing the blocker. Accepted movement returns a new revision,
recomputed fog and diplomatic contacts, an ordered `UnitMovedEvent`, exact
authoritative execution evidence, state digest, map hash, and ruleset hash.

`CancelUnitAction`, `SkipUnitTurn`, and `FortifyUnit` use the same full-state
boundary and rejection semantics. Skip records its restorable movement inside
canonical `InteractionState`; cancel clears unit-owned interaction,
queued/activity/merchant orders, restores an interrupted excavation artifact to
its map coordinate, and wakes the unit. Fortify accepts only an idle controlled
unit. These actions emit no synthetic movement events or evidence.

`aonw_local_runtime::LocalRuntime` owns one validated local session. Opening is
transactional, closing is idempotent, and every snapshot, query, and dispatch
response carries behavior version, revision, state digest, map hash, and ruleset
hash. It exposes full recipient-safe snapshots, reachable and route queries,
revision-bound commands, ordered events, exact execution evidence, and view
patches including unit posture.
Recipient unit views are sorted by stable unit identifier before snapshots and
linear patch generation, independently from canonical contract order. Event
offset capacity is checked before an owned-state dispatch can begin.

`aonw_contracts::client` owns the single client protocol shared by Godot and
Flutter native adapters. `ClientRequestDto` contains tagged lifecycle,
command, and query operations. `ClientResponseDto` contains only recipient-safe
snapshots, patches, events, evidence, persistence documents, and stable errors;
canonical `GameStateDto` never crosses this boundary. The protocol accepts only
`CLIENT_API_VERSION` and has no historical readers or upcasters. Rust in-process
runtime types deliberately have no version suffix.

The shared golden documents in `test/fixtures/client_protocol` are consumed by
Rust, Godot, and Dart tests. Native adapters report `CLIENT_API_VERSION`; each
client owns the same supported constant and rejects an incompatible adapter or
response before inspecting its payload. Map authoring output comes from `MapDocument::to_versioned_json`
so the Godot bridge does not maintain a second map serializer.

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

`aonw_godot::AonwLocalSession` exposes one `request_json` transport operation.
It decodes and encodes `aonw_contracts::client` documents and delegates every
lifecycle, query, command, save, and replay operation to `ClientProtocol` in
`aonw_local_runtime`. Godot obtains units from the recipient snapshot and never
constructs a synthetic canonical unit. Build it with `make rust-godot-build`.

`aonw_flutter` exposes the same dispatcher through a panic-contained C ABI.
`packages/aonw_rust_client` bundles it with Flutter build hooks and keeps native
calls on a helper isolate. Its strict Dart read models cover snapshots, queries,
commands, events, evidence, patches, and persistence results. Normal builds use
an unavailable C stub, so the Dart local engine remains buildable and active.
`make rust-flutter-test` verifies both lanes. A concrete Flutter
`LocalEnginePort` remains gated on lossless complete-state mapping.

## Save and replay

`aonw_contracts` owns separate current-only save and replay schemas. A save
contains the complete `GameStateDto`, behavior version, exact map and ruleset
identities, actor, deterministic RNG position, event offset, and canonical
state digest. Restore is transactional and rejects mismatched content, behavior,
state invariants, or digest before replacing an open session.

The bounded replay segment stores its complete initial state and context, then
each revision-bound command with pre-command context and the exact rejection,
events, execution evidence, RNG position, event offset, revision, and resulting
digest. Verification executes every command again through `GameEngine` and
fails on the first context or result drift. The recorder rolls to a new
checkpoint after 512 commands; adapters own filesystem paths and I/O.

Godot sends save/open and replay export/verification through the same tagged
client protocol as every other operation. Persistence rules remain in Rust.

## Deliberately deferred

- historical client/save/replay upcasters and long-term compatibility manifests;
- production Flutter session cutover and cross-target Rust packaging;
- AI and remote replica crates;
- any integration that could change the active Flutter or Serverpod runtime.
