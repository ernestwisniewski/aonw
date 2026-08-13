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
the source for the active functional revision, wire-version behavior, and
rollout steps.

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
| Lobby presence | `LiveEventSubscription` | Active `multiplayer.connect` stream | An authenticated heartbeat is sent every 10 seconds by using the existing nullable-command client message; renewing only the durable lease does not create a game event or lobby broadcast. |
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
- multiplayer save metadata and save-list indexes use the canonical
  `multi <match name>` form; lobby and match names remain unchanged, and the
  shared naming policy prevents duplicate prefixes;
- the live local-echo guard suppresses a recently sent command event by
  `(matchId, actorPlayerId, tick)`, independently of offset ordering;
- every command ACK repeats its `clientMessageId`; live commands are correlated
  by that identifier, so a late ACK for a timed-out command cannot complete a
  newer command. Unknown or late ACKs are ignored. The transient fallback
  stream has one pending command and accepts its sole ACK. ACK offsets update
  authoritative state and recovery position, but are not ACK identity;
- reconnect uses the last seen offset, but the latest projected snapshot is
  authoritative and precedes any newer projected event markers;
- two clients converge to the same state after backgrounding, browser tab
  suspension, app restart, or stream reconnect.

## Lobby Membership And Presence

Lobby membership and transport presence are separate contracts. A human in
`WireMatch.players` owns a reserved lobby seat; the player's
`connectionState` reports whether that member is currently eligible to
participate in lobby decisions. Reserved seats determine capacity, while only
connected humans are active. A hosted or quickplay match may start only when it
has at least `minPlayers` human members and every human member in the roster is
`connected`. A connecting, reconnecting, or offline member therefore blocks
start and is never counted as an active player.

Presence follows these states and default deadlines:

| State | Meaning | Durable deadline |
| --- | --- | --- |
| `connecting` | Create or join succeeded, but no authorized live stream has opened yet | Initial-connect lease expires after 20 seconds |
| `connected` | At least one authorized live stream is active | Client heartbeat every 10 seconds renews a 30-second lease |
| `reconnecting` | The last known stream closed and the member may return without losing the seat | Reconnect grace expires after 10 seconds |
| `offline` | No current transport presence remains in a running match | No lobby-start eligibility; running-match membership and recovery rights remain |

Closing one of several streams owned by the same user does not change presence.
Closing the last stream changes the visible state to `reconnecting` and starts
the grace deadline. Presence renewal and disconnect handling are generation
checked so a delayed callback from an older stream cannot shorten a lease
renewed by a newer connection. Deadlines are persisted in PostgreSQL; the
process-local subscriber registry is an optimization, not the durable presence
source of truth.

An expired lease is handled according to the authoritative lifecycle:

- in an open hosted lobby, an expired guest is removed from the roster and the
  freed seat becomes joinable;
- in an open hosted lobby, expiry of the host abandons the match with the
  `ownerLeft` lifecycle reason;
- in open quickplay, the expired member is removed, the technical owner is
  transferred when necessary, and countdown/start policy is evaluated again;
  an empty queue is abandoned, while a connected one-player queue is not
  abandoned merely because it is old;
- in a running match, the member becomes `offline` but remains a participant and
  can recover the match later.

Explicit leave is immediate and does not wait for lease expiry. Public discovery
returns only open, non-quickplay hosted lobbies whose host has active presence
and which the caller may join. Quickplay selection, hosted start, public
discovery, and client presentation use the same roster-policy meanings rather
than independently interpreting raw `players.length`.

Presence expiry is reconciled by durable multiplayer maintenance, independently
of new matchmaking requests. Each invocation reads a bounded page, locks and
rechecks the match, lease generation, deadline, and lifecycle, then performs an
idempotent mutation. State is persisted before any broadcast. A backlog
is continued by the next reconciled ten-second invocation instead of making one
invocation unbounded.

Abandonment is a soft delete. An abandoned lobby immediately disappears from
discovery, rejects joins, and broadcasts its terminal state, but its database
record is retained according to [Data Retention](data-retention.md). A lobby
client receiving that terminal state, discovering that its user is no longer in
the roster, or receiving a terminal membership error stops lobby timers and the
stream, clears the active match, and returns to the appropriate previous lobby
screen: a public-lobby client returns to the refreshed public browser, a private
guest returns to the private-join form, and a private host or quickplay client
returns home. The transition is idempotent. Running-match disconnect and
recovery do not use this lobby-return path.

Lobby reconnect treats `not_match_player`, `match_not_found`,
`match_abandoned`, `match_not_open`, and `unsupported_match_protocol` as
terminal membership failures. It stops retrying and enters the same idempotent
return path. Authentication refresh and transient connection failures retain
their existing session/retry handling.

The revision-4 database migration retires every pre-existing `open` lobby as
`abandoned` with `protocol_upgrade`. Those rows predate durable leases, so
carrying them forward as live rooms would be unverifiable. Running matches are
not retired by this migration.

## Running-Match Turn And Inactivity Deadlines

The turn timeout and whole-match inactivity timeout are separate policies:

- while at least one human participant is durably online (`connected` with a
  live presence lease), the normal turn timeout can submit missing players and
  finalize the turn;
- while every human participant is offline, the turn clock is paused and no
  timeout reduction, economy, research, movement, or turn event is produced;
- the first human connection after that global pause restarts `turnStartedAt`
  in the same locked transaction, giving the resumed match a full turn limit;
- independently, 12 hours without human activity changes the match to
  `abandoned/all_players_inactive` on the next maintenance sweep. Starting a
  match, an accepted human command, or a connection-state transition records
  activity; automatic turn processing and AI do not;
- abandonment is terminal and has `endedAt`, no winner, and no normal outcome.

Maintenance checks whole-match inactivity before the offline turn pause. This
ordering prevents an offline match from pausing forever after its 12-hour
deadline. Existing terminal-state persistence, lease cleanup, and broadcast
remain the only abandonment path; there is no parallel cleanup status or direct
SQL mutation.

## Authoritative Movement Evidence

Every readable schema-v3/v4 `WireEvent` and schema-v4 `WireCommandAck` carries a non-null
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
is an invalid event or ACK envelope and is rejected. There is no live
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

### Strict Wire-v3 Activation

The repository carries no pre-v3 wire reader, movement fallback, or implicit
mixed-wire deployment path. The shared models, generated client, Flutter
client, and server activated the required field together. Development data
written without `movementExecutions` is cleared rather than replayed. Contract
fixtures cover only valid explicit-empty and non-empty envelopes plus rejection
of an omitted, `null`, or malformed field.

### Timing Boundary

Authorized recipients receive the same route, costs, and relative order for
the executions visible to them. Protocol v4 still does not provide a shared
animation start tick, cross-client clock, or skew budget. Camera pre-roll,
reduced-motion settings, runtime load, and recipient filtering can therefore
change local start time and duration. Exact cross-client timing belongs to the
separate versioned `AnimationPlan` and virtual-clock work in Etap 4;
hidden-route length must not become observable through that future schedule.

Quickplay uses one global public queue and its application request carries no
map preference. The Serverpod gateway supplies a canonical lobby placeholder;
the server then selects the start map from official maps that fit the final
player count, using the stable seed through
`MapPlayerCapacityRules.multiplayerStartMapName`.

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

Every authoritative top-level wire envelope carries a strict family version.
`WireCommand`, `WireCommandAck`, and `WireMatch` use
`kProtocolVersion == 4`. `WireSnapshot` and `WireEvent` use the independent
`kSnapshotEventVersion == 7` write schema in storage and in standalone or
nested transport. Revision-9 readers accept the bounded durable set v3-v7.
Nested envelopes validate themselves, so an ACK v4 may contain any readable
durable snapshot during the expansion. There is no implicit promotion between
the families.

Functional multiplayer compatibility is versioned independently:

| Contract | Current | Compatible | Meaning |
| --- | ---: | --- | --- |
| Multiplayer revision | 9 | 9 | Revision 9 adds deterministic half-point road movement, edge-aware city-road routing, and route-cost migration. |
| Command / ACK / match schema | 4 | 4 | Schema 4 requires `clientMessageId` in every `WireCommandAck`. |
| Snapshot / event schema | 7 | 3, 4, 5, 6, 7 readable; 7 writable | Schema 7 stores route costs as fixed-point movement units. Older readable rows migrate whole-point route costs on decode and on the next authoritative write. |

The main-menu app-status request sends the app build plus multiplayer revision
9. A revision in the compatible set can continue. A removed, invalid, or
future revision receives `soon`, which renders the localized
`mainMenuUpdateSoonTitle` and `mainMenuUpdateSoonBody` notice. Older clients
that do not yet send a revision are treated specifically as revision 1 during
this bridge window. Release clients keep multiplayer entry and resume actions
closed while compatibility is unresolved and block them when the server returns
`soon`.

The server independently enforces the same functional revision on every
authenticated multiplayer endpoint, including the streaming `connect`
boundary. The generated current client must pass `multiplayerVersion` at
compile time; missing declarations still deserialize as `null` so legacy wire
requests receive the explicit `unsupported_multiplayer_version` failure before
they can read or mutate lobby state.

Version 3 introduced recipient-scoped snapshots and redacted event history.
The server intentionally rejects incompatible matches, including records whose
player identifiers embed account identifiers. Revision 4 added durable lobby
presence while retaining snapshot/event schema 3. Revision 5 moves only
commands, ACKs, and match envelopes to schema 4 and requires ACK correlation
IDs. Persisted snapshots, persisted events, replay transport, nested ACK
snapshots, and the `multiplayer-v3` snapshot-cache namespace remain schema 3.
Revision 6 moves snapshots and events to schema 4 for road construction and
transport-network state. Revision 7 adds stockpiles and production allocations
in schema 5. Revision 8 adds persisted initial resource placements in schema 6.
Revision 9 moves snapshots and events to schema 7 and saves to schema 7 so road
movement can use exact half-point costs without floating-point state. Readers
accept v3-v7; writers emit v7, and an older running match migrates its route
costs on decode and its next accepted state change. Malformed, pre-v3, and
future versions fail closed.

Before deploying revision 9, retain a database backup. Deploy the v9 server
before exposing v9 clients; older clients are blocked by compatibility guards.
Once any v7 row is written, do not roll the server back against that database.
Use a forward fix, or restore the predeploy backup first. No downcaster exists
because it could reinterpret fixed-point movement balances and route costs.

Use this path for every multiplayer change:

1. Increment `kCurrentMultiplayerVersion` for every functional change.
2. Keep each older revision only when old/new fixtures prove it compatible.
3. If wire JSON is incompatible, bump only its envelope-family version. A
   durable snapshot/event bump additionally requires a rollback-safe
   expand/contract plan or deliberate retirement of incompatible matches.
4. Regenerate Serverpod server/client output for endpoint or model changes.
5. Deploy status negotiation before removing an older revision from the
   compatible set, so store propagation yields the translated update notice.
6. Re-run app-status, command retry, reconnect, generated client, projection,
   and server tests before enabling the new revision.

## Maintenance

- Keep this document aligned with generated protocol names after every
  Serverpod model or endpoint rename.
- Keep `packages/aonw_core/lib/protocol/**`, `server/lib/src/generated/**`, and
  `packages/aonw_server_client/lib/src/protocol/**` in sync whenever wire models
  or endpoint YAML changes.
