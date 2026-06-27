# Age of New Worlds

Age of New Worlds is a Flutter and Flame prototype of a hex-based 4X strategy
game. The current runtime focuses on playloop, fog of war, movement, city
growth, production, research, save/load, and the foundations for server-backed
multiplayer.

The repository is organized as a Flutter client, a Dart-only shared core
package, a generated Serverpod client package, and a Serverpod backend.

## Supported Targets

- Flutter app: web, macOS, iOS, Android, Windows, and Linux project scaffolds.
- Backend: Serverpod server with PostgreSQL and Redis.
- Tooling: local balance and benchmark CLIs under `tool/` and
  `packages/aonw_core/tool/`.

## Public Links

- Website: [aonw.net](https://aonw.net/)
- Devlog: [ernest.dev](https://ernest.dev)
- GitHub: [ernestwisniewski/aonw](https://github.com/ernestwisniewski/aonw)
- iOS: [App Store](https://apps.apple.com/pl/app/age-of-new-worlds/id6781790591)
- Windows/macOS: [Steam](https://store.steampowered.com/app/4833240/Age_of_New_Worlds/)
- Android (soon)

## Quick Start

Install Flutter 3.44 or newer, then run:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

For the full local quality gate:

```sh
make ci
```

`make ci` checks formatting, then analyzes and tests the Flutter app, the
shared core package, the generated Serverpod client package, and the Serverpod
backend tests that do not require external services.

## New Contributor Path

If you are new to the project, read the docs in this order:

1. [docs/README.md](docs/README.md) for the architecture map and document index.
2. [docs/multiplayer-protocol.md](docs/multiplayer-protocol.md) if you are touching
   multiplayer or generated Serverpod code.
3. [docs/game-design/pace-profiles.md](docs/game-design/pace-profiles.md) and
   [docs/game-design/scoring-and-outcomes.md](docs/game-design/scoring-and-outcomes.md)
   before changing balance, objectives, victory rules, or AI pacing.
4. [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Local Backend

Copy the sample environment and replace every placeholder secret before running
services:

```sh
cp .env.example .env
docker compose --profile dev up --build
```

The dev profile starts PostgreSQL, Redis, and the Serverpod API. The Flutter
client uses `http://localhost:8080` on desktop/web and
`http://10.0.2.2:8080` on the Android emulator by default.

For a faster server edit loop, run only dependencies in Docker and start
Serverpod on the host:

```sh
cd server
docker compose up -d postgres redis
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

## Project Map

- `lib/game/domain/` - pure client-side game state, reducers, commands, events,
  and value objects.
- `lib/game/application/` - use cases and ports around persistence, logging,
  clocks, ids, and transport.
- `lib/game/infrastructure/` - JSON persistence, migrations, local transport,
  and system adapters.
- `lib/game/presentation/` - Riverpod providers, Flutter UI, Flame rendering,
  and renderer effects.
- `lib/map/` - map data, loading, topology, terrain rendering, and editor-facing
  map support.
- `packages/aonw_core/` - Dart-only shared game rules, protocol models, and
  computer-opponent planning code.
- `packages/aonw_server_client/` - generated Serverpod client package.
- `server/` - Serverpod backend, persistence, auth adapters, endpoints, and
  realtime multiplayer services.
- `assets/`, `web/`, and platform folders - runtime assets and platform
  integration.
- `docs/` - durable architecture, gameplay, operations, and publishing
  references.

## Documentation

Start with [docs/README.md](docs/README.md) for the architecture map and the
current documentation index. Deployment guidance is in
[docs/build-and-deploy.md](docs/build-and-deploy.md), and gameplay system
references are under `docs/game-design/`.

## Localization

The app ships English, Polish, German, Spanish, Dutch, and French. English
(`lib/l10n/app_en.arb`) is the source language and template; other locales
translate it and fall back to English. See [CONTRIBUTING.md](CONTRIBUTING.md)
for how to add or change localized text.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, checks, and contribution
expectations. Community behavior is covered in
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and security reporting is covered in
[SECURITY.md](SECURITY.md).

## License

Code is released under the [MIT License](LICENSE). Asset and third-party
notices are summarized in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
