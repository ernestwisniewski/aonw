# Multiplayer Serverpod Smoke And Alerts

Use this as the release gate for multiplayer changes that touch networking,
persistence, or command dispatch.

## Real PostgreSQL And Stream Smoke

Run the local Serverpod integration smoke:

```sh
tool/run_postgres_smoke.sh
```

The script starts PostgreSQL in a uniquely named Compose project with a fresh
volume, random password, and random loopback-only host port. It creates
`aonw_test`, runs every `make server-integration-test` smoke, and then delegates
to `make serverpod-critical-e2e-test`. Its exit trap removes the isolated
containers and volume. The integration layer applies Serverpod migrations in
test mode and verifies endpoint dispatch and persistence inside the test
harness.

The critical E2E layer starts a separate test-mode server and uses only its
public HTTP and WebSocket surfaces. It signs in real accounts, creates and
starts a persisted match, retries the same `clientMessageId` without creating a
second event, rotates authentication, and catches up from an old event offset
with a fresh client. All three test-server listeners are forced onto IPv4
loopback and probed from non-loopback interfaces. See
[Critical End-to-End Journeys](critical-e2e.md) for the complete contract and
focused commands.

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
6. Inspect the server logs for expected auth sessions, stream reconnects, and
   no repeated command rejects.

## Alert Rules

Prometheus starter rules live in
`deploy/prometheus/aonw-alerts.yml`. They cover:

- API liveness probe failure;
- API readiness probe failure.

The rule file is configuration, not a running monitoring stack. It only becomes
effective after an operator deploys Prometheus, configures blackbox probe jobs
with the expected `job` labels, loads the rule file, and connects Alertmanager
to a tested notification route. Until those pieces exist, `/livez` and
`/readyz` remain release checks but no automated alert is delivered.

Tune thresholds after the first TestFlight sessions produce baseline traffic,
and record a successful synthetic alert before treating monitoring as a
production control.
