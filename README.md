# Age of New Worlds

[![CI](https://github.com/ernestwisniewski/aonw/actions/workflows/ci.yml/badge.svg)](https://github.com/ernestwisniewski/aonw/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B.svg)](https://flutter.dev)


> [!IMPORTANT]
> This repository is no longer actively developed. Continued development has moved to [ernestwisniewski/age-of-new-worlds](https://github.com/ernestwisniewski/age-of-new-worlds).


Age of New Worlds is an open-source, turn-based 4X game built around a hex map. The shipping client uses Flutter and Flame, shared gameplay rules live in Dart, and online matches are hosted by Serverpod.

A Rust engine is being introduced incrementally under `engine/`. It already powers the experimental Godot client, but `packages/aonw_core/` remains the production rules implementation until the migration gates are complete.

## Public Links

| Destination | Link |
| --- | --- |
| Website | [aonw.net](https://aonw.net/) |
| Architecture | [Interactive map](https://aonw.net/architecture) |
| Devlog | [ernest.dev](https://ernest.dev) |
| GitHub | [ernestwisniewski/aonw](https://github.com/ernestwisniewski/aonw) |
| iOS | [App Store](https://apps.apple.com/pl/app/age-of-new-worlds/id6781790591) |
| Windows/Linux/macOS | [Steam](https://store.steampowered.com/app/4833240/Age_of_New_Worlds/), [itch.io](https://ernest-dev.itch.io/aonw) |
| Android | [Google Play](https://play.google.com/store/apps/details?id=aonw.net.game), [itch.io](https://ernest-dev.itch.io/aonw) |

## Repository

| Area | Purpose |
| --- | --- |
| `lib/game/` | Flutter client orchestration, UI, Flame rendering, persistence, and adapters. |
| `packages/aonw_core/` | Production Dart rules, protocol models, and AI. |
| `packages/aonw_server_client/` | Generated Serverpod client used by Flutter. |
| `server/` | Serverpod backend, authentication, multiplayer lifecycle, and persistence. |
| `engine/` | Rust workspace for the successor deterministic engine and native adapters. |
| `content/` | Versioned logical maps and scenarios shared with Rust and Godot. |
| `clients/aonw_flutter/` | Reserved final location for Flutter after the Dart engine is retired. The active app remains at the repository root. |
| `clients/aonw2_godot/` | Godot 3D presentation client and map workbench. Gameplay rules stay in Rust. |
| `docs/` | Architecture, gameplay contracts, quality policy, and runbooks. |

## Quick start

Use the Flutter version pinned in [`.fvmrc`](.fvmrc). FVM is optional; Make uses `.fvm/flutter_sdk` automatically when it exists.

```sh
make bootstrap
make ci
```

`make bootstrap` installs the locked package graphs and the matching Serverpod CLI. It does not generate code, start Docker, or alter lockfiles.

Useful focused checks:

```sh
make analyze
make coverage-check
make architecture
make mutation
make critical-e2e-test
make performance
make generated-code-check
```

## Run the Flutter client

For offline work, run the app with the normal Flutter tooling after bootstrap.

For the local multiplayer stack:

```sh
cp .env.example .env
# Replace every placeholder secret in .env.
make local-start
make local
```

The web client runs at `http://localhost:7357` and the API at `http://localhost:8080`. Four local accounts are seeded as `test1@example.test` through `test4@example.test`; the shared development password is `AonwTest123!`.

Run the automated multiplayer smoke with:

```sh
make local-multiplayer-smoke
```

Stop the stack without removing its data:

```sh
make local-down
```

## Rust and Godot

The Rust workspace and Godot client are separate from the shipping Flutter path.

```sh
make rust-check
make godot-check
make godot-editor
make godot-run
```

Read [the migration plan](docs/rust-engine-migration.md) before moving rules across the Dart/Rust boundary.

## Documentation

Start with [docs/README.md](docs/README.md). It explains which implementation is authoritative, where each subsystem lives, and which checks apply to a change, including [static analysis](docs/static-analysis.md), [critical journeys](docs/critical-e2e.md), [mutation testing](docs/mutation-testing.md), and [architecture budgets](docs/architecture-budgets.md).

Contribution setup and pull-request expectations are in [CONTRIBUTING.md](CONTRIBUTING.md). Architecture decisions are indexed in [docs/adr/README.md](docs/adr/README.md).

## Localization

English is the source language in `lib/l10n/app_en.arb`. The app also ships Polish, German, Spanish, Dutch, and French. Regenerate localization output with `flutter gen-l10n` after changing ARB files.

## License

Code is released under the [MIT License](LICENSE). Asset and dependency notices are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
