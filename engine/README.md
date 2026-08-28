# AoNW Rust Engine

This directory contains the deterministic successor engine for Age of New
Worlds. Rust owns canonical state, gameplay rules, recipient projections,
current save/replay contracts, and the native boundaries used by Flutter and
Godot.

`packages/aonw_core/` remains the production reference until functional parity,
platform qualification, shadow, canary, and rollback gates are complete.

## Workspace

| Area | Purpose |
| --- | --- |
| `aonw_domain` | Canonical game state, entities, identifiers, topology, and fixed-point values. |
| `aonw_content` | Strict maps, scenarios, immutable rulesets, catalogs, and content hashes. |
| `aonw_contracts` | Current client API plus canonical state, save, and replay DTOs. |
| `aonw_contract_mapping` | Validated conversion between contracts and domain types. |
| `aonw_engine` | Commands, queries, deterministic transitions, evidence, and turn processing. |
| `aonw_local_runtime` | Transactional sessions, replay recording, caches, snapshots, and patches. |
| `aonw_flutter` | Panic-contained C ABI for Flutter Native Assets. |
| `aonw_godot` | Thin GDExtension over the shared client protocol. |
| `aonw_map_*` | Logical map authoring, deterministic generation, terrain compilation, and CLI adapters. |
| `aonw_testkit` | Strict current fixtures, bounded corpus loading, and structural comparison. |

Pure engine crates do not depend on Flutter, Godot, Serverpod, filesystem,
network, wall-clock time, or presentation code. Adapters translate the same
versioned client boundary; they do not implement rules or fallback to Dart.

## Current scope

Implemented runtime slices include movement, unit actions, logistics, combat,
cities, workers, roads, economy, production, research, diplomacy, objectives,
match outcome, recipient-safe projections, local sessions, current saves and
bounded multi-segment exact replay. Strategic AI is deterministic, profile-aware,
strength-gated, and exercises the complete local runtime. Native persistence
uses atomic current-format writes plus a last-known-good backup. The production
Serverpod host remains migration work.

The engine and successor clients are greenfield and update one current contract
atomically. Internal DTOs do not carry speculative versions, legacy readers,
upcasters, aliases, or compatibility fallbacks. Shared API and artifact versions
remain because independently built components consume them.

## Quick start

Run from the repository root:

```sh
make rust-check
make successor-engine-check
make successor-engine-evidence-check
```

Focused functional gates include:

```sh
make rust-turn-kernel-check
make rust-movement-logistics-check
make rust-combat-check
make rust-city-check
make rust-worker-check
make rust-ai-check
make rust-persistence-check
```

Build or test the native adapters with:

```sh
make rust-flutter-test
make rust-godot-build
make godot-check
```

## Quality evidence

`cargo-llvm-cov` produces LLVM coverage and `stats_alloc` measures allocations.
Repository scripts add AoNW-specific census, provenance, ratchets, semantic work
counters, result signatures, and payload budgets; they do not replace those
external measurement tools. Wall-clock benchmark values are diagnostic only.

```sh
make rust-coverage-check
make rust-performance-check
make rust-architecture-check
make rust-dependency-check
make rust-determinism-check
make rust-security-policy-check
make rust-release-metadata-policy-check
```

Focused mutation testing uses pinned `cargo-mutants`; three bounded fuzz targets
use pinned `cargo-fuzz`/LibFuzzer with AddressSanitizer; Miri checks the pure
contract/domain boundary on one pinned nightly; and a real C consumer harness
checks the Flutter ABI with Clang AddressSanitizer and UndefinedBehaviorSanitizer.
The harness proves valid ownership/null lifecycle and requires both response and
session double-free misuse to be diagnosed. It does not make invalid stale
handles legal. The policy is part of fast CI, while the expensive executions are
scheduled or run manually:

```sh
make rust-mutation-check
make rust-fuzz-smoke
make rust-miri-check
make rust-ffi-sanitizer-check
make rust-engine-security-check
```

The fuzz workspace has its own committed lockfile because it is intentionally
separate from the production workspace. Generated corpora and crash artifacts
are local evidence and are not committed.

Release supply-chain files use pinned external generators: OWASP
`cargo-cyclonedx 0.5.9` for CycloneDX 1.5 JSON and `cargo-about 0.9.2` with its
explicit `cli` feature for third-party notices. The repository checker isolates
workspace-wide generation from the source tree, selects the current Flutter,
Godot, and map-compiler artifacts, binds output to the exact target and commit
epoch, and requires two byte-identical generations:

```sh
make rust-release-metadata-tool-versions
make rust-release-metadata-check
```

Generated SBOMs, notices, and their SHA-256 manifest are release artifacts under
`/tmp/aonw-rust-release-metadata`; they are uploaded by the scheduled deep gate
and are not committed as source.

## Documentation

- [Public Rust API documentation](https://engine.aonw.net/)
- [Interactive engine architecture](https://engine.aonw.net/architecture)
- [Migration and cutover model](../docs/rust-engine-migration.md)
- [Current save and replay contract](../docs/rust-engine-persistence.md)
- [Migration inventory](migration/README.md)
- [Architecture decisions](../docs/adr/README.md)
- [Successor clients](../clients/README.md)
