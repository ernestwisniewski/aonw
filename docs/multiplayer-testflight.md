# Multiplayer staging and TestFlight checklist

A store build must use a shared HTTPS API. Local platform defaults point to the development server and are not suitable for TestFlight.

```sh
flutter build ipa --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

A special build can hide multiplayer with `--dart-define=AONW_ENABLE_MULTIPLAYER=false`.

## Required services

- Serverpod API reachable over HTTPS;
- PostgreSQL and Redis reachable from Serverpod;
- strong service, JWT, refresh-token, email-hash, database, and Redis secrets;
- reverse proxy with Serverpod API and realtime stream support;
- migrations applied for the release.

Keep all Serverpod ports private. The reverse proxy must replace untrusted client IP headers with one validated address before forwarding them to authentication rate limiting.

## Local rehearsal

```sh
cp .env.example .env
make local-start
make local-multiplayer-smoke
make local
```

The local web origin is `http://localhost:7357`; the API is `http://localhost:8080`.

## Staging

Use the staging overlay; it fixes the Serverpod run mode and must not be replaced by a value in `.env`.

```sh
docker compose -f compose.yml -f compose.staging.yml \
  --profile staging up -d --build

curl -fsS https://api.aonw.net/startupz
curl -fsS https://api.aonw.net/livez
curl -fsS https://api.aonw.net/readyz
```

For a production-like single host, use the production overlay. An external PostgreSQL or Redis service needs an explicit deployment override that removes the bundled service and its `depends_on`; selecting fewer services on the command line is not enough.

## Two-device acceptance

Run from two fresh installs or two independent accounts:

1. Verify the client declares the current multiplayer revision and an old revision is rejected with the update-required notice.
2. Create, discover, join, and start a public match.
3. Confirm start remains blocked while any human is connecting or reconnecting.
4. Send a movement command and verify the other client renders authoritative movement instead of jumping to the final snapshot.
5. Retry one accepted command with the same message id and verify no duplicate event or movement.
6. Trigger first contact and verify the popup appears once per civilization pair.
7. Submit a turn and confirm the other device receives the live update.
8. Background one client, return, and verify snapshot/offset convergence.
9. Sign out from an open lobby and verify best-effort leave plus eventual lease cleanup.

## Presence cases

Before release, cover hosted public/private lobbies and quickplay:

- initial connection lease expiry;
- heartbeat renewal beyond 40 seconds;
- reconnect inside the grace period;
- guest expiry and seat reuse;
- host expiry and terminal navigation;
- multiple streams for one account;
- full quickplay roster containing one non-connected member;
- empty quickplay queue cleanup.

The detailed failure drills are in [multiplayer-chaos-alerts.md](multiplayer-chaos-alerts.md). The protocol contract is in [multiplayer-protocol.md](multiplayer-protocol.md).
