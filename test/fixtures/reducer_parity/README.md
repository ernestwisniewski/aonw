# Reducer Parity Fixtures

This corpus characterizes the duplicated local and authoritative server command
paths before they are replaced by the shared engine described in
[ADR 0002](../../../docs/adr/0002-deterministic-game-engine.md).
Every JSON file is a third, committed oracle reviewed independently from both
implementations. Tests must never calculate or bless `expected` from either
runtime path.

Each version 1 fixture contains:

- `id` and `family`, with accepted, actor-rejected, and semantic-rejected cases
  for player commands plus waiting, finalizing, and rejected turn submissions;
- serialized UTC time, actor, tick, standard ruleset identifier, map, match,
  save, canonical persistent state, and command;
- expected server acceptance/reason plus the complete canonical state, ordered
  domain events, and the complete save except for `savedAt`.

The local test calls `LocalCommandResolver(GameStateReducer)`. The server test
calls `ServerCommandReducer`. Both deserialize the same input and compare their
result with the complete committed oracle. UI effects, transport offsets,
database behavior, and projections are not parity outputs. Client interaction
state is also excluded except for the matching pending research selection in
the accepted research fixture, which proves that both reducers clear it.
`savedAt` is the only excluded save field: local rejection currently advances
it while server rejection preserves the input snapshot, and both tests assert
that known adapter difference explicitly.

Each fixture runs three times for both the committed input order and a variant
whose JSON object entries are reversed recursively before deserialization. JSON
objects are compared structurally, independent of key insertion order; JSON
arrays remain ordered, including the exact order of domain events. Both input
orders must produce the same committed oracle on every run.

Version 1 covers movement, scout auto-exploration, merchant routing, instant
combat, self-contained city-founding commands, city building, unit,
specialization, and map-dependent wonder production, research,
worker improvements, manual city worked-hex add/remove selection,
gold/resource exchange trades, waiting turn
submissions, and simultaneous turn finalization.
Turn rejections cover both a forged player id and a player outside the active
match roster. The corpus intentionally excludes client-only commands,
server-managed commands,
accepted no-op commands, timeout/system flows, and local `EndTurn` versus server
`EndTurn`. The current local transition still has no structured
acceptance/rejection, so the local path proves rejection through a canonical
no-op while the server path additionally checks the committed reason.

Authoritative city founding is characterized only through an explicit,
complete `FoundCityCommand.controlledHexes` payload. An empty command payload
does not mean "read the client city-founding draft". Draft-backed legacy client
behavior and interaction cleanup differences are characterized separately
until both adapters use the shared founding engine.

Oracle changes require a focused JSON diff review and green local and server
parity suites. Do not auto-regenerate, bulk-accept, or calculate `expected`
during a test run. Remove the remaining scope restrictions when the shared
`DomainState` and `DomainTransition` exist; do not normalize missing data away.
