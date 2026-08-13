# AONW Dart Core

`aonw_core` is the current production implementation of Age of New Worlds game
rules. It owns the authoritative domain state, deterministic engine, maps and
ruleset models, save/protocol models, replay support, and AI planning shared by
the Flutter client and Serverpod.

## Planned Replacement

This package is a transitional implementation. It is planned to be replaced by
the shared Rust engine developed as a Cargo workspace under `engine/`. The Rust
engine will become the single authoritative rules implementation used by local
play, AI, replay, Serverpod, Flutter AONW1, and Godot AONW2.

The replacement is incremental, not a big-bang rewrite. Until the documented
parity, save compatibility, platform, server shadow/canary, and rollback gates
pass, this Dart package remains production-supported, fixable, testable, and
releasable. A live session or match must use one complete primary engine; Dart
and Rust command families are never mixed within it.

New gameplay behavior must continue to use the existing deterministic engine
boundary and independently reviewed parity fixtures. Do not move rules into
Flutter, Serverpod endpoints, FFI wrappers, Godot scenes, or GDScript during the
migration.

See:

- [Rust Engine Migration Plan](../../docs/rust-engine-migration.md)
- [ADR 0008: Rust Engine Ownership And Strangler Migration](../../docs/adr/0008-rust-engine-ownership-and-strangler-migration.md)
- [Reducer Parity Fixtures](../../test/fixtures/reducer_parity/README.md)
