# ADR 0006: Current-Version Protocol Compatibility

- Status: Accepted
- Date: 2026-08-01
- Implementation: Implemented
- Supersedes: [ADR 0004](0004-versioned-multiplayer-protocol.md)

## Context

ADR 0004 required a bounded upcaster chain, compatibility negotiation, and a
multi-release bridge for old multiplayer envelopes. The product no longer
requires old saves or incompatible online matches that have not started to
survive a breaking release. Maintaining historical readers and writers would
therefore add permanent complexity without a supported user promise.

## Decision

The client and server exchange only the current protocol version. Every
top-level envelope declares that version and decoding fails closed for an old,
future, malformed, or missing version. A breaking contract change increments
the protocol version and is deployed as a coordinated client/server release.

Old save schemas and incompatible, not-yet-started online matches may be
explicitly retired. They are not silently interpreted by protocol upcasters.
Any future requirement to preserve active matches across incompatible releases
requires a new ADR with a concrete support window, rollout sequence, and
fixture matrix; compatibility must not grow through scattered fallbacks.

Recipient projection remains mandatory: canonical server state never crosses
the network boundary, redaction happens before encoding, and visible offsets
remain monotonic. Generated Serverpod types remain adapter details.

## Consequences

The protocol stays strict and auditable, and releases do not carry unused
historical decoders. Breaking releases may invalidate unsupported saves and
unstarted matches, so deployment notes and cleanup tooling must make that
retirement explicit.

Rejected alternatives:

- retaining speculative upcasters keeps an untested compatibility surface;
- permissive fallback decoding weakens privacy and fail-closed behavior;
- changing ADR 0004 in place would erase the history of the earlier decision.

## Verification

Architecture and contract tests prove exact-version rejection, complete
command/event inventories, recipient projection before transport, and absence
of protocol upcaster chains. Golden fixtures cover the current version only.

## Related Decisions

- [ADR 0001: Map And State Ownership](0001-map-and-state-ownership.md)
- [ADR 0003: Command Boundaries](0003-command-boundaries.md)
