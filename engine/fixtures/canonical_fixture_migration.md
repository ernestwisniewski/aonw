# Reviewed movement and unit-action fixture migration

The 44 reviewed cases from `test/fixtures/reducer_parity_v2` have current-only
dispositions:

- 43 valid-state cases retain their ids in `canonical_commands/` and execute
  through strict `GameStateDto` / `ReplayCommandDto` input. Their acceptance,
  rejection code, ordered event, and exact movement evidence were checked
  against the read-only behavior evidence during the one-time rewrite.
- `movement-characterization-invalid-origin-rejected` is represented by
  `canonical_state_rejections/unit-out-of-bounds.json`. Current aggregate
  validation rejects that state before command dispatch, so no compatibility
  path keeps the unreachable `unit_out_of_bounds` command outcome alive.

`fortify-unit-accepted.json`, introduced with the canonical contract, is an
additional independently reviewed current-contract case. Therefore the command
corpus contains 44 fixtures: 43 migrated cases plus that native canonical case.

The one-time rewrite code is not retained. Runtime, clients, testkit, and the
committed artifacts have no reader, writer, alias, omission default, or output
encoder for the former reducer format.

## Reviewed 120-case dispositions

The separate frozen `test/fixtures/reducer_parity` corpus is classified by
`engine/migration/reducer_fixture_dispositions`. Nine cases for `MoveUnit`,
`CancelUnitAction`, `SkipUnitTurn`, and `FortifyUnit` point to strict artifacts
in `canonical_commands/`; their input and expected states round-trip through
the complete current domain and their full outcomes execute through Rust.

The other 111 cases remain historical `reference-only` evidence and are marked
`superseded-by-current-contract`. Their U2 through O9 checkpoints are complete:
the disposition ledger binds every historical family to existing engine and
runtime tests for the corresponding current contract. There are no outstanding
blocked cases.

This classification deliberately does not claim byte-for-byte execution parity
with the old envelope. The successor behavior is exercised through strict
current DTOs, recipient-safe output, save, and replay without synthetic defaults,
an adapter, or a reader for the historical corpus.
