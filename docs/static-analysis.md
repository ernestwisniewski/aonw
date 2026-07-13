# Static Analysis

The repository has one fail-closed analysis policy for handwritten Dart code.
It is composed rather than copied so a rule change reaches the Flutter app,
the shared core, the generated-client package boundary, and the backend in the
same commit.

## Configuration Layers

Each package loads two ordered profiles:

1. its ecosystem baseline;
2. the workspace policy in `analysis_options_base.yaml`.

| Package | Upstream profile | Workspace include |
| --- | --- | --- |
| Flutter app | `package:flutter_lints/flutter.yaml` | `analysis_options_base.yaml` |
| `aonw_core` | `package:lints/recommended.yaml` | `../../analysis_options_base.yaml` |
| generated client package | `package:lints/recommended.yaml` | `../../analysis_options_base.yaml` |
| Serverpod backend | `package:lints/recommended.yaml` | `../analysis_options_base.yaml` |

The shared policy owns strict casts, strict inference, strict raw types, async
correctness, immutability, import ordering, and API-hygiene rules. Package
files may only own ecosystem-specific profiles and narrowly scoped analyzer
exceptions. Do not copy a shared rule into a package file.

The app keeps `flutter_lints`; Dart-only packages keep `lints`. This preserves
Flutter-specific diagnostics without making the domain or backend depend on a
Flutter profile. Every committed lockfile must resolve the same `lints`
release, while `.fvmrc` pins the analyzer toolchain used locally and in CI.

## Generated And Vendored Boundaries

Handwritten code is always analyzed with the full shared policy. Exceptions
are limited to generator- or vendor-owned paths:

- root build-runner output: `**/*.g.dart` and `**/*.freezed.dart`;
- Serverpod client output: `lib/src/protocol/**` inside
  `packages/aonw_server_client`;
- Serverpod backend output: `lib/src/generated/**` and
  `test/integration/test_tools/serverpod_test_tools.dart` inside `server`;
- the patched upstream plugin: `third_party/**` from the root analysis scope.

The root `server/**` exclusion is a routing boundary, not an analysis
exception. It prevents the Flutter analyzer from scanning a second Dart
package with the wrong ecosystem profile; `make server-analyze` owns that
entire handwritten tree with the same shared policy.

The `aonw_core` generated files remain analyzed because they already satisfy
the shared policy. Serverpod output is excluded because the pinned generator
currently emits code that is incompatible with strict inference and casts.
Those precise exclusions do not make generated output unchecked:
`make generated-code-check` recreates it in isolation and rejects any drift.
Never broaden an exception to `lib/**`, `test/**`, or a whole workspace.

## Commands

Run every analyzer from the repository root:

```sh
make analyze
```

Focused targets are available while iterating:

```sh
make flutter-analyze
make core-analyze
make client-analyze
make server-analyze
```

All targets first verify the pinned Flutter/Dart pair, install the relevant
dependency graph with `pub get --enforce-lockfile`, and treat infos and
warnings as fatal. `make ci` and every GitHub Actions matrix job delegate to
these Make targets, so local and remote commands cannot silently diverge.

When changing the policy:

1. update the shared base or the narrow package exception;
2. update `test/architecture/lint_configuration_guard_test.dart` in the same
   commit;
3. run `make analyze` and `make generated-code-check`;
4. run `make ci` before handoff.

The guard semantically parses YAML, enumerates every tracked Dart workspace,
pins the allowed exclusions and lint dependencies, and verifies that CI calls
the canonical fatal Make targets.
