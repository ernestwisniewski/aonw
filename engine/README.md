# AoNW Rust Engine

This directory is the Cargo workspace for the future authoritative Age of New
Worlds rules engine. The workspace is intentionally independent of Flutter,
Godot, Serverpod, filesystem, network, wall-clock time, and presentation code.

The current code is a foundation, not a production backend. Dart
`packages/aonw_core` remains authoritative until the parity, compatibility,
platform, shadow, canary, and rollback gates in the
[migration plan](../docs/rust-engine-migration.md) pass.

## Current crates

| Crate | Responsibility |
| --- | --- |
| `aonw_domain` | Validated identifiers, coordinates, units, and deterministic world state. |
| `aonw_contracts` | Versioned, domain-independent boundary DTOs. It deliberately does not choose a wire codec yet. |
| `aonw_contract_mapping` | Validated conversion between boundary DTOs and domain types. |
| `aonw_engine` | Pure borrowed state inspection and engine/version surface; authoritative command transitions follow reviewed parity fixtures. |
| `aonw_testkit` | Bounded loader, structural JSON diff, and engine-neutral runner for the shared reducer-parity corpus. |

The split enforces an inward dependency direction: contracts and domain do not
depend on one another, mapping depends on both, and the engine depends only on
the domain. The testkit remains independent of every concrete engine backend.
Recipient state has no conversion into canonical domain state.

## Quality gates

Run from the repository root:

```sh
cargo fmt --manifest-path engine/Cargo.toml --all -- --check
cargo clippy --manifest-path engine/Cargo.toml --workspace --all-targets -- -D warnings
cargo test --manifest-path engine/Cargo.toml --workspace
cargo doc --manifest-path engine/Cargo.toml --workspace --no-deps
```

The toolchain is pinned in `rust-toolchain.toml`, `unsafe` is forbidden across
the initial workspace, canonical entities use sorted contiguous storage for
deterministic cache-friendly reads, and boundary mappings validate all external
input before domain construction.

## Deliberately deferred

- gameplay command handlers and save codecs until reviewed Dart fixtures exist;
- FFI and GDExtension crates until the pure boundary is stable;
- local runtime, AI, recipient projection, and remote replica crates;
- any integration that could change the active Flutter or Serverpod runtime.
