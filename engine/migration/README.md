# Rust engine migration inventory

`authoritative_inventory` is the reviewed, fail-closed inventory for the
authoritative-engine migration. It records every concrete Dart
`DomainCommand`, trusted `SystemCommand`, domain event, execution-evidence
type, Rust query/result variant, recipient projection, current migration
status, optional Rust counterpart, and exact declaration source.

`state_field_ledger` keeps the boundaries separate and names their exact
fields: the 120 reducer fixture inputs, Dart `DomainState`, the Dart snapshot
and persistence metadata, Rust canonical DTO, save/replay envelopes, client
identity stamp, and recipient-safe snapshot/patch. Rust canonical state fields
are `state-contract-ready` only after strict typed round-trip, canonical
normalization, invariant validation, and state-digest participation have been
proven; missing state remains `reference-only`.

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

The file deliberately has no `v1` suffix or schema-version field. The engine
and greenfield clients update this one current contract atomically. A format
version is introduced only after a concrete independently deployed reader or
supported persisted format requires compatibility.

Run the dependency-free source guard and its negative fixtures from the
repository root:

```sh
make rust-engine-inventory-check
make rust-engine-inventory-test
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
