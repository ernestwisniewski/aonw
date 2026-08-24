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
The current T1 lifecycle surface is `turn-kernel-ready`: submission,
lifecycle progression, movement reset, and reversible-skip cleanup are
implemented. Queued movement, trade routes, automation, combat, economy,
diplomacy, research, agreements, and objectives remain disabled and fail
closed when their state is detected. The five historical integrated-turn
fixtures therefore remain blocked until the complete CP9 pipeline; they are
not reclassified as full `engine-parity` by the smaller greenfield kernel.

The CP7/DP read-only substrate is `state-contract-ready` rather than command
parity. `DiplomacyPolicyQuery` centralizes relation-dependent legality and
recipient disclosure, and its accepted/rejected/hidden manifest is exercised
by `make rust-diplomacy-policy-check`. All diplomatic mutation commands and
events retain their existing `reference-only` inventory status until D8.

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
