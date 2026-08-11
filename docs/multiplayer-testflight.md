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
- Reverse proxy that supports Serverpod API, web routes, and realtime stream
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
the Docker API at `http://localhost:8080`. Local services are bound to
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
docker compose -f compose.yml --profile tunnel up --build
```

Read the generated `https://*.trycloudflare.com` URL from the `cloudflared`
logs, then build the app with that URL as `AONW_API_BASE_URL` if you want the
app to use the temporary tunnel instead of the local development default.

Quick Tunnel URLs are temporary. They are useful for a short smoke test, but a
TestFlight build should use a stable domain if testers need more than one run.

## VPS Staging

1. Point the DNS `A` record for `api.aonw.net` at the VPS IP.
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
SERVERPOD_SERVER_ID=staging
SERVERPOD_API_SERVER_PUBLIC_HOST=api.aonw.net
SERVERPOD_API_SERVER_PUBLIC_PORT=443
SERVERPOD_API_SERVER_PUBLIC_SCHEME=https
SERVERPOD_WEB_SERVER_PUBLIC_HOST=api.aonw.net
SERVERPOD_WEB_SERVER_PUBLIC_PORT=443
SERVERPOD_WEB_SERVER_PUBLIC_SCHEME=https
AONW_API_HOST=api.aonw.net
```

4. Start the staging stack:

```sh
docker compose -f compose.yml -f compose.staging.yml --profile staging up -d --build
docker compose -f compose.yml -f compose.staging.yml --profile staging ps
curl -fsS https://api.aonw.net/livez
curl -fsS https://api.aonw.net/readyz
```

The staging overlay fixes Serverpod's run mode to `staging`; do not set
`SERVERPOD_RUN_MODE` in `.env`. The stack fails closed if the overlay is
missing or replaced with the production overlay. The staging profile runs
PostgreSQL, the game server, and Caddy. Caddy
terminates HTTPS, stores certificates in Docker volumes, and proxies Serverpod
API traffic to `server:8080`.

Authentication rate limits treat client-IP headers as trusted ingress data.
Keep all Serverpod ports private. The bundled Caddy proxy accepts
`CF-Connecting-IP` only from the allowlisted Cloudflare networks, removes raw
client identity headers, and sends Serverpod one canonical `X-Forwarded-For`
value. Direct clients are identified by their socket address. The tunnel
profile receives Cloudflare's canonical `CF-Connecting-IP` over the private
Docker network. A custom reverse proxy must provide the same trust boundary:
verify its immediate peer, overwrite `X-Forwarded-For` with one validated
address, and remove client-supplied identity headers. Do not expose the backend
with `AONW_SERVER_BIND=0.0.0.0` on a public host. Keep the Cloudflare ranges in
`deploy/caddy/Caddyfile` synchronized with
[Cloudflare's published ranges](https://www.cloudflare.com/ips/).

## Production-Like External Database

The checked-in Compose profiles are intentionally self-contained. The `prod`
profile starts PostgreSQL, Redis, the Serverpod server, and Caddy unless you
override the service set:

```sh
docker compose -f compose.yml -f compose.prod.yml --profile prod up -d --build
```

That is the right shape for a small single-host production-like staging box.

If PostgreSQL is managed outside the VPS, keep using the same Caddy proxy and
set `SERVERPOD_DATABASE_HOST`, `SERVERPOD_DATABASE_PORT`,
`SERVERPOD_DATABASE_NAME`, `SERVERPOD_DATABASE_USER`, and
`SERVERPOD_DATABASE_PASSWORD` for the external database. Also set
`SERVERPOD_DATABASE_REQUIRE_SSL=true` when the provider requires TLS. For an
external TLS-enabled Redis service, set `SERVERPOD_REDIS_REQUIRE_SSL=true`.
Then use a deployment-specific override that removes the bundled `postgres`
service and the server's `depends_on.postgres` relationship. Naming only
`redis`, `server`, and `caddy` on the command line is not sufficient: Compose
also starts declared dependencies.

Those `SERVERPOD_DATABASE_*` values must point at the managed database in that
mode.
Do not leave the bundled PostgreSQL service running accidentally if the external
database is supposed to be authoritative.

## Multiplayer Smoke Checklist

After deploying, test from two devices or two fresh app installs:

1. Build with `--dart-define=AONW_API_BASE_URL=https://api.aonw.net`.
2. Confirm the client declares functional multiplayer revision 6. Commands,
   ACKs, and matches must be strict schema 4; snapshots and events must remain
   writable schema 4, including the snapshot nested inside each correlated
   ACK; a pre-migration match may return readable schema 3 until its first
   accepted state transition.
3. Verify a revision-4 or undeclared client cannot open/resume multiplayer and
   receives the localized update-required message; verify the server returns
   `unsupported_multiplayer_version` for a direct lobby or stream request.
4. Resume a running match created before deployment and verify its unchanged
   schema-3 snapshot and event history load without replay loss. Exercise an
   N-1 server rollback against the same rows; no wire-v4 data migration should
   be present or required.
5. Open multiplayer from the new-game flow.
6. Create an account or sign in on both devices.
7. Create a public match on device A.
8. Refresh Public games on device B, verify that the match is listed, and join
   it without an invite code.
9. Confirm both human members are `connected`, then ready/start the match. Start
   must remain unavailable while any human roster member is connecting or
   reconnecting.
10. Move a visible unit on one device and confirm the other device renders the
   movement animation instead of jumping directly to the destination.
11. Bring two civilizations into contact and confirm each player sees the
   first-contact popup once. Move out of visibility and back again; the popup
   must not return for the same civilization pair.
12. End the turn and confirm the other device receives the live update without
    restarting the app.
13. Background one device or switch away from the browser tab, return, and
    confirm the running match converges without removing that participant.

## Open-Lobby Presence Checklist

Run these cases against public and private hosted lobbies before release. Use
server logs or a database inspection to distinguish a real heartbeat from a
stale UI tile.

1. Create or join a lobby and verify the member starts as `connecting`. Open the
   authorized stream within the 20-second initial lease and verify the member
   becomes `connected`.
2. Keep the lobby open for at least 40 seconds. Verify 10-second heartbeats renew
   the 30-second connected lease and do not continuously broadcast unchanged
   lobby states.
3. Disconnect a guest's last stream and reconnect within the 10-second grace
   period. The member should move through `reconnecting`, keep the same seat and
   country, and return to `connected`.
4. Disconnect the guest again and do not reconnect before grace expires. The
   guest must disappear from every roster, the seat must become joinable, and a
   stale disconnect callback must not affect a later occupant.
5. Disconnect the host and reconnect within grace. The hosted lobby must remain
   open. Repeat without reconnecting: the match must become `abandoned`,
   disappear from public discovery, reject new joins, and return every remaining
   client to its previous lobby screen.
6. Repeat host expiry in a private lobby. The guest returns to the private-join
   form; the host returns home. A terminal update received twice must not cause
   duplicate navigation or messages.
7. Create or join a lobby but prevent its stream from opening. After the
   20-second initial lease, verify the guest is removed or, for a hosted owner,
   the lobby is abandoned without requiring a new list/join request.
8. Sign out while in an open lobby. Verify best-effort leave is sent while the
   token is valid, streams close, credentials are revoked and cleared, and the
   other client observes the departure immediately. A failed leave must not
   prevent sign-out; maintenance must still reconcile the lease.

## Quickplay Presence Checklist

1. Join with one client and keep it connected for longer than the old waiting
   window. A live one-player queue must remain open while heartbeats renew its
   lease; age alone must not abandon it.
2. Join with a second client and confirm the 30-second countdown starts only
   after both human members are connected.
3. Disconnect one client's last stream. The countdown must be cancelled while
   that member is reconnecting. Reconnect within grace and verify a new countdown
   begins from the current active roster.
4. Let the member expire. It must be removed, any technical ownership must be
   transferred safely, and the remaining connected player may continue waiting.
5. Let every quickplay member expire. The queue must become `abandoned` and must
   not be returned by public discovery or selected by later matchmaking.
6. Fill a queue while one roster member is not connected. Neither reaching
   `maxPlayers` nor the countdown deadline may start the match until every human
   member is connected.

If the lobby works but live updates do not, check Caddy and server logs for
Serverpod stream connection failures. Also verify Redis availability, because
the Serverpod runtime uses it for realtime coordination in this stack.
