# Multiplayer Scale-Out Contract

The current production-ready scale-out mode is Serverpod API instances behind a
reverse proxy, with PostgreSQL as the durable source of truth. Clients reconnect
with their last event offset, but recovery is snapshot-authoritative: the server
sends the latest recipient-scoped snapshot before any newer event markers.

The application-level match subscriber registry is process-local. Until match
event fan-out is moved to a shared Redis/NATS channel, run live match streams
with sticky routing or a single active API instance per match. Cross-instance
recovery is still authoritative through PostgreSQL snapshots and event offsets,
but live broadcasts only reach subscribers attached to the process that emits
the event.

## Load Balancer Rules

- Route `/readyz` to every instance and only send new traffic to instances that
  return `200`.
- Keep `/livez` for liveness and `/startupz` for startup checks. Liveness may
  stay `200` while `/readyz` returns
  `503` during deploy drain.
- Preserve HTTP upgrade headers for Serverpod realtime streams and Insights.
- Keep all players in the same live match pinned to the same API instance unless
  a shared match event bus has been deployed.
- Preserve request-id headers such as `X-Request-Id` at the reverse-proxy layer
  if your deployment adds them. The current Serverpod app does not implement
  custom request-id echoing or JSON-log enrichment itself.
- Block direct public access to the Serverpod API and Insights ports; public
  ingress should go through the reverse proxy.

## Deploy Drain

On `SIGTERM` or `SIGINT`, deploy automation should:

1. Stop routing new traffic when `/readyz` fails or the instance is removed
   from the load balancer.
2. Let in-flight Serverpod endpoint calls and stream reconnects settle.
3. Start the replacement instance and wait for `/startupz`, `/livez`, and
   `/readyz`.
4. Rely on client reconnect plus last-seen event offset for match convergence.

Clients reconnect with their last event offset, so a drained stream should
resume from the latest projected snapshot on another ready instance. Persisted
event history is viewer-scoped and may contain redacted offset markers; clients
must not treat it as a canonical command replay log.

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

Readiness polling should be fast enough to remove draining instances before new
match streams are opened. Keep API and Insights ports private unless the reverse
proxy terminates TLS and applies the public host policy.

## Shared Event Bus Mode

When live match fan-out moves beyond the process-local subscriber registry, the
replacement contract is:

- persist command event + snapshot in PostgreSQL first;
- publish the committed event offset to Redis/NATS after commit;
- each instance reads events from PostgreSQL by offset before broadcasting;
- `/readyz` and drain behavior stay unchanged.
