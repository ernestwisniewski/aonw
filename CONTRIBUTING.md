# Contributing

Thanks for taking a look at Age of New Worlds.

Please follow the project [Code of Conduct](CODE_OF_CONDUCT.md) when
participating in issues, pull requests, discussions, and reviews.

## Setup

Use the exact Flutter SDK selected by `.fvmrc` and its bundled Dart SDK. The
manifest constraints describe package compatibility; `.fvmrc` is the local and
CI toolchain pin. FVM is optional:
`fvm install --setup --skip-pub-get` provisions the project SDK without an
unlocked dependency resolution, and Make automatically prefers
`.fvm/flutter_sdk` when it exists.

```sh
make bootstrap
```

Bootstrap verifies the active toolchain, resolves the root, `aonw_core`,
generated client, and server lockfiles with `--enforce-lockfile`, and ensures
the Serverpod CLI version pinned in `server/pubspec.yaml`. It does not run
generators or tests.

For backend work, copy `.env.example` to `.env`, replace placeholder secrets,
and use Docker Compose for PostgreSQL and Redis.

## Checks

Before opening a pull request, run:

```sh
make ci
```

`make ci` runs `make generated-code-check`, formatting, analysis, and tests for
the Flutter app, `aonw_core`, the generated Serverpod client package, and the
Serverpod backend unit tests that do not require external services. CI uses the
same generated-code gate.

For a focused analysis pass, run `make analyze`. The four packages compose one
strict base with ecosystem-specific upstream profiles; see the
[static-analysis policy](docs/static-analysis.md) before changing a rule or an
exclusion.

Run the generated-code gate on its own while changing generator inputs:

```sh
make generated-code-check
```

It recreates root and `aonw_core` build-runner output, Flutter localizations,
Serverpod protocol/client/test output, and Serverpod migrations in an isolated
snapshot of the current workspace. It reports drift without modifying the
active checkout. A matching Serverpod CLI is required; `make bootstrap`
installs or verifies it.

When touching Serverpod schemas, generated protocol files, migrations, Compose
files, or deployment behavior, also run:

```sh
make serverpod-ops-check
```

Integration tests that require PostgreSQL are intentionally separate:

```sh
make server-integration-test
```

### Test Coverage

Run the complete line-coverage gate with:

```sh
make coverage-check
```

It measures the Flutter app, `aonw_core`, and server unit-test scopes. The root
Flutter suite runs serially, and the generated Serverpod client remains a smoke
test without a percentage target. PostgreSQL integration tests stay outside
coverage collection and must still be run separately when relevant.

Use `make coverage` to collect all reports, or `make flutter-coverage`,
`make core-coverage`, and `make server-coverage` for a focused scope. Diff
coverage uses `origin/main` unless `COVERAGE_BASE_REF=<git-ref>` is supplied.
The baseline ratchet and incremental diff independently use the trusted
previous revision (the branch upstream locally and the PR base or pre-push SHA
in CI).

The committed snapshot is exact and protected by a historical ratchet: per
layer, the ratio cannot decrease, uncovered counts cannot increase, and the
missing-file set may only shrink. Changed eligible lines require at least 90%
coverage. Do not add inline ignore annotations or relax the centralized
generated-code exclusions to make the gate pass. See
[Test Coverage](docs/test-coverage.md) before updating the baseline or policy.

## Generated Code

The drift gate only verifies generated artifacts. When their sources change,
regenerate the relevant artifacts deliberately in the real checkout:

```sh
flutter pub run build_runner build
(cd packages/aonw_core && dart run build_runner build)
flutter gen-l10n
(cd server && dart pub global run serverpod_cli:serverpod_cli generate)
(cd server && dart pub global run serverpod_cli:serverpod_cli create-migration)
```

Review every generated diff, commit the expected output, and rerun
`make generated-code-check`.

## Localization

English is the source language. `lib/l10n/app_en.arb` is the template that
defines the canonical key set and placeholder metadata; the other locales
(`app_pl.arb`, `app_de.arb`, `app_es.arb`, `app_nl.arb`, `app_fr.arb`)
translate it and fall back to English for any missing key.

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
- Follow accepted [Architecture Decision Records](docs/adr/README.md). A change
  to a binding decision requires a new superseding ADR, index/docs updates, and
  the corresponding architecture guards in the same pull request.
- Prefer small comments that explain intent or invariants.
