# Multiplayer Scale-Out Contract

This current runtime contract complements
[ADR 0004](adr/0004-versioned-multiplayer-protocol.md) and
[ADR 0005](adr/0005-immutable-deployment.md). Those ADRs define the accepted
compatibility and deployment targets; this document states today's safe
single-active-multiplayer-instance operating mode.

The drain sequence below is a required automation contract, not a currently
implemented signal handler. Today's Compose recreate can disconnect calls and
streams without first switching readiness to `503`; clients recover through
reconnect and the authoritative snapshot. Do not assume graceful drain until a
deployment test proves that sequence end to end.

PostgreSQL is the durable source of truth. Clients reconnect with their last
event offset, but recovery is snapshot-authoritative: the server sends the
latest recipient-scoped snapshot before any newer event markers.

The currently implemented live-delivery mode requires one active API instance
for multiplayer streams, mutations, and maintenance. The application-level
subscriber registry is process-local. Redis is configured for Serverpod
infrastructure, but the application does not publish match events to a shared
Redis channel. Running unrestricted active-active API replicas would therefore
miss some live broadcasts, including lifecycle changes committed by presence
maintenance on another process.

PostgreSQL still makes recovery on another instance authoritative, but recovery
after a reconnect is not a substitute for cross-instance live fan-out. Per-match
load-balancer affinity is not sufficient by itself because a durable FutureCall
may execute on another process. A future affinity mode must also route
maintenance to the owning process or use shared fan-out. Until then, one active
multiplayer API/maintenance instance is the safe operating mode.

## Durable Lobby Presence

The process-local stream count does not define lobby presence. PostgreSQL stores
the current presence generation and lease deadline for each human lobby member,
so a process crash cannot leave an unbounded `connected` seat. The active
contract uses these defaults:

- create or join records `connecting` with a 20-second initial-connect lease;
- an authorized stream records `connected`, and its 10-second heartbeat renews a
  30-second lease without broadcasting an unchanged lobby;
- closing the last stream records `reconnecting` with a 10-second grace period;
- a generation check prevents a delayed disconnect from replacing a newer
  connection or renewed lease.

Closing one of multiple streams for the same member has no presence effect.
Process termination may prevent the last-stream callback from running, so the
previous durable lease remains the recovery window and is eventually handled by
maintenance. A deploy or restart must never treat the loss of a process-local
registry as immediate proof that a lobby member left.

Expiry is lifecycle-specific. An expired hosted guest is removed from an open
lobby; an expired hosted owner abandons it; an expired quickplay member is
removed and the queue policy is recalculated; a running-match member becomes
offline without losing membership. Abandoned lobbies are soft-deleted from
discovery and remain durable records until a separately reviewed retention
policy removes them.

## Presence Maintenance

Presence expiry uses the reconciled Serverpod maintenance pattern rather than a
widget timer or the arrival of another matchmaking request. The schedule and
work are durable across process restarts:

1. A reconciled FutureCall keeps one maintenance deadline and repairs missing or
   duplicate scheduled work under an advisory lock.
2. One invocation reads a bounded, ordered page of expired leases. The next
   reconciled ten-second invocation continues the backlog; successful mutations
   durably remove or replace the processed lease rows.
3. Each candidate match is locked independently. The service rechecks lifecycle,
   member identity, presence generation, and deadline before mutating it.
4. A heartbeat or reconnect that won the race makes the stale candidate a no-op.
5. The committed roster or terminal state is broadcast only after its database
   transaction succeeds; one candidate failure does not stop later candidates.

The sweep is idempotent and must make progress without a new quickplay, list, or
join request. Bounded pagination and the recurring reconciled invocation protect
the API process from a large expiry backlog; the in-process cursor is only an
optimization because processed database rows are the durable progress marker.
Expired public rooms are excluded directly by discovery while cleanup catches
up.

## Load Balancer Rules

- Route `/readyz` to every instance and only send new traffic to instances that
  return `200`.
- Keep `/livez` for liveness and `/startupz` for startup checks. Liveness may
  stay `200` while `/readyz` returns
  `503` during deploy drain.
- Preserve HTTP upgrade headers for Serverpod realtime streams.
- Keep all players in the same live match pinned to the same API instance unless
  a shared match event bus has been deployed.
- Preserve request-id headers such as `X-Request-Id` at the reverse-proxy layer
  if your deployment adds them. The current Serverpod app does not implement
  custom request-id echoing or JSON-log enrichment itself.
- Block direct public access to the Serverpod API; public API ingress should go
  through the reverse proxy.

## Deploy Drain

Deploy automation should:

1. Start the replacement in isolation, keep it out of live match mutation
   traffic, and wait for `/startupz`, `/livez`, `/readyz`, and synthetic smoke.
2. Signal the old instance, make its `/readyz` return `503`, stop accepting new
   mutations on endpoints and existing streams, and let already accepted
   Serverpod calls settle.
3. Atomically close/force-reconnect old streams and activate the replacement as
   the single multiplayer mutation and maintenance target, then terminate the
   old process. There is no interval where both accept commands.
4. Allow clients to renew durable presence on the replacement within the active
   reconnect/lease window; do not abandon an open lobby merely because the old
   process-local registry disappeared.
5. Rely on client reconnect plus last-seen event offset for match convergence.

Clients reconnect with their last event offset, so a drained stream should
resume from the latest projected snapshot on another ready instance. PostgreSQL
stores canonical events, not viewer-scoped copies. On every response or stream
delivery, the server projects those events for the authenticated recipient and
may replace hidden data with redacted offset markers. Clients must not treat the
projected history as a canonical command replay log.

For an open lobby, reconnect also presents the current membership and terminal
state. A client that reconnects after its seat expired must stop retrying on a
terminal membership error and return to the appropriate previous lobby screen.
If the hosted owner expired while the client was disconnected, the persisted
`abandoned` state supplies that same terminal result after restart.

## Player-Scoped Recovery

PostgreSQL stores the complete authoritative match state. Network responses are
projected for the authenticated player before they leave the server. A client
therefore must recover from `loadSnapshot` or the initial/reconnect stream
snapshot, not by replaying canonical server events. Redacted event markers keep
offset tracking monotonic without exposing another player's commands or turn
resolution details.

## Environment

```env
SERVERPOD_REDIS_ENABLED=true
SERVERPOD_REDIS_HOST=redis
SERVERPOD_PASSWORD_redis=<strong-secret>
SERVERPOD_WEBSOCKET_PING_INTERVAL=20
SERVERPOD_SERVICE_SECRET=<strong-secret>
```

The Serverpod WebSocket ping is transport liveness only. It does not replace the
authenticated 10-second application heartbeat that renews lobby presence.

Readiness polling should be fast enough to remove draining instances before new
match streams are opened. Keep the API port private behind the reverse proxy.

These environment values do not enable application match fan-out. The shared
event bus described below is a future mode and must be implemented and tested
before removing the single-active-multiplayer-instance restriction.

## Shared Event Bus Mode

When live match fan-out moves beyond the process-local subscriber registry, the
replacement contract is:

- persist command event + snapshot in PostgreSQL first;
- publish the committed event offset to Redis/NATS after commit;
- each instance reads events from PostgreSQL by offset before broadcasting;
- `/readyz` and drain behavior stay unchanged.
