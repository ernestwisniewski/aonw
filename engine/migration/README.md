# Rust engine migration inventory

`authoritative_inventory` is the reviewed, fail-closed inventory for the
authoritative-engine migration. It records every concrete Dart
`DomainCommand`, its current Rust `PlayerCommand` counterpart, trusted
`SystemCommand`, domain event, execution-evidence
type, Rust query/result variant, recipient projection, current migration
status, optional Rust counterpart, and exact declaration source.
The Rust player-command census must also exactly match `ClientCommandDto`, so
the greenfield client protocol cannot acquire a trusted system endpoint.
Rust-native evidence without an old Dart counterpart is recorded separately as
`native-evidence`; this keeps the census closed without inventing a legacy
adapter or pretending a new contract came from the reference implementation.

`state_field_ledger` keeps the boundaries separate and names their exact
fields: the 120 reducer fixture inputs, Dart `DomainState`, the Dart snapshot
and persistence metadata, Rust canonical DTO, save/replay envelopes, client
identity stamp, and recipient-safe snapshot/patch. Rust canonical state fields
are `state-contract-ready` only after strict typed round-trip, canonical
normalization, invariant validation, and state-digest participation have been
proven; missing state remains `reference-only`.

`determinism_inventory` names every current oracle RNG/seed derivation and
wall-clock read. Reference behavior is recorded with its concrete algorithm,
inputs, and required evidence. It does not create a generic global RNG
contract: each future Rust capability must own its named deterministic inputs
and exact replay evidence. Pure Rust engine crates are forbidden from reading
the system clock or system randomness.

`reducer_fixture_dispositions` binds the frozen 120-case Dart evidence corpus
by filename census and aggregate Git blob OID without parsing its historical
envelope. Every case records family, command, accepted/rejected oracle result,
structural status, execution status, and either a strict current canonical
artifact or a concrete future checkpoint with one explicit blocker. Rust
crates are forbidden from reading the source corpus. Only cases backed by a
current `GameStateDto` round-trip and complete canonical command fixture may be
promoted to `engine-parity` and executed by the Rust evidence gate.

The status vocabulary is closed:

- `reference-only`
- `characterized`
- `state-contract-ready`
- `turn-kernel-ready`
- `engine-parity`
- `runtime-ready`
- `client-ready`
- `shadow-ready`
- `cutover`

Active Rust fixtures now own typed canonical input and compare complete output
returned by the engine, so `partial-parity-mode` is `full-state`. The historical
opaque splice adapter and its execution gate have been removed. State
representation is `state-contract-ready`; command/query surfaces remain at
their independently evidenced status until their own parity gate is met.
The current T1+U2+C3+C4+W5 lifecycle surface is `turn-kernel-ready`: submission,
lifecycle progression, movement reset, reversible-skip cleanup, queued
movement, merchant routes, scout auto-exploration, multiplayer intended combat,
worker construction, and bounded worker automation are implemented. Economy,
diplomatic turn processing, research, agreements, and objectives remain disabled
and fail closed when their state is detected. The five
historical integrated-turn fixtures therefore remain blocked until the
complete O9 pipeline; they are
not reclassified as full `engine-parity` by the smaller greenfield kernel.

The CP7/DP read-only substrate is `state-contract-ready` rather than command
parity. `DiplomacyPolicyQuery` centralizes relation-dependent legality and
recipient disclosure, and its accepted/rejected/hidden manifest is exercised
by `make rust-diplomacy-policy-check`. All diplomatic mutation commands and
events retain their existing `reference-only` inventory status until D8.

The CP7/TG read-only substrate is also `state-contract-ready` rather than
research-command parity. The immutable ruleset owns all 54 technology nodes and
their canonical catalog hash. One `TechnologyUnlockQuery` supplies prerequisite
availability, deterministic fixed-point costs, unlock breakdowns, accumulated
combat/economy modifiers, and production/worker/resource gates. Its strict
accepted/rejected manifest is exercised by `make rust-tech-gate-check`.
`SelectTechnology` and research turn progression remain `reference-only` until
R7; no legacy reader, fallback, local unlock table, or internal version was
introduced.

The CP9/C3 surface is `runtime-ready`. `AttackHex`, `CombatPreview`, direct
apply, and simultaneous intended attacks share one deterministic resolver,
DP/TG policy inputs, ordered events, and typed execution evidence. Three frozen
combat reducer cases are `historical/reference-only` and point to nine strict
current C3 fixtures; no Rust code parses their old envelope. Save/reopen/replay
re-executes exact rolls and detects single-roll, event, or evidence drift.
Recipient client encoding filters hidden combat identifiers and canonical
rolls, while the authoritative replay keeps the complete evidence. C3 adds no
legacy reader, upcaster, fallback, compatibility alias, or internal version;
the shared client API version remains unchanged.

The CP11/W5 surface is `runtime-ready`. Seven worker/infrastructure commands,
`WorkerOptions`, worker-job and automation turn processors, recipient-filtered
infrastructure projections, exact save/reopen/replay, and structural performance
budgets use one current contract. Thirteen frozen worker/road reducer cases are
`historical/reference-only` and point to the reviewed W5 manifest instead of a
reader for their old envelope. The shared client API remains version 5; W5 adds
no internal schema counter, legacy reader, adapter, upcaster, or fallback.

The CP12/E6.2 rush surface is `runtime-ready`. `RushProduction` uses the same
current production balance and technology gates as production options, spends
gold atomically, preserves a complete unit queue when deterministic spawn is
blocked, resolves global wonder races in canonical city order, and emits
recipient-filtered completion/refund events. Its strict client and replay
contracts reject unknown fields, while save/reopen/replay executes the current
command directly. The historical reducer documents remain reference evidence;
no reader, adapter, upcaster, fallback, or internal format version was added.

The CP12/E6.2 turn-production surface is `runtime-ready`. A distinct
`production` turn processor advances scoped players in canonical player/city
order, reuses the same yield, spawn, completion, and wonder resolvers as rush,
and persists its typed events through client projection, save, and replay.
Wealth projects convert current production through the content-owned divisor;
research projects still require the separate fail-closed R7 processor. The
general economy processor therefore remains unsupported instead of hiding
growth, upkeep, or stability no-ops. No client API version or compatibility
path was added.

The file deliberately has no `v1` suffix or schema-version field. The engine
and greenfield clients update this one current contract atomically. A format
version is introduced only after a concrete independently deployed reader or
supported persisted format requires compatibility.

Run the dependency-free source guard and its negative fixtures from the
repository root:

```sh
make rust-engine-inventory-check
make rust-engine-inventory-test
make rust-determinism-check
make rust-corpus-parity-check
make rust-tech-gate-check
make rust-combat-check
make rust-worker-check
```

The analyzer-backed AST census is a separate evidence gate because the small
`p0-check` CI job intentionally has no Flutter toolchain:

```sh
make rust-engine-inventory-ast-check
```

Adding, removing, renaming, moving, or porting a command, query, event,
evidence type, state field, envelope field, or recipient projection requires
an atomic inventory/ledger update. Never change only an expected count. A
status promotion must include the evidence required by the development plan
and cannot be used to hide an unclassified source variant.
