# Reducer Parity Fixtures

This corpus originally characterized duplicated local and authoritative server
command paths and now protects the covered slices as both adapters use the
shared Dart engine described historically in
[ADR 0002](../../../docs/adr/0002-deterministic-game-engine.md).
Every JSON file is a third, committed oracle reviewed independently from both
implementations. Tests must never calculate or bless `expected` from either
runtime path.

The same corpus is also the independent compatibility oracle for the Rust
engine migration described in
[ADR 0008](../../../docs/adr/0008-rust-engine-ownership-and-strangler-migration.md).
It remains in this shared repository location rather than being copied into
`engine/`. As migration harnesses are introduced, Dart, Rust CLI, native, Godot,
and server-shadow paths will compare their covered slices with this committed
data; a live Dart-to-Rust diff is additional evidence and never replaces the
oracle. The corpus does not claim coverage of offsets, database transactions,
recipient projections, system/timeout commands, or other explicitly excluded
boundaries.

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
worker improvements, road construction, manual city worked-hex add/remove
selection,
gold/resource exchange trades, waiting turn
submissions, and simultaneous turn finalization.
The `StartBuilding` slice is fail-closed over an exact fixture set: adversarial
city-not-found precedence plus city-not-controlled precedence for both an
otherwise available and a technology-locked foreign city, technology-locked,
already-built, and missing-map-requirement rejections, a fresh pace-scaled
overflow queue, replacement of an active queue with a satisfied map
requirement, and today's accepted same-target value no-op. The three distinct
causes that currently collapse to `building_not_available` are classified
explicitly by fixture id and validated against the fixture semantics. Every
accepted building fixture carries an unrelated-city sentinel, a runtime
sentinel, a complete-state oracle, and no events.
`StartWonder` is likewise fail-closed over exactly ten reviewed paths:
city-not-found, otherwise-available and same-target-unavailable wrong-actor
precedence, completed, technology-locked, missing-map-requirement, same-target
and other-own-city active-wonder rejections, plus fresh pace-scaled overflow
and active non-wonder queue replacement. The five internal statuses that
collapse to `wonder_not_available` are classified independently of the
production policy.
Accepted fixtures preserve full state and registry/runtime sentinels, emit no
events, and use an independent queue/overflow oracle.
`StartUnitProduction` is fail-closed over exactly eleven reviewed paths. They
pin `city_not_found`, both otherwise-available and compound wrong-actor
precedence, then the ordered availability, resource, coast, and supply
rejections. Accepted cases cover warrior standard60 rollover (cost 12, cap 6),
an iron import plus coastal warship queue replacement, today's accepted
same-target value no-op, and the supply boundary crossed only by a stored food
artifact together with a passive farm. Every accepted oracle replaces only the
target city queue and compares the complete remaining state; all fixtures carry
an unrelated-city/runtime sentinel and emit no events.
`RushProduction` is fail-closed over exactly thirteen reviewed paths. Seven
rejections pin `city_not_found`, both otherwise-rushable and foreign
empty-queue/zero-treasury wrong-actor precedence, owned empty queue, a
zero-treasury continuous project, insufficient gold, and an already-complete
finite queue. The latter two independently classify the conditions collapsed
into `rush_production_unavailable`. Six accepted
paths cover a partial unrest-sensitive building advance, building completion,
deterministic unit completion, today's accepted blocked-spawn behavior, Great
Library completion with a free technology and competing-queue refund, and the
refund path for a wonder already present in the registry. Complete-state
oracles verify exact gold, cities, units, research, registry, sentinels, and
ordered events; rejected commands preserve the complete canonical input.
Turn rejections cover both a forged player id and a player outside the active
match roster. The corpus intentionally excludes client-only commands,
server-managed commands,
accepted no-op commands other than the explicitly reviewed same-target
`StartBuilding` compatibility case, timeout/system flows, and local `EndTurn`
versus server `EndTurn`. The current local transition still has no structured
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
