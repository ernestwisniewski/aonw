# Age of New Worlds

[![CI](https://github.com/ernestwisniewski/aonw/actions/workflows/ci.yml/badge.svg)](https://github.com/ernestwisniewski/aonw/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B.svg)](https://flutter.dev)

Age of New Worlds is an open-source hex-based 4X strategy game built with
Flutter, Flame, Dart, and Serverpod. It includes a playable cross-platform
client, a shared rules package, and a server-backed multiplayer foundation.

The game currently focuses on the core 4X loop: exploration, fog of war,
movement, city growth, production, research, combat, save/load, AI opponents,
and online multiplayer infrastructure.

## Public Links

| Destination | Link |
| --- | --- |
| Website | [aonw.net](https://aonw.net/) |
| Devlog | [ernest.dev](https://ernest.dev) |
| GitHub | [ernestwisniewski/aonw](https://github.com/ernestwisniewski/aonw) |
| iOS | [App Store](https://apps.apple.com/pl/app/age-of-new-worlds/id6781790591) |
| Windows/Linux/macOS | [Steam](https://store.steampowered.com/app/4833240/Age_of_New_Worlds/), [itch.io](https://ernest-dev.itch.io/aonw) |
| Android | [Google Play](https://play.google.com/store/apps/details?id=aonw.net.game), [itch.io](https://ernest-dev.itch.io/aonw) |

## Repository

| Area | Purpose |
| --- | --- |
| `lib/game/` | Flutter client gameplay, UI, Flame rendering, local persistence, and adapters. |
| `packages/aonw_core/` | Dart-only rules, protocol models, AI planning, and shared game logic. |
| `packages/aonw_server_client/` | Generated Serverpod client package used by the Flutter app. |
| `server/` | Serverpod backend, auth adapters, multiplayer services, and persistence. |
| `docs/` | Architecture, gameplay, operations, release, and publishing documentation. |

## Quick Start

The canonical local and CI SDK pin is [`.fvmrc`](.fvmrc). Install that exact
Flutter release and use its bundled Dart SDK. FVM is optional; if used,
`fvm install --setup --skip-pub-get` creates `.fvm/flutter_sdk` without
resolving dependencies outside the locked bootstrap; Make automatically places
that SDK first on `PATH`. Bootstrap all four locked packages and the matching
Serverpod CLI with one command:

```sh
make bootstrap
```

Bootstrap fails before dependency resolution when the active Flutter/Dart pair
differs from `.fvmrc`. It does not generate code, start services, or alter
tracked lockfiles.

For the full local quality gate:

```sh
make ci
```

`make ci` includes `make generated-code-check`, checks formatting, then
analyzes and tests the Flutter app, the shared core package, the generated
Serverpod client package, and the Serverpod backend tests that do not require
external services. The generated-code gate uses an isolated snapshot of the
current workspace, so checking root and `aonw_core` build-runner output,
localizations, Serverpod output, and migrations never rewrites the active
checkout. It requires the Serverpod CLI version pinned by the backend;
`make bootstrap` installs or verifies that CLI as part of workspace setup.

Run `make analyze` for the focused, fatal static-analysis gate across all four
packages. Its shared rules, generated-code exceptions, and extension procedure
are documented in [the static-analysis policy](docs/static-analysis.md).

Run `make coverage-check` for the line-coverage gate across the Flutter app,
shared core, and server. It enforces exact per-layer baselines, a
non-regressing historical ratchet, and 90% changed-line coverage; see the
[test coverage policy](docs/test-coverage.md).

When generator inputs change, regenerate the affected output deliberately in
the real checkout, review the diff, and commit it:

```sh
flutter pub run build_runner build
(cd packages/aonw_core && dart run build_runner build)
flutter gen-l10n
(cd server && dart pub global run serverpod_cli:serverpod_cli generate)
(cd server && dart pub global run serverpod_cli:serverpod_cli create-migration)
make generated-code-check
```

## Local Backend

Copy the sample environment and replace every placeholder secret before running
services:

```sh
cp .env.example .env
make local-start
```

`make local-start` starts PostgreSQL, Redis, and the Serverpod API in Docker,
waits for readiness, and seeds four reusable multiplayer accounts. Run the web
client with the stable Google OAuth origin and Docker API in one command:

```sh
make local
```

The local web app runs at `http://localhost:7357` and targets the Docker API at
`http://localhost:8080`. The seeded accounts are `test1@example.test` through
`test4@example.test`, all using `AonwTest123!`. Use separate browser profiles
or a normal and private window to test two players concurrently.

For an automated multiplayer round trip, including the global quickplay queue,
public-lobby discovery and join, realtime streams, commands, reconnect, and
persisted event history, run:

```sh
make local-multiplayer-smoke
```

Desktop/web/iOS/macOS builds use `http://localhost:8080` by default. The
Android emulator uses `http://10.0.2.2:8080`. Google Web requires the stable
`http://localhost:7357` origin. Apple Web still requires a registered public
HTTPS callback; native Apple sign-in can use the local API.

Stop the local stack without deleting its data with `make local-down`.

For a faster server edit loop, run only dependencies in Docker and start
Serverpod on the host:

```sh
cd server
docker compose -f compose.yml up -d postgres redis
dart run bin/main.dart \
  --mode=development \
  --server-id=local \
  --logging=normal \
  --role=monolith \
  --apply-migrations
```

Serverpod integration smoke tests require PostgreSQL:

```sh
tool/run_postgres_smoke.sh
make server-integration-test
```

## Documentation

Start with [docs/README.md](docs/README.md) for the architecture map and
document index.

Recommended entry points:

- [CONTRIBUTING.md](CONTRIBUTING.md) for setup, checks, localization, and pull
  request expectations.
- [docs/build-and-deploy.md](docs/build-and-deploy.md) for builds, releases,
  server deploys, store uploads, and public download packaging.
- [docs/multiplayer-protocol.md](docs/multiplayer-protocol.md) before changing
  Serverpod protocol surfaces, multiplayer sessions, or realtime streams.
- [docs/test-coverage.md](docs/test-coverage.md) for measured scopes, baseline
  updates, exclusions, and changed-line coverage.
- [docs/adr/README.md](docs/adr/README.md) before changing architecture
  ownership, command semantics, compatibility policy, or deployment identity.
- `docs/game-design/` for gameplay systems, balance, UX, and
  rendering behavior.

## Localization

The app ships English, Polish, German, Spanish, Dutch, and French. English is
the source language in `lib/l10n/app_en.arb`; other locales translate it and
fall back to English. See [CONTRIBUTING.md](CONTRIBUTING.md) before changing
user-facing text.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, checks, and contribution
expectations. Community behavior is covered in
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and security reporting is covered in
[SECURITY.md](SECURITY.md).

## License

Code is released under the [MIT License](LICENSE). Asset and third-party
notices are summarized in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
