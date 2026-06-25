# Multiplayer Serverpod Smoke And Alerts

Use this as the release gate for multiplayer changes that touch networking,
persistence, or command dispatch.

## Real PostgreSQL And Stream Smoke

Run the local Serverpod integration smoke:

```sh
tool/run_postgres_smoke.sh
```

The script starts the Compose PostgreSQL service, creates `aonw_test` when it
is missing, resets that test database when it still points at a removed clean
migration, and runs `make server-integration-test`. The smoke applies Serverpod
migrations in test mode, verifies auth-required endpoint dispatch, creates and
starts a persisted match, opens the Serverpod realtime stream, sends a command
through the input stream, receives an ACK, retries the same `clientMessageId`
without creating a second event, and verifies the persisted event.

## Quickplay Lobby Smoke

Before release, verify the Serverpod quickplay lobby contract:

1. Create or reuse two signed-in accounts with different selected countries.
2. Join quickplay with the first account and confirm the lobby shows 1/4.
3. Join quickplay with the second account and confirm a 30 second countdown.
4. Re-enter quickplay from the same account after changing country and confirm
   the existing player tile updates to the new country instead of staying on an
   old default.
5. Join two more accounts and confirm the fourth human starts the match
   immediately.
6. Stop any local simulator or throwaway client while it is alone in quickplay;
   after the waiting window, a new quickplay join should create a fresh lobby
   without the simulator's stale country.

## Manual Reconnect Drill

1. Start the staging stack.
2. Open two clients in one match and submit a command.
3. Send `SIGTERM` to the active server container.
4. Verify `/readyz` stops receiving new traffic while `/livez` remains healthy.
5. Verify both clients reconnect and converge to the latest snapshot and event
   offset after resuming from background or a hidden browser tab.
6. Verify Serverpod Insights shows expected auth sessions, stream reconnects,
   and no repeated command rejects.

## Alert Rules

Prometheus starter rules live in
`deploy/prometheus/aonw-alerts.yml`. They cover:

- API liveness probe failure;
- API readiness probe failure;
- Serverpod Insights probe failure.

Tune thresholds after the first TestFlight sessions produce baseline traffic.
