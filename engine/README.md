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
| `aonw_domain` | `GameState`, complete unit and city entities, validated identifiers, odd-q topology, and fixed-point values. |
| `aonw_content` | Strict maps, immutable rulesets and scenarios, catalogs, validation, and separate deterministic content hashes. |
| `aonw_map_authoring` | Metric terrain-authoring profiles bound to, but excluded from, logical map identity. |
| `aonw_map_compiler` | Pure deterministic compilation of authoring profiles into bounded base/min/max height rasters. |
| `aonw_map_compiler_cli` | Thin filesystem adapter that writes compiled terrain as OpenEXR, raw R16, and a strict manifest. |
| `aonw_contracts` | Current-only shared client API plus strict bounded canonical state, save, and replay codecs. |
| `aonw_contract_mapping` | Validated conversion between boundary DTOs and domain types. |
| `aonw_engine` | Authoritative movement, unit actions, logistics, combat, DP/TG policy queries, and the capability-gated turn kernel with a separate trusted lifecycle boundary. |
| `aonw_local_runtime` | Transactional local sessions, player/system replay records, recipient-safe lifecycle snapshots/patches, and query/command dispatch. |
| `aonw_godot` | Thin GDExtension translating Godot calls into the framework-neutral local runtime. |
| `aonw_flutter` | Panic-contained C ABI exposing the same client protocol to Flutter Native Assets. |
| `aonw_testkit` | Bounded canonical fixture/corpus loader, duplicate-key rejection, structural output diff, and engine-neutral runner for current contracts. |

The split enforces an inward dependency direction: contracts and domain do not
depend on one another, content depends only on domain coordinates, map
authoring depends on validated content, the pure map compiler depends on
authoring, its CLI owns terrain artifact I/O, mapping depends on contracts and
domain, and the engine depends on domain plus validated content. The testkit
remains independent of every concrete engine backend.
Recipient state has no conversion into canonical domain state.

Large responsibilities are organized as modules instead of monolithic crate
roots: scenarios separate model, codec, bootstrap, canonicalization, and tests;
state mapping separates aggregate, identity, economy, city, unit, world, value,
and error conversion;
local runtime sessions separate lifecycle, state, capabilities, and execution;
the engine separates application commands, queries, transitions, context, and
state-digest writing; the Godot adapter separates request parsing, response
mapping, and bindings. Canonical fixture support separates strict parsing,
bounded loading, structural comparison, and engine execution.

## Terrain compilation

Run the thin artifact writer from `engine/` with an explicit logical map,
authoring profile, output directory, and optional samples-per-hex density:

```sh
cargo run --locked -p aonw_map_compiler_cli --bin aonw-map-compiler -- \
  ../content/maps/aonw2_starter/map.json \
  ../content/maps/aonw2_starter/terrain_authoring.json \
  ../build/terrain/aonw2_starter 8
```

The output contains independent `base`, `min`, and `max` OpenEXR and raw R16
rasters plus `terrain_compile.json`. Regeneration creates no `final` raster;
manual terrain remains caller-owned and can only be constrained through the
explicit region-clamp API.

## Quality gates

Run the complete standalone Rust gate from the repository root:

```sh
make rust-check
```

The component targets are `rust-format-check`, `rust-clippy`, `rust-test`,
`rust-doc`, and the release compile-smoke for both native adapters. The required
fast aggregate is `make successor-engine-check`; `make
successor-engine-evidence-check` separately generates parity, LLVM coverage,
and structural-performance evidence. Both are included in the repository-wide
`make ci`/`make release-check` path, while the release-mode deep aggregate is a
separate scheduled workflow.

`cargo-llvm-cov 0.9.0` performs source instrumentation and exports LCOV plus
LLVM JSON. The repository checker adds only the project-specific crate census
and historical ratchet: authoritative and local-runtime ratios cannot fall,
uncovered lines cannot grow, and a new uninstrumented production file is
accepted only when it is purely declarative; executable files must be measured.
Adapter, authoring, generated, platform, test, and testkit scopes are classified
separately rather than diluted into one host-dependent denominator.

The performance harness uses `stats_alloc 0.1.10` as its counting allocator.
Setup and three warm-up runs occur outside the single-threaded measured region;
twenty identical allocation samples are required before a workload is accepted.
The hard gate covers result signatures, domain work counters, allocations,
allocated bytes, and payload bytes. Wall-clock medians and p95 values remain
diagnostic because ordinary CI runners are not stable timing references.
Criterion/Divan would improve host-local timing analysis but would not replace
these structural metrics. Gungraun (formerly Iai-Callgrind) remains a possible
future Linux-only deep diagnostic, not a substitute for the portable structural
gate. T1 adds
allocation/payload workloads for partial submit, trusted timeout finalization,
participant removal, client JSON submit, and exact replay verification at
1/64/512 units. Run its complete focused gate with `make
rust-turn-kernel-check`. U2 adds 21 allocation/work-counter workloads for
auto-explore apply/options and long merchant routes at the same scales; run its
focused gate with `make rust-movement-logistics-check`. C3 adds 20 workloads
for combat preview/apply, bounded mass-turn resolution, runtime dispatch, and
client JSON at 10/64/512-unit scales. The mass workload resolves at most 32
attacker/defender pairs per turn, and its complete focused gate is `make
rust-combat-check`. C4 adds city founding and territory workloads. W5 brings the
reviewed census to 174 workloads and adds nine worker cases: options, automation
apply, and mass job completion on 100/600/1200-tile maps with up to 1199
workers. Its focused gate is `make rust-worker-check`.

The migration inventory under [`migration/`](migration/README.md) closes the
authoritative surface before new Rust behavior is added. `p0-check` runs its
dependency-free source census and negative fixtures; the analyzer-backed Dart
AST census and exact field ledger run through
`rust-engine-inventory-ast-check`. Together they compare 39 player commands,
two trusted system commands, eight queries, 40 mapped plus four native domain
events, one mapped plus four native evidence types, eight recipient projection
types and nine pending-action variants, 30 Dart `DomainState` fields, 10 boundary
envelopes, and all 120 reducer fixtures. The inventory remains migration
evidence; active Rust execution gates use only typed current contracts and do
not preserve opaque Dart JSON.

The determinism inventory separately names all seven current oracle
randomness/seed derivations and both wall-clock reads. Its dependency-free
guard rejects unregistered sources, system time/randomness in pure Rust engine
crates, and generic persisted RNG state. `make rust-determinism-check` also
proves the same canonical replay signature in debug and release builds.

The 120-case reducer evidence has a separate reviewed disposition ledger. It
does not restore a reader for that historical envelope: a dependency-free
guard binds the corpus by filenames and aggregate blob identity, requires each
case to have either current structural round-trip evidence or an explicit
future checkpoint, and rejects any Rust source that reads the old corpus.
`make rust-corpus-parity-check` executes only the nine root cases whose current
canonical artifacts and four player-command capabilities are promoted to
`engine-parity`; 72 remain blocked `reference-only`, while 39 are historical
`reference-only` cases superseded by separately reviewed current contracts
through U2, C3, C4, and W5. No Rust reader parses their historical envelope.

## Greenfield compatibility policy

The engine and successor clients evolve one current contract atomically. New
files, types, snapshots, fixtures, codecs, and adapter boundaries do not receive
speculative `v1` suffixes, schema counters, upcasters, or historical readers.
A format version is introduced only when a concrete independently deployed
consumer, supported production save/replay, or rollback path requires two
formats at the same time. The decision then names the compatibility period and
removal condition.

Pinned dependency/toolchain versions, Git tree identities, content hashes, and
build IDs remain useful for reproducibility and diagnostics; they do not by
themselves create a compatibility API. The CP0 audit removed internal canonical
state, engine behavior, and save/replay counters. Shared client and workbench
API versions remain because independently built Rust, Godot, and Flutter
components consume those boundaries.

The public mutation family is `PlayerCommand`; it contains only commands a
player client may issue. Trusted lifecycle mutations use the separate
`SystemCommand` and `GameEngine::apply_system_owned` boundary, whose context has
no player actor. They do not exist in `ClientCommandDto`, the successor client
protocol, or any player adapter. No legacy command adapter or compatibility
alias is retained.

T1 advertises `turn-kernel-ready`, not full turn parity. CP8/U2 extends its
ordered processors with queued movement, merchant routes, and scout
auto-exploration. CP9/C3 adds deterministic intended-attack resolution for
simultaneous multiplayer turns. CP11/W5 adds worker construction completion and
bounded deterministic automation. Economy, diplomatic turn processing,
research, agreements, and objectives remain explicitly disabled; states
requiring them fail closed with `turn_processor_unsupported`. The full integrated
turn remains an O9 capability.

The DP policy foundation exposes one pure `DiplomacyPolicyQuery` for hostility,
foreign city and territory entry, attack protection, automation, trade, and
recipient disclosure. Missing relations use the current neutral rule default,
but remain hidden until contact; unknown participants fail closed with
actor-first precedence. Movement city-center checks already call this policy.
The six diplomatic mutation commands and their turn processing remain
`reference-only` until D8; no compatibility adapter or client-side relation
table is introduced.

Run the diagnostic release baseline separately:

```sh
make rust-benchmark
```

It reports map open/hash plus raw and prepared reachable/route, occupied-target
approach, owned apply, city, combat, logistics, worker, direct local-runtime
dispatch, and shared client JSON workloads. Movement and T1 lifecycle cases
cover 1, 10, 64, and 512 units as applicable; the worker ceiling reaches 1199
units. Wall-clock values are diagnostic; stable result signatures, work
counters, payload sizes, and allocation ceilings are test gates.

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

The current canonical command corpus contains 44 fixtures covering movement
and cancel/skip/fortify behavior. Each fixture owns a validated logical map,
complete `GameStateDto`, typed command, rejection, ordered events, execution
evidence, and complete returned state. Every case executes through
`GameEngine::apply`; the result is encoded from the returned `GameState`
without copying fields from the input or projecting into a historical shape.
`aonw_testkit` accepts only canonical fixture contract version 3. That version
remains because fixture files are shared artifacts consumed independently from
the engine implementation.

The characterization covers terrain bases and features, roads, partial and
queued movement, occupancy and hidden information, cities, fog, complete
diplomacy and resource-trade state, victory-progress substrates, posture,
artifact capacity, rejection precedence, and exact movement evidence. Diplomacy persists normalized contacts
and relations, proposals, messages and responses, score history, war status,
and active resource agreements. Outcome progress persists sparse domination and
cultural hold counters plus ordered map-objective controllers and hold turns;
the derived match outcome remains a future engine result, not duplicated state.
The domain rejects unknown participants,
self-relations, missing contacts, duplicate records, invalid score/turn ranges,
and incoherent message or trade fields before constructing state. Historical
version 2 reducer fixtures remain frozen read-only migration evidence outside
the Rust workspace. No Rust reader, adapter, projection, gate, or generator
consumes or rewrites them.

## Map content contract

`MapDocument` represents the editable versioned document and carries the
presentation-only `defaultZoom` hint. `MapDefinition` is the validated logical
map. Its compact `canonical_bytes()` output is exactly what `content_hash()`
hashes; presentation hints are excluded. Resource order uses an explicit stable
wire rank, so enum source order cannot change canonical bytes.

Versioned documents fail closed on missing, unknown, duplicated, or invalid
fields and apply no compatibility defaults. Authored `MapDocument` values
retain the schema's 5×5 minimum, while logical `MapDefinition` values accept
smaller positive grids constructed inside deterministic canonical fixtures.
Map bounds expose canonical odd-q neighbors and row-major indices without
allocation.

The actor is command/query context, not persisted state. `GameStateDto` is the
strict current contract for all implemented authoritative state. It
persists artifacts and rule-relevant interaction state, including reversible
current-turn unit skips, without moving those rules into UI.
`EngineContext` supplies actor, permission, validated map, and immutable
ruleset; canonical fog and occupancy are derived from `GameState`.

Match identity and turn lifecycle are typed canonical components rather than
opaque JSON. They preserve ordered participants, match rules and recursive
balance values, match mode, player turn states, submitted/AFK/kicked sets,
the explicit required-submission scope, timeout streaks, and a host-provided
UTC turn start. The pure domain never reads a clock, and mapping rejects
duplicate or unknown lifecycle identities. Persisted participant names and
colors are part of canonical display identity and therefore contribute to the
complete state digest. Mutable localization, client theme, camera and
recipient presentation stay outside `GameStateDto`.

Economy is likewise a typed canonical section: signed gold, war-weariness and
stability accounts, positive oil/aluminium stockpiles, and the persisted seed
plus ordered initial resource placements all round-trip and participate in the
state digest. The successor contract intentionally has no resource-generator
version. Persisted placements are authoritative, and the legacy Dart
`algorithmVersion` has no runtime consumer once generation is complete; the
canonical contract stores the generated result rather than that redundant
internal counter.

Cities use one complete typed contract and domain entity. The representation
preserves current and founding ownership, name, progression counters, ordered
controlled and worked coordinates, the full building and wonder sets, typed
building/unit/project/wonder production, invested and overflow production,
reserved strategic resources, specialization, preferred expansion, and
optional hit points. Mapping validates participant identity, map bounds,
duplicate collections, worked-territory consistency, and resource-allocation
invariants with field paths. All persisted city fields contribute to the state
digest; current movement and unit-action transitions preserve them unchanged.

Infrastructure is one validated domain component containing economic field
improvements and the transport network. Field improvements normalize to
coordinate order while validation rejects duplicates and serves lookups; all
19 current improvement kinds, optional builder-city attribution,
road identity, condition, builder player, and optional builder city round-trip.
Mapping rejects coordinates outside the map and missing participant/city
references with field paths. Digest ordering is coordinate-canonical, and both
current transition families preserve the complete component unchanged.

Research and completed wonders form a validated knowledge-state component.
Research uses the full 54-value technology identity set, deterministic player
maps and technology sets/maps, optional active selection, positive progress,
and non-negative science overflow. The wonder registry maps each of the 11
global wonders to a match participant. Mapping rejects duplicate unlocks,
progress retained for unlocked technologies, active selections that are
already unlocked, non-positive progress, negative overflow, and unknown player
references with field paths. Every field contributes to the state digest and
is preserved by current transitions, save, and replay.

Pending simultaneous combat is a typed `CombatState` rather than opaque
lifecycle JSON. Each intended attack preserves its attacker, bounded target,
host-provided declaration tick, declaring participant, and explicit city
capture/destroy choice. Construction rejects duplicate declarations per
attacker, absent or foreign-owned attackers, unknown players, and targets
outside the logical map. Unit HP/XP/army and city HP/founding ownership remain
owned by their complete entity sections; all of these combat-relevant fields
are preserved by current transitions, save, replay, and the state digest.

CP9/C3 makes that state executable through one current-only combat path.
`CombatPreview` and `AttackHex` share the same prepared legality and statistic
calculation, including visibility, range, `DiplomacyPolicyQuery`, terrain,
army composition, artifacts, and `TechnologyUnlockQuery` modifiers. The RNG
ports the oracle's UTF-16 FNV seed derivation and xorshift draws for
`turn + attacker + defender`; ordered rolls and the derived outcome are stored
as typed evidence rather than as a mutable global RNG counter. Apply handles
damage, retaliation, retreat, XP, casualties, city capture/destruction,
artifact loss, fog/contact updates, and diplomatic consequences.

Direct attacks and simultaneous intended attacks use the same resolver.
Authoritative replay retains the complete event/evidence record, while the
client encoder filters combat, unit events, identifiers, rolls, and turn-kernel
executions through a recipient disclosure snapshot taken before transition.
A third-party observer therefore cannot learn a hidden attacker, defender, or
seed. Nine strict current C3 fixtures and mutation tests cover exact preview /
apply identity, rejection precedence, technology and artifact modifiers,
conquest, intended-turn evidence, persistence, and single-roll/event/evidence
tampering. They do not read or translate the historical reducer envelope.

## Movement foundation

`GameState` is the canonical aggregate root for the implemented simulation
slice. It uses the nominal `StateRevision` and stores units, cities and
artifacts in stable identifier order. Construction validates map bounds,
duplicate IDs, unit occupancy, artifact locations and ownership, and
rule-relevant interaction references.

`canonicalize_game_state` defines one semantic JSON identity through strict
DTO -> domain -> DTO normalization. JSON object member order is irrelevant;
maps and sets use stable key order, entity registries use identifier or
coordinate order, and genuinely ordered sequences such as participant turn
order, paths, events and resource placements retain their contract order. The
active canonical fixture corpus must already be in that normalized form.

The complete `Unit` entity preserves identity, display name, HP, XP, army,
queued and merchant routes, worker charges, posture, artifacts, and concrete
worker/founding/assignment/excavation activity. These independently persisted
activity slots may coexist in current game state. Manual movement availability
is derived from them; it is not a client-supplied canonical boolean.

`RulesetDefinition` owns all 17 unit movement allowances, movement domains,
capabilities, artifact allowance, occupancy policy, and the complete immutable
54-node technology catalog. The catalog contains prerequisites, costs, boosts,
unlocks and effects, has its own canonical SHA-256 identity, and also
participates in the whole-ruleset hash. `TechnologyUnlockQuery` is the single
read-only source for availability, fixed-point research costs, effect summaries,
and building/improvement/resource/unit/wonder gates. Research selection and
turn progression remain disabled until their later parity stage.
`ScenarioDefinition` links exact map and ruleset hashes to validated starting
placements and can bootstrap a revision-zero, turn-one `GameState`, matching
the established game semantics. Map, ruleset, technology-catalog, and scenario
identities use stable SHA-256 golden vectors.

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

The U2 logistics surface adds deterministic bounded auto-explore, engine-owned
merchant route planning/travel, troop detachment, and one recipient-safe
`UnitLogisticsOptions` query. These paths reuse the same movement costs,
occupancy, route search, and `DiplomacyPolicyQuery` as manual movement; clients
never calculate a private route. Four native logistics events and typed
`LogisticsExecution` evidence are persisted and encoded through the current
client API. Save/reopen/replay tests compare exact state, event order, evidence,
and fog-safe recipient views.

The W5 worker surface adds seven authoritative commands and the recipient-safe
`WorkerOptions` query. Manual actions, query options, bounded automation, and
turn processors share one legality implementation and the same TG unlock
source. Improvements and roads are canonical infrastructure; completed jobs
emit typed events, update routing identity, invalidate affected runtime query
caches, and survive exact current-only save/reopen/replay. Infrastructure views
are recipient-filtered, and no historical worker or road envelope is parsed.

`CancelUnitAction`, `SkipUnitTurn`, and `FortifyUnit` use the same full-state
boundary and rejection semantics. Skip records its restorable movement inside
canonical `InteractionState`; cancel clears unit-owned interaction,
queued/activity/merchant orders, restores an interrupted excavation artifact to
its map coordinate, and wakes the unit. Fortify accepts only an idle controlled
unit. These actions emit no synthetic movement events or evidence.

`aonw_local_runtime::LocalRuntime` owns one validated local session. Opening is
transactional, closing is idempotent, and every snapshot, query, and dispatch
response carries revision, state digest, map hash, and ruleset hash. Full
recipient-safe snapshots also carry the authoritative turn number.
They expose a pending action only when it belongs to the snapshot recipient;
the owner identifier is intentionally redundant and omitted. The runtime
exposes reachable, route, unit-logistics-options, combat-preview, three
city-planning, and worker-options queries, revision-bound commands, ordered events,
exact execution evidence, and view patches including unit posture and the
current recipient pending action, including an explicit `null` when it clears.
Recipient unit views are sorted by stable unit identifier before snapshots and
linear patch generation, independently from canonical contract order. Event
offset capacity is checked before an owned-state dispatch can begin.

`aonw_contracts::client` owns the single client protocol shared by Godot and
Flutter native adapters. `ClientRequestDto` contains tagged stateless map
inspection, lifecycle, command, and query operations. `ClientResponseDto`
contains framework-neutral map views, recipient-safe snapshots, patches,
events, evidence, persistence documents, and stable errors; canonical
`GameStateDto` never crosses this boundary. The protocol accepts only
`CLIENT_API_VERSION` and has no historical readers or upcasters. Rust
in-process runtime types deliberately have no version suffix.
Command results use a tagged accepted/rejected outcome, so an incoherent
acceptance flag and rejection code cannot be represented on the wire. Rejection
codes are closed enums in both the engine and client DTO; their current wire
values are pinned by `command_rejection_codes.json` and unknown values fail
closed in every adapter. The current contract includes authoritative turn,
recipient-owned pending actions, turn-one scenario bootstrap semantics, and
unified stale command rejections as `stale_revision`.

The shared golden documents in `test/fixtures/client_protocol` are consumed by
Rust, Godot, and Dart tests. Native adapters report `CLIENT_API_VERSION`; each
client owns the same supported constant and rejects an incompatible adapter or
response before inspecting its payload. The stateless `inspectMap` operation
validates a strict `MapDocument` and projects the same content hash and
`MapViewDto` for both clients. Godot has no separate map validator or serializer.

The runtime prepares `CompiledMovementMap` once per map/ruleset, keeps
tile-indexed visibility, builds occupancy as a compact bitset, reuses reachable
search buffers, and caches the last query by revision, unit, state/visibility
digest, map hash, ruleset hash, and target. Occupied-target approach uses one
multi-target search. Batch queries reuse the same cache and buffers.

The hot dispatch path consumes owned `GameState`, reuses its entity allocation,
and consumes `DomainTransition::into_parts`; it does not clone the complete
state for a normal local apply. `GameEngine` exposes only this owned command
path, preventing an accidental full-state clone behind a convenience API.
Prepared and raw contexts have deterministic parity tests. Rayon, ECS, SIMD,
GPU pathfinding, custom allocators, and `unsafe` are not used because the
measured 1200-tile workload does not justify them.

Each concrete player command publishes a reviewed event budget. The local
runtime reserves the complete bound before transferring canonical state to the
engine, commits only the actual ordered event count, and fails closed if the
engine exceeds the bound. This supports future multi-event commands without a
global one-event limit and prevents later offset overflow from partially
applying a transition.

`aonw_godot::AonwLocalSession` exposes one `request_json` transport operation.
It decodes and encodes `aonw_contracts::client` documents and delegates every
map inspection, lifecycle, query, command, save, and replay operation to `ClientProtocol` in
`aonw_local_runtime`. Godot obtains units from the recipient snapshot and never
constructs a synthetic canonical unit. Build it with `make rust-godot-build`.

`aonw_flutter` exposes the same dispatcher through a panic-contained C ABI.
`packages/aonw_rust_client` bundles it with Flutter build hooks and keeps native
calls on a helper isolate. Its strict Dart read models cover snapshots, queries,
commands, events, evidence, patches, and persistence results. Consumers that do
not request Rust receive an explicit unavailable C stub; the successor client
sets `rust_backend: true` and builds the real host-native adapter. A requested
Rust backend for another OS or architecture fails closed instead of silently
substituting the stub. `make rust-flutter-test` verifies these lanes. A concrete
Flutter `LocalEnginePort` remains gated on lossless complete-state mapping.

## Save and replay

`aonw_contracts` owns separate current-only save and replay schemas. A save
contains the complete `GameStateDto`, exact map and ruleset identities, actor,
event offset, and canonical state digest. Restore is transactional and rejects
mismatched content, state invariants, or digest before replacing an open
session. Combat randomness is derived from named command inputs and recorded
in its execution evidence, so saves do not carry a fabricated global RNG
stream.

The bounded replay segment stores its complete initial state and context, then
each revision-bound command with pre-command context and the exact rejection,
ordered events, execution evidence, event offset, revision, and resulting
digest. Every random capability must add its named algorithm, exact seed
inputs, and ordered draw/roll evidence to its own command result; a generic
pre/post RNG counter is forbidden. Verification executes every command again
through `GameEngine` and fails on the first context or result drift. The
recorder rolls to a new checkpoint after 512 commands; adapters own filesystem
paths and I/O.

Godot sends save/open and replay export/verification through the same tagged
client protocol as every other operation. Persistence rules remain in Rust.

## Deliberately deferred

- historical client/save/replay upcasters and long-term compatibility manifests;
- production Flutter session cutover and cross-target Rust packaging;
- AI and remote replica crates;
- any integration that could change the active Flutter or Serverpod runtime.
