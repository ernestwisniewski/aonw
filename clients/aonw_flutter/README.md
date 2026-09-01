# AoNW Flutter Client

This is the greenfield Flutter and Flame presentation client for the Rust
engine. It consumes the strict client protocol through
`package:aonw_rust_client` and builds the native Rust backend for the host
target.

## Modules

| Area | Responsibility |
| --- | --- |
| `lib/app/` | Bootstrap, composition, routing, lifecycle, and process error handling. |
| `lib/design_system/` | Shared visual tokens and accessible widgets. |
| `lib/features/map/` | Rust-backed session orchestration, interaction state, and map presentation. |
| `lib/features/settings/` | Client-only preferences and persistence. |
| `lib/features/turns/` | Presentation queue for authoritative turn updates. |
| `lib/game/` | Flame viewport, camera, rendering, and presentation-only effects. |
| `lib/l10n/` | ARB catalogs and generated localization APIs. |

`AppComposition.production()` is the production composition root. Widgets do
not construct FFI sessions or repositories, and presentation code receives
immutable read models rather than wire DTOs.

## Boundary

- Rust owns movement, combat, economy, turns, AI, saves, and replays.
- Flutter owns presentation, input, accessibility, camera, and local animation.
- One repository retains one Rust session for its complete lifecycle.
- Accepted commands are followed by an authoritative snapshot or patch; Dart
  never reduces gameplay state locally.
- The client has no dependency on the legacy root application or `aonw_core`,
  and contains no legacy adapter, alternate engine, or per-command fallback.
- Incompatible API versions and unknown closed-enum values fail closed.

## Quick start

Run from the repository root:

```sh
make bootstrap
make successor-flutter-check
make successor-flutter-run
```

Useful focused gates:

```sh
make successor-flutter-coverage-report
make successor-flutter-device-test
make successor-flutter-fm5-baseline
make map-stage-1-check
```

The starter map assets are generated from `content/maps/` for both successor
clients. `make map-stage-1-check` verifies shared semantics without rewriting
Flutter visual goldens.

## Documentation

Read [the Rust engine migration plan](../../docs/rust-engine-migration.md) for
the current cutover gates. Client and engine ownership is formalized in
[ADR 0010](../../docs/adr/0010-rust-successor-engine-and-client-boundary.md).
