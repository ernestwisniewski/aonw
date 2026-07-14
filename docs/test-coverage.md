# Test Coverage

Coverage is a repository quality gate, not a target to optimize in isolation.
Phase 1 measures executable line coverage only; branch and function coverage do
not affect the result.

## Covered Scopes

The gate measures three independent source scopes and their configured layers:

| Scope | Source | Test runner |
| --- | --- | --- |
| Flutter app | `lib/` | Flutter tests, run serially with `--concurrency=1` |
| Shared core | `packages/aonw_core/lib/` | Dart tests in `aonw_core` |
| Server | `server/lib/` | Server unit tests without external services |

`packages/aonw_server_client/` is generated code. Its smoke test remains part
of the quality gate, but the package has no percentage target. PostgreSQL-backed
server integration tests are also deliberately separate; run
`make server-integration-test` when a change touches their surface. Stateful
local persistence and public multiplayer boundaries additionally use the
[Critical End-to-End Journeys](critical-e2e.md).

Server coverage uses Dart's canonical `*_test.dart` discovery. This keeps
process entry points and PostgreSQL `*_smoke.dart` support code out of the
unit-test compilation graph; passing an explicit positional list here would
manufacture unexecuted LCOV records and silently change the measured source
census.

## Local Commands

Use the Make targets so local and CI collection use the same SDK, options, file
paths, and policy:

```sh
make coverage
make coverage-check
```

`make coverage` is the convenient alias for the complete gate;
`make coverage-check` is the explicit target used by CI. Both collect all three
reports and apply the policy. For a focused loop, run:

```sh
make flutter-coverage
make core-coverage
make server-coverage
```

The Flutter target removes `build/test_cache` before collection so local and CI
runs begin with the same incremental compiler state. Keep this cleanup in the
canonical target; normal non-coverage test runs retain their cache. Tests that
load assets or Flame components must still wait for an observable readiness
condition instead of relying on a fixed number of frames.

Diff coverage is compared with `origin/main` by default. Override the base only
when reproducing a specific CI comparison:

```sh
make coverage-check COVERAGE_BASE_REF=<git-ref>
```

The historical ratchet is a separate trust boundary. Locally it compares with
the current branch's upstream; CI uses the pull-request base or the previous
remote SHA from before the push. This prevents an earlier commit in a
multi-commit push from blessing a weaker baseline. The same trusted ref gets a
second, incremental 90% diff check, so older covered branch work cannot dilute
an uncovered new delivery. The `origin/main` comparison remains as the
cumulative long-lived-branch gate. Set
`COVERAGE_RATCHET_REF=<trusted-git-ref>` only when reproducing that exact CI
state; do not point it at an intermediate commit from the change under review.

## Baseline And Ratchet

The committed baseline stores exact instrumented totals and minimum covered
counts for every layer, plus the exact set of eligible source files absent from
LCOV. A freshly collected report must keep the same totals and missing-file
set, while meeting or exceeding every covered-count floor. Updating structural
totals or floors is therefore an explicit, reviewable source change rather
than an automatic percentage rounding adjustment.

Supported platforms may cover more than the committed floor when framework or
runtime internals take a different deterministic path. Such gains pass without
rewriting the baseline. Raise a floor only after every supported environment
reliably meets it; a snapshot from one platform alone is not evidence that a
higher floor is portable.

The historical ratchet then prevents a baseline update from concealing a
regression. Per layer:

- the coverage ratio must not decrease;
- the number of uncovered items must not increase;
- the current missing-file set must be a subset of the previous set.

The comparison uses integer counts, not rounded percentages. Changed eligible
lines must additionally reach at least 90% coverage both overall and in every
changed layer. A changed eligible file missing from LCOV fails the gate.

The policy records an immutable rollout anchor in `tool/coverage_policy.json`.
The effective diff base is the later of `COVERAGE_BASE_REF` and that anchor, so
history from before enforcement cannot fail the initial rollout. Once the
anchor is reachable from the normal base branch, comparisons naturally use the
requested base.

## Source Census And Exclusions

The gate starts from tracked and untracked Dart sources, then reconciles that
census with LCOV. Every eligible file must belong to exactly one configured
layer. Adding source outside the layer map or broadening an exclusion fails
closed.

Exclusions are narrow and centralized in `tool/coverage_policy.json`:

- `*.g.dart` and `*.freezed.dart`;
- generated Flutter localization output under `lib/l10n/generated/`;
- generated Serverpod output under `server/lib/src/generated/`;
- the Flutter process entry point `lib/main.dart`;
- the generated Serverpod client package, which keeps its smoke test instead.

Do not add inline coverage-ignore annotations or manually edit LCOV. The gate
rejects ignore markers in handwritten production source, and generated suffixes
must carry their canonical generator header. The generated-code drift oracle
deletes every excluded output in its temporary snapshot and requires the pinned
generators to recreate it, so a handwritten file cannot hide under a generated
path. A new output matching an existing generated pattern needs no policy
change. A genuinely new generator category or layer remap requires an explicit
checker-schema migration with a reviewed old-to-new baseline mapping; ordinary
commits cannot mutate the anchored scope, layer, or exclusion structure.

## Updating The Baseline

Generate a candidate outside the repository, inspect its layer and
missing-file changes, then deliberately apply the reviewed JSON to
`tool/coverage_baseline.json`:

```sh
make coverage-snapshot
diff -u tool/coverage_baseline.json /tmp/aonw-coverage-baseline.json
```

Override `COVERAGE_SNAPSHOT_PATH` when another temporary destination is more
convenient. The candidate reflects the platform that generated it, so do not
raise a covered-count floor solely because that platform reports an additional
hit. Update the committed snapshot only when the historical ratchet still
passes. New tests should accompany production changes that would otherwise
lower the ratio, add uncovered lines, or add a missing source file.

Run `make coverage-check` again after updating the snapshot. Do not accept a
baseline change whose only purpose is to make a regression green.
