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
