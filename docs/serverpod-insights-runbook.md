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
docker compose -f compose.yml --profile dev up --build
curl -fsS http://localhost:8080/livez
curl -fsS http://localhost:8080/readyz
curl -fsS http://localhost:8080/startupz
make serverpod-runtime-smoke SERVERPOD_SMOKE_HOST=http://127.0.0.1:8080/
```

Connect Insights to:

```text
http://127.0.0.1:8081
```

Local `.env` values that matter:

```env
SERVERPOD_SERVICE_SECRET=replace-with-long-random-secret
AONW_INSIGHTS_PUBLIC_PORT=8081
SERVERPOD_INSIGHTS_SERVER_PORT=8081
SERVERPOD_LOGGING_MODE=normal
```

`SERVERPOD_SERVICE_SECRET` must be non-empty and longer than 20 characters.
Serverpod disables Insights when that secret is missing or too short.

## Remote Environments

Staging and production do not expose Insights through Caddy or a public DNS
name. Compose hardcodes the host-side Insights listener to `127.0.0.1`; the
bind cannot be widened with an environment variable.

After deploy:

```sh
curl -fsS https://api.aonw.net/livez
curl -fsS https://api.aonw.net/readyz
curl -fsS https://api.aonw.net/startupz
```

Open an SSH local-forward from the operator workstation:

```sh
ssh -o ExitOnForwardFailure=yes \
  -N \
  -L 127.0.0.1:8081:127.0.0.1:8081 \
  deploy@server.example.com
```

Then connect Insights to:

```text
http://127.0.0.1:8081
```

If local port `8081` is occupied, forward another local port, for example
`ssh -N -L 127.0.0.1:18081:127.0.0.1:8081 ...`, and connect to
`http://127.0.0.1:18081`. Authenticate the Insights app with the deployment's
`SERVERPOD_SERVICE_SECRET`; do not copy the secret into shell history or the
repository. Keep port `8081` loopback-only and do not add a public Caddy route,
DNS record, or load-balancer listener for it.

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
8. Check Insights logs for emitted auth-abuse, stream lifecycle, command-reject,
   and projection-failure events, plus unexpected reconnect loops. Do not expect
   tokens, email addresses, IP addresses, nonces, or raw command payloads in
   those events.
9. Check `/readyz` and the Serverpod database/Redis health records during the
   reconnect test. Latency dashboards require a separately configured metrics
   backend; this repository does not provision one.

Treat this checklist as a completion gate for the Serverpod multiplayer
refactor together with analyzer/test results and migration checks.
