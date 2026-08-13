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
| `aonw_domain` | Validated identifiers, coordinates, units, and deterministic world state. |
| `aonw_content` | Strict versioned map documents, an explicit legacy adapter, domain validation, normalization, lookup, and deterministic logical-content hashing. |
| `aonw_contracts` | Versioned, domain-independent boundary DTOs. It deliberately does not choose a wire codec yet. |
| `aonw_contract_mapping` | Validated conversion between boundary DTOs and domain types. |
| `aonw_engine` | Pure borrowed state inspection and engine/version surface; authoritative command transitions follow reviewed parity fixtures. |
| `aonw_testkit` | Bounded fixture/corpus loader, duplicate-key rejection, structural JSON diff, and engine-neutral runner for the shared reducer-parity corpus. |

The split enforces an inward dependency direction: contracts and domain do not
depend on one another, content depends only on domain coordinates, mapping
depends on contracts and domain, and the engine depends only on domain. The
testkit remains independent of every concrete engine backend. Recipient state
has no conversion into canonical domain state.

## Quality gates

Run the complete standalone Rust gate from the repository root:

```sh
make rust-check
```

The component targets are `rust-format-check`, `rust-clippy`, `rust-test`, and
`rust-doc`. They are intentionally independent of the existing Dart/Flutter
`make ci` target during this migration phase.

The toolchain is pinned in `rust-toolchain.toml`, `unsafe` is forbidden across
the initial workspace, canonical entities use sorted contiguous storage for
deterministic cache-friendly reads, and boundary mappings validate all external
input before domain construction. Release builds retain integer overflow checks.

## Map content contract

`MapDocument` represents the editable versioned document and carries the
presentation-only `defaultZoom` hint. `MapDefinition` is the validated logical
map. Its compact `canonical_bytes()` output is exactly what `content_hash()`
hashes; presentation hints are excluded. Resource order uses an explicit stable
wire rank, so enum source order cannot change canonical bytes.

Versioned documents fail closed on missing, unknown, duplicated, or invalid
fields. Defaults exist only in the explicit legacy Flutter map adapter.

## Deliberately deferred

- gameplay command handlers and save codecs until reviewed Dart fixtures exist;
- FFI and GDExtension crates until the pure boundary is stable;
- local runtime, AI, recipient projection, and remote replica crates;
- any integration that could change the active Flutter or Serverpod runtime.
