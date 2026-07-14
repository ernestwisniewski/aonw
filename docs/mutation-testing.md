# Mutation Testing

The mutation gate checks whether focused tests detect small, valid changes to
critical handwritten code. It complements line coverage: executing a branch is
not enough when the assertion would also pass after reversing its decision.

## Enforced Scopes

Schema 1 deliberately starts with three high-risk, deterministic seams:

| Scope | Production target | Focused test |
| --- | --- | --- |
| Shared combat wire format | `packages/aonw_core/lib/game/domain/combat/combat_serialization.dart` | `packages/aonw_core/test/game/combat_serialization_test.dart` |
| Unit command decisions | `lib/game/domain/reducer/unit/unit_command_validator.dart` | `test/game/domain/reducer/unit_command_validator_test.dart` |
| Server authentication input | `server/lib/src/auth/auth_input_validator.dart` | `server/test/auth/auth_input_validator_test.dart` |

The target list is tied to the handwritten-source census from the architecture
policy. Target and test paths must be portable regular Dart files inside their
declared package, and every target must produce at least one mutant. Extending
the gate means adding a narrowly owned scope and focused deterministic tests,
not pointing it at the entire repository at once.

## Operators

The AST discoverer currently applies seven reviewed operators:

- flip boolean literals;
- negate equality operators;
- swap logical connectors;
- insert or remove logical negation;
- move relational boundaries by one operator form;
- negate safe type tests;
- alter strings that form a serialized wire contract.

Promotion-sensitive expressions are excluded when mutating them would only
make the program fail analysis. Mutant identity combines the repository path,
qualified declaration, structural AST path, token context, operator, and
replacement. Formatting and line-number shifts therefore do not reset history,
while inserting a different condition cannot inherit an old mutant identity.

## Execution Contract

Each scope first proves that its unmodified focused suite passes. Every mutant
then runs alone in an isolated snapshot of the complete current workspace with
fixed test ordering and one test process at a time. The source is restored and
the controlled snapshot is checked for side effects after every run. Package
runtime directories such as `.dart_tool/` and `build/` are reset from a trusted
template before the next mutant, so compiler state cannot leak between cases.

A mutant is killed only by a reported user-test failure with the matching test
runner completion and exit status. Analyzer errors, compilation failures,
suite-load failures, crashes, timeouts, malformed runner output, and filesystem
side effects fail the mutation tool itself. They never improve the result by
being counted as killed mutants.

The per-mutant timeout and bounded stdout/stderr buffers are safety limits, not
substitutes for a test assertion. On POSIX hosts, including Linux-based WSL,
every test command runs in a dedicated session and process group. The complete
group is terminated after every run, before the runner waits for output EOF, so
a child cannot evade cleanup by exiting, reparenting, or retaining an inherited
output pipe. Timeouts and output-limit violations are treated as infrastructure
failures.

Native Windows execution fails before starting a test process. The gate must
not run there until equivalent isolation is implemented with Windows Job
Objects; falling back to PID polling or best-effort `taskkill` is not an
accepted safety boundary.

The documented Make targets run under `caffeinate -i` on macOS so host sleep
cannot consume a mutant timeout while the test process is suspended. Linux,
including GitHub Actions and WSL, runs the same Dart command directly.

## Baseline And Ratchet

`tool/mutation_baseline.json` is a canonical snapshot of the exact target and
operator census plus every surviving mutant. The initial reviewed baseline has
no survivors. There is intentionally no percentage threshold and no inline
waiver mechanism: a new survivor must be killed by a behavioral assertion or
the redundant production logic must be simplified before the baseline can
advance.

The current run must match the committed baseline exactly. The historical
ratchet also loads the baseline from the trusted Git ref and rejects any new
survivor identity, so refreshing the local census cannot hide a regression.
Removing a survivor is allowed; changing the schema 1 policy after rollout is
not. A future policy change requires a new schema and explicit migration tests.
When histories diverge, their unique merge base proves that they share a
comparable rollout boundary, but the baseline is intentionally read from the
trusted tip so an improvement already made on that branch cannot be lost.

## Commands

Run the same gate used by `make ci` and GitHub Actions:

```sh
make mutation
```

To inspect a candidate after intentionally changing a target or its tests:

```sh
make mutation-snapshot
diff -u tool/mutation_baseline.json /tmp/aonw-mutation-baseline.json
```

Review the target totals, operator totals, and complete survivor set. Replace
the committed baseline only when the source or assertions explain every census
change and the historical ratchet still passes. Never edit mutant identities or
counts by hand to make the gate green.

GitHub Actions runs mutation testing as a dedicated job with full Git history.
It uses the pull-request base or the previous pushed commit as the trusted
ratchet ref, matching the local Make target's contract.
