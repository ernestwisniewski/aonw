# Contributing

Thanks for taking a look at Age of New Worlds.

Please follow the project [Code of Conduct](CODE_OF_CONDUCT.md) when
participating in issues, pull requests, discussions, and reviews.

## Setup

Use Flutter 3.44 or newer and Dart 3.11.4 or newer (matching the `environment`
constraint in `pubspec.yaml`).

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

For backend work, copy `.env.example` to `.env`, replace placeholder secrets,
and use Docker Compose for PostgreSQL and Redis.

## Checks

Before opening a pull request, run:

```sh
dart format --set-exit-if-changed .
make check
```

When touching Serverpod schemas, generated protocol files, migrations, Compose
files, or deployment behavior, also run:

```sh
make serverpod-ops-check
```

Integration tests that require PostgreSQL are intentionally separate:

```sh
make server-integration-test
```

## Localization

English is the source language. `lib/l10n/app_en.arb` is the template that
defines the canonical key set and placeholder metadata; the other locales
(`app_pl.arb`, `app_de.arb`, `app_es.arb`, `app_nl.arb`) translate it and fall
back to English for any missing key.

When you add or change user-facing text:

1. Add the key and English value (plus any `@key` placeholder metadata) to
   `app_en.arb`.
2. Mirror the key into the other locale files with a translation, or leave it to
   fall back to English until a translation is provided.
3. Regenerate with `flutter gen-l10n` and reference it via
   `AppLocalizations.of(context)`.

Production Dart sources must not contain user-facing literals; this is enforced
by `test/.../localization_hardcode_guard_test.dart`.

## Guidelines

- Keep changes focused and update docs when behavior, persistence, APIs, game
  rules, or build/deploy flows change.
- Keep generated files in sync with their source annotations and Serverpod
  definitions.
- Do not commit `.env`, signing keys, local IDE state, traces, build outputs, or
  benchmark artifacts.
- Keep architecture boundaries intact. If a dependency crosses layers, update
  the architecture test and docs in the same change.
- Prefer small comments that explain intent or invariants.
