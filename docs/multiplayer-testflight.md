# Multiplayer TestFlight Readiness

This repo has a server-backed multiplayer path. Multiplayer is visible by
default in Flutter builds. Local builds target a local development server by
default, so a TestFlight build must point at the shared staging API:

```sh
flutter build ipa --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

The same API URL is used by the generated Serverpod client for endpoint calls
and realtime match streams.

For local iOS simulator, macOS, and web runs, no API override is needed when the
server listens on `http://localhost:8080`. Android emulator runs use
`http://10.0.2.2:8080` by default. Override the API target only when you want a
different server:

```sh
flutter build ipa --release \
  --dart-define=AONW_API_BASE_URL=http://localhost:8080
```

If a special build needs to hide multiplayer, pass
`--dart-define=AONW_ENABLE_MULTIPLAYER=false`.

## What Must Be Running

- Serverpod server from `server/`, reachable over HTTPS.
- PostgreSQL reachable from the server.
- Redis reachable from the server.
- `SERVERPOD_SERVICE_SECRET` set to a strong random value.
- `SERVERPOD_PASSWORD_redis` set to the same strong random value used by the
  Redis service.
- `SERVERPOD_PASSWORD_emailSecretHashPepper`,
  `SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey`, and
  `SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper` set to strong random values.
- Reverse proxy that supports Serverpod API, Insights, and realtime stream
  traffic.
- Port 80 and 443 open on the VPS if Caddy manages TLS.

## Local Docker Smoke

```sh
cp .env.example .env
make local-start
make local-multiplayer-smoke
make local
```

This starts PostgreSQL, Redis, and Serverpod, waits for API readiness, seeds
four reusable users, runs the multiplayer runtime smoke, and launches Flutter
Web at the stable Google OAuth origin `http://localhost:7357`. The client uses
the Docker API at `http://localhost:8080`. API and Insights ports are bound to
`127.0.0.1` by default. PostgreSQL and Redis are also bound to `127.0.0.1`.
Set `AONW_SERVER_BIND=0.0.0.0` only if you explicitly need LAN access. If local
port `8080` is busy, override `LOCAL_API_PORT` consistently and keep
`SERVERPOD_API_SERVER_PORT=8080` inside the container.

The seeded accounts are `test1@example.test` through `test4@example.test`, all
using `AonwTest123!`. Open normal and private browser windows for a manual
two-player check. Quickplay uses one shared queue even when the two clients
entered the lobby through different randomly selected maps. The Public games
screen lists open matches and lets the second player join without an invite
code. Google Web requires the exact `http://localhost:7357` origin. Apple Web
cannot use a localhost callback because Apple requires registered HTTPS;
native Apple sign-in can still verify through the local API.

## Cloudflare Quick Tunnel Smoke

For a short-lived public HTTPS URL without provisioning long-lived
infrastructure:

```sh
cp .env.example .env
docker compose --profile tunnel up --build
```

Read the generated `https://*.trycloudflare.com` URL from the `cloudflared`
logs, then build the app with that URL as `AONW_API_BASE_URL` if you want the
app to use the temporary tunnel instead of the local development default.

Quick Tunnel URLs are temporary. They are useful for a short smoke test, but a
TestFlight build should use a stable domain if testers need more than one run.

## VPS Staging

1. Point DNS `A` records for `api.aonw.net` and `insights.aonw.net` at the VPS
   IP.
2. Copy the repo to the VPS.
3. Create `.env` from `.env.example` and change at least:

```env
POSTGRES_PASSWORD=replace-with-strong-password
SERVERPOD_DATABASE_PASSWORD=replace-with-strong-password
SERVERPOD_SERVICE_SECRET=replace-with-strong-random-secret
SERVERPOD_PASSWORD_redis=replace-with-strong-random-secret
SERVERPOD_PASSWORD_emailSecretHashPepper=replace-with-strong-random-secret
SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=replace-with-strong-random-secret
SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=replace-with-strong-random-secret
AONW_API_HOST=api.aonw.net
AONW_INSIGHTS_HOST=insights.aonw.net
```

4. Start the staging stack:

```sh
docker compose --profile staging up -d --build
docker compose --profile staging ps
curl -fsS https://api.aonw.net/livez
curl -fsS https://api.aonw.net/readyz
```

The staging profile runs PostgreSQL, the game server, and Caddy. Caddy
terminates HTTPS, stores certificates in Docker volumes, and proxies Serverpod
API traffic to `server:8080` plus Insights traffic to `server:8081`.

## Production-Like External Database

The checked-in Compose profiles are intentionally self-contained. The `prod`
profile starts PostgreSQL, Redis, the Serverpod server, and Caddy unless you
override the service set:

```sh
docker compose --profile prod up -d --build
```

That is the right shape for a small single-host production-like staging box.

If PostgreSQL is managed outside the VPS, keep using the same Caddy proxy and
set `SERVERPOD_DATABASE_HOST`, `SERVERPOD_DATABASE_PORT`,
`SERVERPOD_DATABASE_NAME`, `SERVERPOD_DATABASE_USER`, and
`SERVERPOD_DATABASE_PASSWORD` for the external database. Also set
`SERVERPOD_DATABASE_REQUIRE_SSL=true` when the provider requires TLS. For an
external TLS-enabled Redis service, set `SERVERPOD_REDIS_REQUIRE_SSL=true`.
Then either remove the `postgres` service from the deployed Compose file, use a
deployment-specific override file, or start the explicit services that should
run on the host:

```sh
docker compose --profile prod up -d --build redis server caddy
```

Those `SERVERPOD_DATABASE_*` values must point at the managed database in that
mode.
Do not leave the bundled PostgreSQL service running accidentally if the external
database is supposed to be authoritative.

## Multiplayer Smoke Checklist

After deploying, test from two devices or two fresh app installs:

1. Build with `--dart-define=AONW_API_BASE_URL=https://api.aonw.net`.
2. Open multiplayer from the new-game flow.
3. Create an account or sign in on both devices.
4. Create a public match on device A.
5. Refresh Public games on device B, verify that the match is listed, and join
   it without an invite code.
6. Ready/start the match.
7. Move a visible unit on one device and confirm the other device renders the
   movement animation instead of jumping directly to the destination.
8. Bring two civilizations into contact and confirm each player sees the
   first-contact popup once. Move out of visibility and back again; the popup
   must not return for the same civilization pair.
9. End the turn and confirm the other device receives the live update without
   restarting the app.
10. Background one device or switch away from the browser tab, return, and
   confirm the match state converges without manual refresh.

If the lobby works but live updates do not, check Caddy and server logs for
Serverpod stream connection failures. Also verify Redis availability, because
the Serverpod runtime uses it for realtime coordination in this stack.
