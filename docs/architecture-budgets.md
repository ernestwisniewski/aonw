# Architecture Budgets

The architecture gate treats size and control-flow complexity as review-cost
signals. A threshold is a target for new code, not a claim that every existing
source above it should be deleted immediately. Existing debt is captured at its
exact measured value and can only stay level or decrease.

## Repository Census

`tool/check_architecture.dart` discovers every tracked and repository-visible
untracked Dart source. The policy assigns each source to exactly one declared
root covering the Flutter application, `aonw_core`, the Serverpod server and
client, tests, tools, and the committed `sign_in_with_apple` fork. A new Dart
source outside those roots fails the gate.

Paths come from NUL-delimited Git output, must be valid UTF-8 portable
repository paths, and must resolve to regular files rather than symbolic
links. Repository `.gitignore` files are honored for local build output, while
user-global Git ignore configuration cannot change the census.

Generated sources are excluded only after provenance checks and only where the
drift oracle recreates the same boundary:

- build-runner outputs require a canonical header and sibling input;
- localization outputs require the canonical directory and ARB inputs;
- Serverpod server, client, and test-tool outputs require the Serverpod
  generated header.

A generated-looking file outside those declared generator scopes remains
ordinary handwritten code and is measured.

## Four Coherent Roles

Schema 2 classifies code by responsibility rather than by package-specific
exceptions. The four roles are exhaustive and live once in the central policy:

- `production` for application, domain, server, client, and vendored runtime
  code;
- `flame_rendering` for the stable rendering roots under editor engine, game
  presentation engine, and map rendering;
- `test` for every test source root;
- `tool` for developer tools, smoke runners, and operational CLIs.

All roles share the same 500-line file target and 350-line type-declaration
target. New code no longer receives the former path-specific 180/350/500 file
ceilings. The repository census showed production p95 near 476 lines, while
the larger p95 values in rendering, tests, and tools are existing debt rather
than a reason to weaken the target. Existing files already above the former
stricter 350-line frontend target remain in an immutable migration-debt map
until they fall to 350 lines or below; unifying future targets does not grant
that accepted debt new headroom. The target follows Git-detected renames from
the reviewed rollout anchor, so moving a file cannot reset its stricter budget.

Callable thresholds vary only where the review shape genuinely differs:

| Role | Callable lines | Max nesting | Cyclomatic | Cognitive |
| --- | ---: | ---: | ---: | ---: |
| Production | 60 | 3 | 10 | 15 |
| Flame/rendering | 80 | 4 | 12 | 18 |
| Test | 120 | 4 | 15 | 20 |
| Tool | 100 | 4 | 15 | 20 |

Production keeps the tightest budget because business behavior should remain
easy to isolate and review. Rendering may need a little more local branching
to keep frame work explicit. Tests and tools may contain scenario setup and
procedural orchestration, but still receive finite limits. There are no new
per-file overrides, inline suppressions, or hidden headroom values; the only
path-local values are the frozen schema-1 debts carried by migration.

## AST Metric Contract

The gate measures named functions, methods, constructors, getters, setters,
operators, local functions, and anonymous callbacks. Stable names identify
top-level and type-owned callables. Anonymous extensions, local functions, and
callbacks use an owner-local ordinal; callback keys also include the invocation
name and a normalized string label when present. Moving or renaming an
over-target entity creates a new debt key and therefore cannot disguise debt
transfer.

Callable line count is exclusive: the complete source span is measured, then
the union of line ranges occupied by direct nested callables is removed. The
union avoids subtracting a shared source line twice. This prevents a test
`main`, `group`, or orchestration method from being charged again for every
callback that is independently measured. Annotations belong to declaration
spans; leading Dartdoc comments do not. Constructor complexity includes its
initializer list as well as its body.

Control-flow scores exclude nested callable bodies from their parent and use
this versioned contract:

- cyclomatic complexity starts at 1 and adds one for every `if`, loop,
  `catch`, non-default switch-statement branch, switch-expression case,
  conditional expression, collection `if`/`for`, pattern guard, and boolean
  `&&`/`||` expression or pattern;
- maximum nesting counts `if`, loops, `catch`, switch statements and
  expressions, conditional expressions, and collection `if`/`for`; an
  `else if` remains at its parent level;
- cognitive complexity adds `1 + current nesting` for each nested structural
  construct, one for `else` or `else if`, and one for each pattern guard or
  boolean `&&`/`||` operation.

This is an intentionally small repository contract, not a claim of byte-for-
byte compatibility with Sonar or another vendor. Golden AST tests define every
score. The parser is the public AST from the exact root dev dependency
`analyzer: 12.1.0`; an Analyzer upgrade requires an intentional pin, lockfile
update, and metric-contract review.

## Exact Baseline And Historical Ratchet

`tool/architecture_baseline.json` contains only metrics currently above their
role or frozen migration target. It has separate maps for current-role files,
migrated schema-1 files, declarations, callable lines, nesting, cyclomatic
complexity, and cognitive complexity. An entry at or below its target is
invalid.

The current measurement must match the committed baseline exactly. A reviewed
refactor that reduces or removes debt therefore updates the snapshot. The
historical comparison then rejects:

- a new above-target entity in any metric;
- growth of an existing above-target metric;
- a refreshed baseline that attempts to hide either regression.

Schema 2 is immutable after rollout. Its one-time migration records SHA-256
digests of the reviewed schema-1 policy and baseline. When the trusted ref is
still schema 1, the gate verifies both digests and remeasures the candidate
with the old file/profile and declaration thresholds before accepting the new
snapshot. Every schema-1 file governed by a stricter old target is also copied
into the schema-2 migration map and remains ratcheted after rollout. This bridge
therefore cannot reset old debt. The schema-1 bridge is accepted only for the
exact reviewed anchor; once the trusted ref contains schema 2, every metric
participates in the normal historical ratchet. A future policy change requires
another explicit schema and migration tests.

The trusted ref itself is used even when histories diverge; their unique merge
base must remain comparable with the rollout anchor. This preserves
improvements already present on the trusted branch and detects baseline resets
across force pushes.

## Commands

Run the same gate used by local CI and GitHub Actions:

```sh
make architecture
```

To inspect a debt-reducing candidate:

```sh
make architecture-snapshot
diff -u tool/architecture_baseline.json /tmp/aonw-architecture-baseline.json
```

Review every changed key and exact value before replacing the committed
snapshot. Do not edit the JSON manually merely to make a regression green.

`make ci` includes `architecture-check`. GitHub Actions supplies the pull
request base or previous pushed commit as the trusted ratchet ref.
