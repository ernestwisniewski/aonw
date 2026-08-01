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

- every client command delivery has a `clientMessageId`; an identical retry
  reuses that id, so the server can return the stored result, while reuse
  with a different command is rejected as `client_message_id_conflict`;
- server persists accepted command, event offset, and snapshot before broadcast;
- clients apply snapshots and events in monotonic offset order; the live
  movement path additionally requires the next adjacent event and its matching
  attached snapshot;
- the live local-echo guard suppresses a recently sent command event by
  `(matchId, actorPlayerId, tick)`, independently of offset ordering;
- ACKs are correlated to pending live commands in send order; the transient
  fallback stream has one pending command and accepts its sole ACK. ACK offsets
  update authoritative state and recovery position, but are not ACK identity;
- reconnect uses the last seen offset, but the latest projected snapshot is
  authoritative and precedes any newer projected event markers;
- two clients converge to the same state after backgrounding, browser tab
  suspension, app restart, or stream reconnect.

## Authoritative Movement Evidence

Every protocol-v3 `WireEvent` and `WireCommandAck` carries a non-null
`movementExecutions` list. Each execution contains the unit, exact origin,
ordered travel steps, per-step entry cost, and cumulative cost. A regular
`MoveUnitCommand` supplies its exact single execution. Simultaneous-turn
finalization, including timeout finalization, supplies the complete globally
ordered chain produced by the canonical reducer. Clients preserve that order
without sorting, grouping, merging, deduplicating, or pathfinding. For example,
`[A1, B1, A2]` remains interleaved, and A2 starts at A1's destination even
though B1 is presented between them.

The field has two valid wire values:

| Wire value | Meaning | Client presentation |
| --- | --- | --- |
| `[]` | The producer or recipient projection intentionally declares that there is no visible movement | Apply authoritative state without movement animation and never infer movement from the snapshot delta |
| Non-empty list | Recipient-safe authoritative movement; one execution for a regular direct move or the complete projected chain for simultaneous finalization | Validate the complete per-unit chain, then present the exact ordered executions |

The key is required. A missing key, JSON `null`, or malformed non-list payload
is an invalid protocol-v3 envelope and is rejected. There is no live
snapshot-delta fallback or dual interpretation for older producers.

### Recipient Projection

PostgreSQL retains a canonical event with server-only movement audience
metadata. Projection follows a whole-chain policy:

- the unit owner may receive the complete chain;
- another participant receives it only when the origin and every executed
  coordinate are visible in both the pre-transition and post-transition fog
  state;
- every segment for one unit has one identical audience;
- if continuity, endpoints, audience metadata, or visibility validation fails,
  projection removes the complete chain for that unit rather than exposing a
  partial route;
- a recipient with no remaining visible chain receives explicit `[]`.

The `_serverAudiencePlayerIds` metadata is storage-only. Event, ACK,
`listEvents`, and live-stream projectors remove it before crossing the network
boundary. Missing, malformed, or inconsistent metadata fails closed: the
projector must suppress the affected movement or reject projection, never send
unreviewed coordinates.

### Persistence, Delivery, and Retry

Normal and timeout finalization use the same canonical reduction, storage, and
recipient projection:

| Path | Durable result | Delivery |
| --- | --- | --- |
| Accepted player command | Snapshot and canonical event are stored at one new offset | The calling stream receives one direct ACK and is excluded from that event broadcast; other subscribed recipients receive the projected event and attached snapshot |
| Server timeout | Snapshot and canonical timeout event are stored at one new offset | Connected recipients receive the projected event and attached snapshot; there is no command caller awaiting an ACK |
| Retry with the same `clientMessageId` and identical command | The previously stored event and offset are reused | The caller receives the stored projected ACK payload; no second state transition or event broadcast is created |
| `listEvents` | Reads canonical stored events | Each event is projected for the requesting participant as metadata-free full or explicit empty movement evidence |

Reusing a `clientMessageId` with a different command is rejected. On the
client, an ACK plan replaces local movement effects instead of being appended
to them. The live subscription also rejects the caller's local event echo, and
offset/state validation prevents a retry ACK from replaying a route after
recovery has already installed its destination snapshot.

### Recovery and History

Connect and reconnect first install the latest recipient-projected snapshot.
The server requests backlog only after the greater of the client's offset and
that snapshot's offset, so events already represented by current state are not
sent again as movement animation. Snapshot-only recovery, offset gaps, stale
events, and an event without its matching attached snapshot suppress movement
presentation. Recovery never infers movement from a snapshot delta.

`listEvents` still exposes safely projected movement evidence for audit and
history consumers. `NetworkEventLog`, however, intentionally maps commands,
domain events, and activity entries into `RecordedDomainCommand`; it is not
the renderer animation-replay surface. It can retain `UnitMovedEvent` activity
and coarse direct-move history, but it does not translate authoritative
intermediate coordinates or costs. Durable exact animation replay remains a
separate event-plan contract.

### Strict Protocol-v3 Activation

No public online matches predate this contract, so the repository carries no
live compatibility reader, movement fallback, or mixed-version deployment
path. The shared models, generated client, Flutter client, and server activate
the required field together. Development data written without
`movementExecutions` is cleared rather than replayed. Contract fixtures cover
only valid explicit-empty and non-empty envelopes plus rejection of an omitted,
`null`, or malformed field.

### Timing Boundary

Authorized recipients receive the same route, costs, and relative order for
the executions visible to them. Protocol v3 does not provide a shared animation
start tick, cross-client clock, or skew budget. Camera pre-roll, reduced-motion
settings, runtime load, and recipient filtering can therefore change local
start time and duration. Exact cross-client timing belongs to the separate
versioned `AnimationPlan` and virtual-clock work in Etap 4; hidden-route length
must not become observable through that future schedule.

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
The server intentionally rejects incompatible matches, including records whose
player identifiers embed account identifiers. The client uses the
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
