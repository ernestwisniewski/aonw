# ADR 0004: Versioned multiplayer protocol

- Status: Accepted
- Date: 2026-07-12
- Implementation: Implemented

## Context

Player-visible multiplayer behavior, transient peer envelopes, and durable stored snapshots evolve on different schedules. One version number either blocks safe additive rollout or hides incompatible storage changes.

## Decision

Multiplayer has three independent compatibility axes:

| Constant | Owns |
| --- | --- |
| `kCurrentMultiplayerVersion` | Functional online behavior: rules, projection, ordering, retry, matchmaking, and transport semantics. |
| `kProtocolVersion` | Transient command, ACK, and match envelope schema. |
| `kSnapshotEventVersion` | Durable snapshot and event schema. |

Current values are defined in `packages/aonw_core/lib/protocol/protocol_version.dart`. At the time of this decision update they are functional revision 9, transient schema 4, and durable write schema 7, with bounded readers for durable schemas 3 through 7.

The binding rules are:

- every multiplayer behavior change increments the functional revision, even when JSON remains additive;
- older functional revisions stay accepted only when fixture-tested as safe;
- each envelope carries its own schema version and fails closed for missing, malformed, future, or retired values;
- supporting an older schema requires an explicit bounded reader/upcaster and, when needed, peer-specific encoder;
- functional compatibility never weakens fog, audience filtering, offset order, or command idempotency;
- save schema and multiplayer schemas remain independent;
- shared DTOs and compatibility constants belong to `aonw_core`;
- generated Serverpod output changes in the same commit as its source model or endpoint.

## Rollout

For every multiplayer change:

1. increment the functional revision;
2. classify each previously accepted revision as compatible or not;
3. bump only the incompatible envelope family;
4. add status, codec, retry, reconnect, projection, and rollout fixtures;
5. deploy the status-aware server before requiring the new client;
6. retain stored matches only when their schema and semantics remain readable or have an explicit migration plan.

Readers precede writers. A durable writer is enabled only with a backup and a rollback/forward-fix plan for older servers.

## Consequences

Compatible releases can roll out without making wire and storage migration implicit. The cost is explicit review of compatibility on every online change.

## Verification

Contract tests cover current, removed, undeclared legacy, and future functional revisions; strict wire readers; command retry; recipient projection; reconnect; and generated-code drift.

See [multiplayer-protocol.md](../multiplayer-protocol.md) for the active runtime contract.
