# Serverpod Insights Runbook

Use Serverpod Insights after the multiplayer refactor to inspect server logs,
health metrics, auth/session behavior, realtime stream behavior, and reconnect
flows. The Insights app version must match the Serverpod major version used by
the project.

References:

- Serverpod Insights: https://docs.serverpod.dev/tools/insights
- Serverpod health checks: https://docs.serverpod.dev/concepts/health-checks

## Local

Start the local Serverpod stack:

```sh
cp .env.example .env
docker compose --profile dev up --build
curl -fsS http://localhost:8080/livez
curl -fsS http://localhost:8080/readyz
curl -fsS http://localhost:8080/startupz
make serverpod-runtime-smoke SERVERPOD_SMOKE_HOST=http://127.0.0.1:8080/
```

Connect Insights to:

```text
http://localhost:8081
```

Local `.env` values that matter:

```env
SERVERPOD_SERVICE_SECRET=replace-with-long-random-secret
AONW_INSIGHTS_BIND=127.0.0.1
AONW_INSIGHTS_PUBLIC_PORT=8081
SERVERPOD_INSIGHTS_SERVER_PORT=8081
SERVERPOD_LOGGING_MODE=normal
```

`SERVERPOD_SERVICE_SECRET` must be non-empty and longer than 20 characters.
Serverpod disables Insights when that secret is missing or too short.

## Staging

Staging exposes Insights through Caddy on `AONW_INSIGHTS_HOST`:

```env
SERVERPOD_SERVICE_SECRET=replace-with-long-random-secret
AONW_INSIGHTS_HOST=insights.aonw.net
AONW_INSIGHTS_UPSTREAM=server:8081
SERVERPOD_INSIGHTS_SERVER_PUBLIC_HOST=insights.aonw.net
SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT=443
SERVERPOD_INSIGHTS_SERVER_PUBLIC_SCHEME=https
```

After deploy:

```sh
curl -fsS https://api.aonw.net/livez
curl -fsS https://api.aonw.net/readyz
curl -fsS https://api.aonw.net/startupz
```

Connect Insights to:

```text
https://insights.aonw.net
```

Keep the Insights host restricted to the team through DNS, firewall, VPN, or
reverse-proxy access rules before production rollout.

## Multiplayer Verification

Run this checklist with two clients after each substantial multiplayer change:

1. Run `make serverpod-runtime-smoke` against the target Serverpod host to
   verify account creation, match creation/join/start, two-way stream command
   ACK, duplicate `clientMessageId` retry idempotency, persisted event offset,
   and reconnect snapshot convergence.
2. Create an account or sign in on both Flutter clients.
3. Create a public match on client A.
4. Join from client B.
5. Start the match and send at least one movement command and one end-turn
   command.
6. Background one mobile/desktop client or switch away from the web tab.
7. Return and confirm both clients converge to the same snapshot and event
   offset.
8. Check Insights logs for auth failures, stream disconnects, command rejects,
   and unexpected reconnect loops.
9. Check health metrics for PostgreSQL and Redis latency spikes during the
   reconnect test.

Treat this checklist as a completion gate for the Serverpod multiplayer
refactor together with analyzer/test results and migration checks.
