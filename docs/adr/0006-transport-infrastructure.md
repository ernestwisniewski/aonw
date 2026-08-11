# ADR 0006: Transport Infrastructure Ownership And Traversal

- Status: Accepted
- Date: 2026-08-11
- Implementation: Implemented

## Context

Roads are persistent map infrastructure with movement, rendering, fog-of-war,
save, replay, AI, and multiplayer consequences. Economic field improvements
already occupy hexes, but treating a road as another field improvement would
prevent a farm or mine from coexisting with transport and would couple yields
to pathfinding.

Movement previously obtained terrain costs directly in several manual and
automated flows. Adding a road discount independently to each caller would let
queued movement, exploration, merchants, AI, and previews disagree with the
authoritative command resolver.

## Decision

Transport is an independent domain aggregate owned by `DomainState`.
`TransportNetworkState` contains immutable, deterministically serialized
`TransportSegment` values keyed by hex. A segment records its kind, condition,
builder, and optional originating city. It may coexist with a field
improvement.

The binding invariants are:

- road construction is an authoritative `BuildRoadCommand` handled by the
  infrastructure engine family;
- only a ready worker on a legal, passable, non-city-center hex may start the
  job, and a road cannot be duplicated or built in foreign-controlled land;
- starting construction consumes the worker's current movement, while
  completing a road does not consume its field-improvement charge;
- build time uses the match pace and construction completes in the regular
  worker economy turn processor;
- all land path planning obtains entry cost through
  `UnitTraversalCostResolver`; an operational road reduces a passable land
  hex's entry cost to one, but never makes blocked terrain passable and never
  affects naval or air movement;
- manual moves, previews, queued paths, auto-explore, worker automation,
  merchants, and AI inject the same infrastructure-aware resolver;
- saves persist the network in schema 4; schema 3 is upcast with an empty
  network, while unsupported older and future schemas fail closed;
- multiplayer projections always include the recipient's roads and include
  foreign roads only when their static hex is remembered through fog-of-war;
- the transport rendering layer is independent of economic improvements and
  is covered by fog.

## Consequences

Road rules remain in pure Dart and are reusable by Flutter, server, replay, and
AI. The aggregate and traversal port can add rails, technology-based discounts,
pillage and repair without changing economic improvement ownership.

The first implemented slice stores one transport segment per hex and supports
roads only. City connectivity bonuses, rail construction, pillaging, repair,
and diplomacy-based transit are separate domain policies to be introduced when
their gameplay rules are defined. Connectivity should be derived from the
transport aggregate rather than persisted as a second source of truth.

Rejected alternatives:

- adding road to `FieldImprovementType` prevents coexistence and mixes yield
  and traversal responsibilities;
- storing road flags on map tiles makes authored map data own mutable match
  state;
- applying road discounts in UI or individual automation flows creates
  divergent route costs;
- persisting a city-connectivity graph duplicates data that can be derived
  deterministically from segments and city positions.

## Migration And Verification

The implementation includes deterministic aggregate serialization, a schema
3-to-4 upcaster, command codec and engine-family coverage, worker completion
tests, land/air/blocked-terrain traversal tests, movement boundary ratchets,
player-view projection tests, HUD localization, and a dedicated rendering
layer.

## Related Decisions And Documentation

- [ADR 0001: Map And State Ownership](0001-map-and-state-ownership.md)
- [ADR 0002: Deterministic Game Engine](0002-deterministic-game-engine.md)
- [ADR 0003: Command Boundaries](0003-command-boundaries.md)
- [ADR 0004: Versioned Multiplayer Protocol](0004-versioned-multiplayer-protocol.md)
