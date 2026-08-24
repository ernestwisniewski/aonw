# Canonical command fixtures

This corpus exercises the current Rust engine contract directly. Every JSON
file is a self-contained, independently reviewed artifact with these exact
sections:

- `fixtureVersion`: shared fixture artifact version;
- `id` and `capability`: stable test identity and current engine surface;
- `input`: actor, ruleset identity, validated canonical logical map, complete
  `GameStateDto`, and one `ReplayCommandDto`;
- `expected`: acceptance/rejection, complete returned `GameStateDto`, ordered
  `ReplayEventDto` values, and optional `ReplayEvidenceDto`.

Fixtures never contain historical reducer state, save metadata, wall-clock
values, duplicated ticks, omission defaults, aliases, or generated expected
output. Old fixtures may be consulted only as behavior evidence while a case is
reviewed and rewritten into this contract.

The corpus currently contains 43 reviewed movement/unit-action behavior cases
rewritten from read-only evidence plus one natively canonical fortify case. The
former invalid-origin case is a canonical state-boundary rejection documented
in `../canonical_state_rejections/`, because invalid aggregate state cannot
reach command dispatch.
