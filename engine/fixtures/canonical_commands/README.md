# Canonical command fixtures

This corpus exercises the current Rust engine contract directly. Every JSON
file is a self-contained, independently reviewed artifact with these exact
sections:

- `fixtureVersion`: shared fixture artifact version;
- `id` and `capability`: stable test identity and current engine surface;
- `input`: actor, ruleset identity, validated versioned map, complete
  `GameStateDto`, and one `ReplayCommandDto`;
- `expected`: acceptance/rejection, complete returned `GameStateDto`, ordered
  `ReplayEventDto` values, and optional `ReplayEvidenceDto`.

Fixtures never contain historical reducer state, save metadata, wall-clock
values, duplicated ticks, omission defaults, aliases, or generated expected
output. Old fixtures may be consulted only as behavior evidence while a case is
reviewed and rewritten into this contract.
