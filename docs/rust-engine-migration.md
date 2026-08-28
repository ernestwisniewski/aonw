# Rust engine migration

- Status: active strangler migration
- Governing decision: [ADR 0008](adr/0008-rust-engine-ownership-and-strangler-migration.md)
- Production authority today: `packages/aonw_core`
- Successor implementation: `engine/`

Age of New Worlds is moving authoritative gameplay rules from Dart to Rust so the same engine can serve Flutter, Godot, AI, replay, and Serverpod. This is a compatibility port, not a gameplay rewrite.

```mermaid
flowchart LR
  Contracts["1. Stabilize deterministic contracts"] --> Slices["2. Port complete vertical slices"]
  Slices --> Clients["3. Prove Flutter and Godot boundaries"]
  Clients --> Modes["4. Add complete backend modes"]
  Modes --> Cutover["5. Cut over new saves and matches"]
  Cutover --> Retire["6. Retire Dart authority"]

  Dart["packages/aonw_core<br/>production reference"] -. parity fixtures .-> Slices
  Slices -. accepted/rejected output, digests, events, evidence .-> Dart
  Modes -. kill switch / rollback .-> Dart
```

## Current checkpoint

The Rust workspace has a working vertical slice for strict content, canonical state, movement queries and transitions, fog, diplomacy, cities, roads, save/replay contracts, local runtime sessions, recipient-safe patches, initial unit actions, and thin Godot/Flutter native adapters.

The shared fixture corpus covers the current movement and unit-action slice. Godot can open a Rust local session, query reachable tiles, execute movement, and consume exact movement evidence.

This does **not** make Rust the production backend. Flutter local play and Serverpod still use the Dart engine by default. The next work must continue through complete command families and turn-driven behavior rather than introducing client-specific rules.

The current crate inventory and commands are documented in [`../engine/README.md`](../engine/README.md).

## Rules that do not change during migration

1. The Flutter application stays buildable and releasable at the repository root.
2. `packages/aonw_core` remains behavioral evidence until explicit cutover gates pass; it is not a runtime compatibility dependency for new clients.
3. Preserve required game behavior, but prefer a simpler, safer, or more efficient Rust design over a line-for-line Dart port.
4. One save or match uses one primary engine for its entire lifetime.
5. Command families are never split between Dart and Rust inside an active session.
6. Fixtures are an independently reviewed oracle. Neither implementation may generate and bless its own expected result in CI.
7. Flutter, Godot, bridge code, and Serverpod endpoints do not own movement, combat, economy, fog, AI, or save rules.
8. Public protocol and durable schema changes follow their existing compatibility process; a language port does not imply a version bump.

## Target ownership

```mermaid
flowchart TB
  subgraph Pure["Pure deterministic Rust"]
    Domain["Domain + engine"]
    Contracts["Content + versioned contracts"]
    Projection["Recipient projection"]
    Contracts --> Domain
    Domain --> Projection
  end

  Runtime["Local runtime"] --> Domain
  Runtime --> Projection
  Flutter["Flutter adapter"] --> Runtime
  Godot["Godot adapter"] --> Runtime
  Serverpod["Serverpod host"] --> Domain
  Serverpod --> Projection
  Serverpod --> DB[(PostgreSQL)]

```

| Component | Responsibility |
| --- | --- |
| Rust domain and engine | Pure deterministic state transitions and queries. No I/O, framework, clock, localization, or database dependencies. |
| Rust content/contracts | Strict versioned maps, scenarios, state, save, replay, and client protocol models. |
| Local runtime | Session lifecycle, revision checks, command/query dispatch, recipient snapshots, and view patches. |
| Flutter/Godot adapters | Marshal the shared client protocol and render recipient-safe results. |
| Serverpod | Authentication, lobby/match lifecycle, locking, transactions, persistence, offsets, post-commit delivery, and reconnect. |
| PostgreSQL | Durable online source of truth. |

Recipient projection is a rules-sensitive policy and belongs with the engine. A remote client never reconstructs canonical `DomainState` from projected data.

## Migration sequence

### 1. Stabilize contracts

Keep the Dart engine boundary deterministic and explicit. Every external rule input must be carried in state, command, or context. Presentation effects stay outside authoritative results.

### 2. Port complete vertical slices

For each slice:

- read all supported current inputs;
- produce the same accepted/rejected result, state digest, events, evidence, and RNG position;
- cover round trips and rejection-without-mutation;
- keep the Dart path releasable;
- add a measured performance case when the slice is performance-sensitive.

Do not create empty crates for planned responsibilities. Add a crate when its first behavior and tests are ready.

### 3. Prove native client boundaries

Godot and Flutter consume the same coarse, versioned client protocol. Raw canonical state does not cross the client boundary. Native panics are contained in the adapter and reported as stable errors.

Required checks:

```sh
make rust-check
make rust-flutter-test
make godot-check
```

### 4. Add complete backend modes

The rollout model needs complete-engine selections such as:

- Dart only;
- Dart primary with Rust shadow;
- Rust primary with Dart shadow;
- Rust primary with Dart standby;
- Rust only.

Shadow output is comparison data only. It is never persisted, broadcast, or shown as authoritative.

### 5. Cut over new work

A kill switch may change the default engine for new saves or matches after parity, packaging, observability, and rollback drills pass. Existing work remains pinned unless an explicit versioned migration proves it safe to move.

Readers and writers for the single current Rust contract ship together. New
Flutter and Godot clients consume that contract directly; no Dart bridge or
rollback adapter is introduced. Development artifacts are unsupported until
the first production writer establishes the compatibility-support boundary.

### 6. Retire Dart authority

The Dart engine can be removed only when all of the following use Rust:

- every player and system command;
- queries and legality previews;
- turn processing, AI, and simulation;
- canonical saves and replay;
- recipient projection;
- Flutter and Godot local sessions;
- Serverpod authoritative transitions and recovery;
- every supported platform, including a deliberate Flutter Web solution.

No active server match may remain pinned to Dart. A reader/upcaster is added
only when a second real production format is deliberately supported; there is
no speculative compatibility layer for pre-cutover development artifacts. The
rollback window and drills must be complete.

Only after retirement should the repository be reorganized mechanically into final client/service directories. Do not mix that move with behavior migration.

## Rust quality baseline

The successor engine has three deliberately separate quality layers. `make
successor-engine-check` is the fast merge gate and combines the frozen-boundary
checks, all-feature Rust format/Clippy/test/doc/build checks, the exact crate and
unsafe architecture census, pinned license/source/duplicate policy, and
debug/release determinism. `make successor-engine-evidence-check` runs the
current capability-gated parity corpus and publishes LLVM coverage JSON, LCOV,
and structural performance evidence. `make successor-engine-deep-check` adds
release-mode workspace tests on its scheduled pinned Linux runner. Native
adapter/platform smokes remain separate jobs because unsupported rows must be
reported as unsupported, never replaced with a successful stub.

Coverage measurement is delegated to pinned `cargo-llvm-cov 0.9.0`. The local
checker supplies repository policy that the measurement tool does not know:
the complete crate-role census, explicit exclusions, per-authoritative-crate
and local-runtime ratios, uncovered-line ceilings, and a missing-file set that
may only shrink. Adapter coverage is deliberately not folded into the Linux
pure-engine denominator.

Structural performance measurement uses pinned `stats_alloc 0.1.10` around a
single-threaded measured region after setup and warm-up. The gate ratchets exact
result signatures, work counters, allocations, allocated bytes, payload bytes,
and soak count. Host-local timing remains diagnostic. Criterion and Divan are
appropriate for statistical timing exploration, while Iai-Callgrind may later
add Linux-only instruction/cache diagnostics to the deep workflow; none of
them replaces the portable domain counters and allocation contract required
for this migration.

Dependency policy uses `cargo-deny 0.20.2` from crates.io. Licenses and sources
fail closed. The only current duplicate exception is the exact `syn` 2/3 pair
introduced by the EXR/zerocopy and serde proc-macro chains; it is owned by the
engine foundation, expires on 2027-08-24, and must be removed or re-reviewed at
expiry. OSV continues to scan every committed lockfile independently.

These quality artifacts describe the single current greenfield engine and
successor-client contract. They introduce no legacy reader, adapter, upcaster,
or redundant internal format version. Shared API, map, fixture, and other real
multi-component versions remain unchanged.

## Verification and fixtures

Historical reducer corpora under `test/fixtures/` are frozen, read-only
migration evidence. Rust does not read or regenerate them. Active Rust behavior
coverage lives under `engine/fixtures/` and uses only the strict current
canonical contract.

A slice is complete only when the canonical fixture owns the full typed input
and Rust returns the full expected state, events, evidence, and rejection—not
just the visible destination or a projected subset of fields.

Run Rust performance diagnostics separately:

```sh
make rust-benchmark
```

Wall-clock numbers are host-local observations. Stable signatures and work counters are the regression evidence.

## Known transitional boundaries

- Flutter network state is recipient-projected by Serverpod but still passes through a Dart canonical compatibility envelope. Replace it with nominal recipient types before remote-replica cutover.
- The Rust client/save/replay contracts are current-only. Historical upcasters are deferred until a second schema exists.
- Atomic native writes, current-format backup promotion, and transactional restore are documented in [`rust-engine-persistence.md`](rust-engine-persistence.md).
- Rust is not yet the Serverpod production engine or the default Flutter local engine.

Keep this page at milestone level. Detailed crate behavior belongs in `engine/README.md`, Godot authoring behavior in `clients/aonw_godot/README.md`, and durable decisions in ADRs.
