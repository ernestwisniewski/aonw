# Multiplayer Scale-Out Contract

The current production-ready scale-out mode is Serverpod API instances behind a
reverse proxy, with PostgreSQL as the durable source of truth and Redis enabled
for Serverpod realtime coordination. Clients reconnect with their last event
offset and recover through Serverpod endpoints/streams plus persisted snapshots.

## Load Balancer Rules

- Route `/readyz` to every instance and only send new traffic to instances that
  return `200`.
- Keep `/livez` for liveness and `/startupz` for startup checks. Liveness may
  stay `200` while `/readyz` returns
  `503` during deploy drain.
- Preserve HTTP upgrade headers for Serverpod realtime streams and Insights.
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
resume through normal backlog replay on another ready instance.

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

## Future Redis/NATS Mode

If the runtime needs a custom event bus beyond Serverpod/Redis, the replacement
contract is:

- persist command event + snapshot in PostgreSQL first;
- publish the committed event offset to Redis/NATS after commit;
- each instance reads events from PostgreSQL by offset before broadcasting;
- `/readyz` and drain behavior stay unchanged.
