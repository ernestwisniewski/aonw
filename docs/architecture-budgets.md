# Architecture Budgets

The repository uses line budgets as a maintainability signal, not as a claim
that there is one universally correct file length. The enforceable contract is
therefore based on a small set of role-specific targets plus an exact ratchet
for existing code above those targets. It replaces the previous scattered
maps whose per-file values mixed targets, historical snapshots, and arbitrary
ceilings.

## Repository Census

`tool/check_architecture.dart` discovers every tracked and repository-visible
untracked Dart source. The policy assigns each source to exactly one of these
roots:

- application, test, and tool code in the root Flutter package;
- library, test, and tool code in `aonw_core`;
- library and smoke-test code in `aonw_server_client`;
- the server entry point, library, and tests;
- the committed `sign_in_with_apple` fork.

A new Dart source outside those roots fails the gate until the policy is
deliberately migrated. Deleted files are removed from the census. Paths come
from NUL-delimited Git output, must be valid UTF-8 portable repository paths,
and must resolve to regular files rather than symbolic links. Repository
`.gitignore` files are honored for local build output, while user-global Git
ignore configuration cannot change the census.

Generated sources are excluded only after provenance checks and only where the
drift oracle recreates the same boundary:

- build-runner outputs require a canonical header and sibling input, and the
  suffix exclusion is enabled only for root and `aonw_core` library sources;
- localization outputs require the canonical directory and ARB inputs;
- Serverpod server, client, and test-tool outputs require the Serverpod
  generated header.

The generated-code drift gate deletes and recreates every excluded directory,
including the complete Serverpod test-tools directory, before proving that the
outputs match their inputs. A generated-looking file outside those declared
generator scopes remains ordinary handwritten code and is measured.

## Targets

| Profile | File target | Rationale |
| --- | ---: | --- |
| Application use case | 180 lines | A use case should orchestrate a small number of ports and domain operations rather than become a second domain service. |
| Flutter frontend | 350 lines | Application composition, screens, widgets, editor UI, and input adapters need enough room for readable interaction code while remaining practical to review and test as one unit. |
| Default Dart source | 500 lines | Domain catalogs, serializers, renderers, tests, and developer tools sometimes carry dense data or fixtures, but new monolithic files are still rejected. |
| Type declaration | 350 lines | One class, enum, mixin, extension, or extension type should not own an unbounded amount of behavior even when its file stays below the file target. |

The numbers exist exactly once in the policy's global `fileLineTargets` catalog
and global `declarationLineTarget`. Scopes only assign stable directory prefixes
to named profiles, so a package cannot quietly invent a different value for the
same role. Reserved prefixes may outlive their last source file; deleting code
does not force a policy weakening or schema migration. All unmatched files use
the default profile. Callable length, nesting, and cognitive complexity are not
part of this first AST budget and remain future policy work.

Type spans come from the public AST exposed by the exact root dev dependency
`analyzer: 12.1.0`. Annotations are part of a declaration span; leading Dartdoc
comments are not. Upgrading Analyzer requires an intentional pin and lockfile
update together with the AST contract test for every supported type kind.

## Exact Baseline And Historical Ratchet

`tool/architecture_baseline.json` contains only files and type declarations
that are currently above their target. Entries at or below a target are
invalid. This distinction is intentional: a 23-line file is healthy code, not
an arbitrary 23-line permanent ceiling.

The current measurement must match the committed baseline exactly. A reviewed
refactor that reduces or removes debt therefore updates the snapshot. The
historical check then compares that candidate with the trusted Git ref and
rejects:

- a new above-target file or declaration;
- growth of an existing above-target entity;
- a refreshed baseline that attempts to hide either regression.

Debt cannot be transferred to a new identity. Renaming or moving an
above-target file or declaration creates a new key and is rejected unless the
refactor also brings that entity within its target.

The trusted ref itself is used for the historical comparison even when branch
histories have diverged; their unique merge base validates that they share the
architecture rollout boundary. This preserves improvements already present on
the trusted branch and detects baseline resets across force pushes.

Policy schema 1 is immutable after rollout. Targets, source roots, profiles,
and generated-code boundaries cannot be silently weakened alongside a
baseline update. An intentional policy change requires a new schema with an
explicit old-to-new migration and updated negative tests. There are no inline
or path-local waivers.

## Commands

Run the same gate used by local CI and GitHub Actions:

```sh
make architecture
```

To inspect a candidate after a debt-reducing refactor:

```sh
make architecture-snapshot
diff -u tool/architecture_baseline.json /tmp/aonw-architecture-baseline.json
```

Review every changed key and line count, then replace the committed baseline
with the candidate only when the historical ratchet also passes. Do not edit
the JSON manually to make a regression green.

`make ci` includes `architecture-check`. GitHub Actions runs the same Make
target in the root quality-gate job and supplies the pull-request base or the
previous pushed commit as the trusted ratchet ref.
