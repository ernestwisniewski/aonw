# Multiplayer Protocol

Scope: multiplayer transport in the Flutter client (`lib/api/**`), generated
Serverpod client package (`packages/aonw_server_client/**`), shared wire models
(`packages/aonw_core/lib/protocol/**`), and Serverpod server
(`server/lib/src/**`).

This document describes the current Serverpod multiplayer protocol used by the
app. One-shot lobby and recovery operations use generated Serverpod endpoint
methods. Live matches use Serverpod bidirectional streams with generated
protocol envelopes and shared `aonw_core` wire DTOs.

The accepted target compatibility and generated-code boundaries are recorded
in [ADR 0004](adr/0004-versioned-multiplayer-protocol.md). This runbook remains
the source for currently implemented version-3 behavior and rollout steps.

## Architecture

- Auth: custom Serverpod `emailIdp` endpoint backed by
  `serverpod_auth_core_server`; account creation and login are required before
  multiplayer.
- Token refresh: Serverpod Auth Core JWT refresh endpoint.
- Lobby and match lifecycle: generated Serverpod endpoint methods on
  `multiplayer`.
- Shared wire DTOs: `packages/aonw_core/lib/protocol/**` owns command,
  snapshot, event, match, player, and protocol-version payloads.
- Live match sync: Serverpod stream methods with generated protocol envelopes.
- Recovery: PostgreSQL is authoritative for match metadata, snapshots, events,
  and offsets; reconnecting clients first receive a recipient-projected current
  snapshot and then any newer visible events or redacted offset markers.
- Operations: Serverpod health endpoints (`/livez`, `/readyz`, `/startupz`)
  are the built-in operational surface. The repository does not itself provision
  request correlation, a metrics backend, or alert delivery.

## Protocol Surface

| Area | Client adapter | Serverpod surface | Notes |
| --- | --- | --- | --- |
| Account login | `NetworkSessionClient.login` | `emailIdp.login` | Throws generated `AccountAuthException` codes. |
| Account creation | `NetworkSessionClient.createAccount` | `emailIdp.createAccount` | Creates `serverpod_auth_core_user` plus `aonw_account`. |
| Token refresh | `NetworkSessionClient.refresh` | `jwtRefresh.refreshAccessToken` | Refresh token is persisted client-side when present. |
| List/create/join/start/leave match | `NetworkSessionClient` | `multiplayer` endpoint methods | Request/response operations for lobby actions. |
| Snapshot/event reads | `NetworkGameRepository`, `NetworkEventLog` | `multiplayer` endpoint methods | Used for recovery and command/domain-event history, not exact authoritative path replay. |
| Live match updates | `LiveEventSubscription` | `multiplayer.connect` bidirectional stream | Stream payloads carry authoritative offsets. |
| Player commands | `LiveWireCommandDispatcher` | Active `LiveEventSubscriptionHandle.sendCommand` | Commands are sent as `MultiplayerClientMessage.command`; ACKs return as `MultiplayerServerMessage.ack`. `NetworkCommandTransport` is a startup fallback before the live stream is ready. |

## Command And Stream Flow

Serverpod supports bidirectional stream methods, and live match play uses that
shape. `LiveEventSubscription` keeps a long-lived generated
`multiplayer.connect` stream open for match updates and owns the outbound
`StreamController<MultiplayerClientMessage>`.

`LiveWireCommandDispatcher` sends player commands through the active
`LiveEventSubscriptionHandle.sendCommand` path and waits for the matching
`MultiplayerServerMessage.ack`. If gameplay dispatch races ahead of live stream
startup, `NetworkCommandTransport` can open the same generated bidirectional
stream contract for a single command/ACK exchange.

The runtime keeps these synchronization invariants:

- every command has a client request id or tick for idempotent retry;
- server persists accepted command, event offset, and snapshot before broadcast;
- clients deduplicate stream events and command ACKs by offset;
- reconnect uses the last seen offset, but the latest projected snapshot is
  authoritative and precedes any newer projected event markers;
- two clients converge to the same state after backgrounding, browser tab
  suspension, app restart, or stream reconnect.

Accepted finalization events can carry recipient-projected movement execution
plans for live animation. PostgreSQL history retains the canonical plan, while
public event reads remove storage-only audience metadata. Reconnect does not
replay movements already represented by the current snapshot.

Projected `UnitMovedEvent` domain history can coexist with that plan. It
remains useful for activity/history consumers; a live renderer must treat the
movement execution plan as the authoritative replacement, not as an additional
animation source.

`NetworkEventLog` intentionally maps commands, domain events, and activity
entries into `LoggedCommand`, including legacy `UnitMovedEvent` values that can
produce a coarse direct-move replay. It does not translate authoritative
movement execution plans, their intermediate coordinates, or costs. Durable
exact animation replay remains a separate event-plan contract.

Quickplay uses one global public queue. A player's requested map is a lobby
preference for newly created queues; once they join an existing queue, the
existing lobby's map preference and the final player count determine the start
map through `MapPlayerCapacityRules.multiplayerStartMapName`.

Network multiplayer currently uses the server-owned `MatchRules.standard` and
the display name stored in the authenticated account profile, while matchmaking
allocates human seats only. Client lobby requests intentionally expose neither
custom rules, arbitrary display names, nor AI seats. The shared wire model can
serialize AI players for snapshot compatibility, but the Serverpod runtime does
not run AI turns for multiplayer matches. If configurable rules or AI seats are
enabled later, add them as complete vertical protocol features. AI seats require
a server-side AI turn runner before they can block turn completion; current
timeout handling treats AI seats as non-blocking.

## Protocol Versioning

Every authoritative top-level wire envelope carries `v: 3` and is validated by
`kProtocolVersion`; nested command/event bodies inherit the envelope version.
Persisted snapshots/events from earlier wire versions must be cleared or
migrated before replaying them with the current client and server.

Version 3 introduced recipient-scoped snapshots and redacted event history.
The server intentionally rejects earlier matches, including legacy matches
whose player identifiers embedded account identifiers. The client uses the
`multiplayer-v2` snapshot-cache namespace so pre-projection snapshots cannot
be loaded as an offline fallback.

Use this path for the first coordinated protocol bump:

1. Pause new multiplayer match creation during the deploy window.
2. Update the shared wire models, bump `kProtocolVersion`, and regenerate the
   Serverpod protocol output in the same change.
3. Update the Flutter client, generated Serverpod client package, and Serverpod
   server together so they read and write the same version.
4. Clear or migrate persisted match snapshots/events that still carry the
   earlier version when sessions requiring replay exist.
5. Re-run command retry, reconnect, generated client, and server tests before
   enabling matchmaking again.

Once long-lived public multiplayer sessions are common, revisit this section
before a protocol bump. At that point the project may need a temporary
dual-version reader, replay migration, or forced client update policy.

## Maintenance

- Keep this document aligned with generated protocol names after every
  Serverpod model or endpoint rename.
- Keep `packages/aonw_core/lib/protocol/**`, `server/lib/src/generated/**`, and
  `packages/aonw_server_client/lib/src/protocol/**` in sync whenever wire models
  or endpoint YAML changes.
