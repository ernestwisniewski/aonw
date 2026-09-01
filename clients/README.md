# AoNW Clients

`clients/` contains the greenfield presentation clients for the Rust engine.
Both clients consume the same strict, versioned multiplayer API and keep
gameplay rules, authoritative state transitions, saves, and replays in Rust.

## Clients

| Client | Purpose |
| --- | --- |
| [`aonw_flutter/`](aonw_flutter/) | Flutter and Flame desktop/mobile client backed by `package:aonw_rust_client`. |
| [`aonw_godot/`](aonw_godot/) | Godot 4.7 desktop client and Terrain3D map workbench backed by the Rust GDExtension. |

## Contract

- The clients implement presentation, input, accessibility, camera, and local
  animation only.
- Rust owns gameplay validation and every authoritative state transition.
- The shared multiplayer API remains explicitly versioned where peers must
  negotiate compatibility.
- New clients have no legacy adapter, legacy protocol, alternative rules
  engine, or per-command fallback.
- Unknown protocol values and incompatible native libraries fail closed.

## Quick start

Run focused client checks from the repository root:

```sh
make successor-flutter-check
make godot-check
make map-stage-1-check
```

Run the clients with:

```sh
make successor-flutter-run
make godot-run
```

`make map-stage-1-check` compares normalized Rust-backed map semantics between
the clients. Client-owned visual goldens remain separate.

## Documentation

Read the client-specific [Flutter](aonw_flutter/README.md) and
[Godot](aonw_godot/README.md) guides. The migration gates and ownership rules
are defined in [the Rust engine migration plan](../docs/rust-engine-migration.md),
with architecture decisions indexed under [`docs/adr/`](../docs/adr/README.md).
