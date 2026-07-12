# Multiplayer Scale-Out Contract

PostgreSQL is the durable source of truth. Clients reconnect with their last
event offset, but recovery is snapshot-authoritative: the server sends the
latest recipient-scoped snapshot before any newer event markers.

The currently implemented live-delivery mode is a single active API instance,
or strict per-match affinity covering both streams and match mutations. The
application-level subscriber registry is process-local. Redis is configured for
Serverpod infrastructure, but the application does not publish match events to
a shared Redis channel. Running unrestricted active-active API replicas would
therefore miss some live broadcasts.

PostgreSQL still makes recovery on another instance authoritative, but recovery
after a reconnect is not a substitute for cross-instance live fan-out. Use one
active instance unless the reverse proxy can guarantee that every participant
and mutation for a match reaches the same process.

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
  through the reverse proxy. Keep Insights outside public ingress entirely and
  reach its loopback listener only through the operator SSH tunnel.

## Deploy Drain

On `SIGTERM` or `SIGINT`, deploy automation should:

1. Stop routing new traffic when `/readyz` fails or the instance is removed
   from the load balancer.
2. Let in-flight Serverpod endpoint calls and stream reconnects settle.
3. Start the replacement instance and wait for `/startupz`, `/livez`, and
   `/readyz`.
4. Rely on client reconnect plus last-seen event offset for match convergence.

Clients reconnect with their last event offset, so a drained stream should
resume from the latest projected snapshot on another ready instance. PostgreSQL
stores canonical events, not viewer-scoped copies. On every response or stream
delivery, the server projects those events for the authenticated recipient and
may replace hidden data with redacted offset markers. Clients must not treat the
projected history as a canonical command replay log.

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
match streams are opened. Keep the API port private behind the reverse proxy and
the Insights port bound to host loopback without a public proxy route.

These environment values do not enable application match fan-out. The shared
event bus described below is a future mode and must be implemented and tested
before removing single-instance or per-match-affinity routing.

## Shared Event Bus Mode

When live match fan-out moves beyond the process-local subscriber registry, the
replacement contract is:

- persist command event + snapshot in PostgreSQL first;
- publish the committed event offset to Redis/NATS after commit;
- each instance reads events from PostgreSQL by offset before broadcasting;
- `/readyz` and drain behavior stay unchanged.
